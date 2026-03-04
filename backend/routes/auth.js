const router = require('express').Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const db = require('../db/pool');
const { authenticate } = require('../middleware/auth');

// POST /api/auth/register
router.post('/register', [
  body('name').trim().notEmpty(),
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 6 }),
  body('department').optional().trim(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  const { name, email, password, department } = req.body;
  try {
    const exists = await db.query('SELECT id FROM users WHERE email=$1', [email]);
    if (exists.rows.length) return res.status(409).json({ error: 'Email già registrata' });

    const hash = await bcrypt.hash(password, 10);
    const colors = ['#4F46E5','#059669','#DC2626','#D97706','#0891B2','#7C3AED'];
    const avatar_color = colors[Math.floor(Math.random() * colors.length)];

    const { rows } = await db.query(
      `INSERT INTO users (name, email, password, role, department, avatar_color)
       VALUES ($1,$2,$3,'employee',$4,$5)
       RETURNING id, name, email, role, department, avatar_color`,
      [name, email, hash, department, avatar_color]
    );
    const user = rows[0];
    const token = jwt.sign({ id: user.id, email: user.email, role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.status(201).json({ token, user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Errore del server' });
  }
});

// POST /api/auth/login
router.post('/login', [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  const { email, password } = req.body;
  try {
    // Controlla tentativi falliti nell'ultima ora
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const attempts = await db.query(
      'SELECT COUNT(*) FROM login_attempts WHERE email=$1 AND attempted_at > $2',
      [email, oneHourAgo]
    );
    const attemptCount = parseInt(attempts.rows[0].count);

    if (attemptCount >= 4) {
      const oldest = await db.query(
        'SELECT attempted_at FROM login_attempts WHERE email=$1 AND attempted_at > $2 ORDER BY attempted_at ASC LIMIT 1',
        [email, oneHourAgo]
      );
      const unlockTime = new Date(oldest.rows[0].attempted_at.getTime() + 60 * 60 * 1000);
      const minutesLeft = Math.ceil((unlockTime - Date.now()) / 60000);
      return res.status(429).json({ 
        error: `Account bloccato per troppi tentativi. Riprova tra ${minutesLeft} minuti.` 
      });
    }

    const { rows } = await db.query(
      'SELECT id, name, email, password, role, department, avatar_color FROM users WHERE email=$1',
      [email]
    );
    if (!rows.length) {
      await db.query('INSERT INTO login_attempts (email) VALUES ($1)', [email]);
      return res.status(401).json({ error: 'Credenziali non valide' });
    }

    const user = rows[0];
    const valid = await bcrypt.compare(password, user.password);
    
    if (!valid) {
      await db.query('INSERT INTO login_attempts (email) VALUES ($1)', [email]);
      const remaining = 3 - attemptCount;
      return res.status(401).json({ 
        error: remaining > 0 
          ? `Credenziali non valide. Ancora ${remaining} tentativ${remaining === 1 ? 'o' : 'i'} prima del blocco.`
          : 'Credenziali non valide. Al prossimo tentativo l\'account verrà bloccato.'
      });
    }

    // Login riuscito — pulisci i tentativi falliti
    await db.query('DELETE FROM login_attempts WHERE email=$1', [email]);

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role }, 
      process.env.JWT_SECRET, 
      { expiresIn: '7d' }
    );
    const { password: _, ...safeUser } = user;
    res.json({ token, user: safeUser });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Errore del server' });
  }
});

// GET /api/auth/me
router.get('/me', authenticate, async (req, res) => {
  try {
    const { rows } = await db.query(
      'SELECT id, name, email, role, department, avatar_color, created_at FROM users WHERE id=$1',
      [req.user.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Utente non trovato' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Errore del server' });
  }
});

module.exports = router;