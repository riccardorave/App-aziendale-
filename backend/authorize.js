const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');
const http = require('http');

const CREDENTIALS_PATH = path.join(__dirname, 'oauth_client.json');
const TOKEN_PATH = path.join(__dirname, 'token.json');

const credentials = JSON.parse(fs.readFileSync(CREDENTIALS_PATH));
const { client_secret, client_id } = credentials.installed;
const oAuth2Client = new google.auth.OAuth2(client_id, client_secret, 'http://localhost:3002');

const authUrl = oAuth2Client.generateAuthUrl({
  access_type: 'offline',
  scope: ['https://www.googleapis.com/auth/drive.file'],
});

const server = http.createServer(async (req, res) => {
  const code = new URL(req.url, 'http://localhost:3002').searchParams.get('code');
  if (code) {
    try {
      const { tokens } = await oAuth2Client.getToken(code);
      fs.writeFileSync(TOKEN_PATH, JSON.stringify(tokens));
      res.end('Token salvato! Puoi chiudere questa finestra e tornare al terminale.');
      console.log('Token salvato con successo!');
      server.close();
      process.exit(0);
    } catch(e) {
      res.end('Errore: ' + e.message);
      console.error('Errore:', e.message);
      server.close();
    }
  }
});

server.listen(3002, () => {
  console.log('\nApri questo URL nel browser:\n');
  console.log(authUrl);
  console.log('\nIn attesa di autorizzazione...');
});
