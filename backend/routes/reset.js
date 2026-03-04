const router = require('express').Router();
const crypto = require('crypto');
const bcrypt = require('bcrypt');
const db = require('../db/pool');
const { sendResetEmail } = require('../middleware/mailer');

router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ error: 'Email obbligatoria' });

  try {
    const { rows } = await db.query('SELECT id, name, email FROM users WHERE email=$1', [email]);
    if (!rows.length) return res.json({ message: 'Se email esiste riceverai un link' });

    const user = rows[0];
    const token = crypto.randomBytes(32).toString('hex');
    const expires = new Date(Date.now() + 3600000);

    await db.query(
      'UPDATE users SET reset_token=$1, reset_token_expires=$2 WHERE id=$3',
      [token, expires, user.id]
    );

const resetLink = `http://localhost:5500?reset=${token}`;    console.log('Invio email a:', user.email);
    console.log('Reset link:', resetLink);
    
    await sendResetEmail(user.email, user.name, resetLink);
    console.log('Email inviata con successo!');

    res.json({ message: 'Email di reset inviata!' });
  } catch (err) {
    console.error('ERRORE:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.post('/reset-password', async (req, res) => {
  const { token, password } = req.body;
  if (!token || !password) return res.status(400).json({ error: 'Dati mancanti' });

  try {
    const { rows } = await db.query(
      'SELECT id FROM users WHERE reset_token=$1 AND reset_token_expires > NOW()',
      [token]
    );
    if (!rows.length) return res.status(400).json({ error: 'Token non valido o scaduto' });

    const hash = await bcrypt.hash(password, 10);
    await db.query(
      'UPDATE users SET password=$1, reset_token=NULL, reset_token_expires=NULL WHERE id=$2',
      [hash, rows[0].id]
    );

    res.json({ message: 'Password aggiornata con successo!' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Errore del server' });
  }
});

module.exports = router;
