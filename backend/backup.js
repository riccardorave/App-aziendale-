const cron = require('node-cron');
const { google } = require('googleapis');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const readline = require('readline');
require('dotenv').config();

const TOKEN_PATH = path.join(__dirname, 'token.json');
const CREDENTIALS_PATH = path.join(__dirname, 'oauth_client.json');

const getOAuthClient = () => {
  const credentials = JSON.parse(fs.readFileSync(CREDENTIALS_PATH));
  const { client_secret, client_id, redirect_uris } = credentials.installed;
  return new google.auth.OAuth2(client_id, client_secret, redirect_uris[0]);
};

const authorize = async () => {
  const oAuth2Client = getOAuthClient();
  if (fs.existsSync(TOKEN_PATH)) {
    const token = JSON.parse(fs.readFileSync(TOKEN_PATH));
    oAuth2Client.setCredentials(token);
    return oAuth2Client;
  }
  return getNewToken(oAuth2Client);
};

const getNewToken = (oAuth2Client) => {
  return new Promise((resolve, reject) => {
    const authUrl = oAuth2Client.generateAuthUrl({
      access_type: 'offline',
      scope: ['https://www.googleapis.com/auth/drive.file'],
    });
    console.log('Apri questo URL nel browser per autorizzare il backup:\n', authUrl);
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    rl.question('\nIncolla il codice di autorizzazione qui: ', (code) => {
      rl.close();
      oAuth2Client.getToken(code, (err, token) => {
        if (err) { reject(err); return; }
        oAuth2Client.setCredentials(token);
        fs.writeFileSync(TOKEN_PATH, JSON.stringify(token));
        console.log('Token salvato!');
        resolve(oAuth2Client);
      });
    });
  });
};

const uploadToDrive = async (filePath, fileName) => {
  const auth = await authorize();
  const driveClient = google.drive({ version: 'v3', auth });
  const fileMetadata = {
    name: fileName,
    parents: [process.env.GOOGLE_DRIVE_FOLDER_ID],
  };
  const media = {
    mimeType: 'application/octet-stream',
    body: fs.createReadStream(filePath),
  };
  await driveClient.files.create({
    requestBody: fileMetadata,
    media,
    fields: 'id',
  });
  console.log(`Backup caricato su Drive: ${fileName}`);
};

const runBackup = async () => {
  const date = new Date().toISOString().split('T')[0];
  const fileName = `backup_${date}.sql`;
  const backupsDir = path.join(__dirname, 'backups');
  const filePath = path.join(backupsDir, fileName);

  if (!fs.existsSync(backupsDir)) {
    fs.mkdirSync(backupsDir);
  }

  const cmd = `pg_dump -U postgres -d booking_interno -f "${filePath}"`;
  exec(cmd, { env: { ...process.env, PGPASSWORD: 'postgres123' } }, async (err) => {
    if (err) {
      console.error('Errore backup:', err.message);
      return;
    }
    console.log(`Backup creato: ${fileName}`);
    try {
      await uploadToDrive(filePath, fileName);
      fs.unlinkSync(filePath);
    } catch (e) {
      console.error('Errore upload Drive:', e.message);
    }
  });
};

cron.schedule('0 23 * * *', () => {
  console.log('Avvio backup automatico...');
  runBackup();
});

console.log('Scheduler backup attivo — ogni giorno alle 23:00');

module.exports = { runBackup, authorize };
