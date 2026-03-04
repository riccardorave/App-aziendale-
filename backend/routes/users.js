const router = require('express').Router();
const db = require('../db/pool');
const { authenticate, requireAdmin } = require('../middleware/auth');

// GET /api/users (admin only)
router.get('/', authenticate, requireAdmin, async (req, res) => {
  try {
    const { rows } = await db.query(
      'SELECT id, name, email, role, department, avatar_color, created_at FROM users ORDER BY name'
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Errore del server' });
  }
});

// PUT /api/users/:id/role (admin only)
router.put('/:id/role', authenticate, requireAdmin, async (req, res) => {
  const { role } = req.body;
  const { logActivity } = require('../middleware/logger');
  if (!['employee', 'admin'].includes(role)) {
    return res.status(400).json({ error: 'Ruolo non valido' });
  }
  try {
    const { rows } = await db.query(
      'UPDATE users SET role=$1, updated_at=NOW() WHERE id=$2 RETURNING id, name, email, role',
      [role, req.params.id]
    );
   if (!rows.length) return res.status(404).json({ error: 'Utente non trovato' });
    logActivity({
      userId: req.user.id,
      userName: req.user.name,
      userEmail: req.user.email,
      action: 'USER_ROLE_CHANGED',
      entityType: 'user',
      entityId: req.params.id,
      details: `Ruolo cambiato in "${role}" per ${rows[0].name} (${rows[0].email})`,
      ip: req.ip,
    });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Errore del server' });
  }
});
// GET /api/users/me — profilo personale
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

// PUT /api/users/me — aggiorna dati personali
router.put('/me', authenticate, async (req, res) => {
  const { name, department } = req.body;
  if (!name || !name.trim()) return res.status(400).json({ error: 'Il nome è obbligatorio' });
  const validDepts = ['Sviluppo', 'Marketing', 'Commerciale', 'Amministrazione', 'HR', 'IT'];
  if (department && !validDepts.includes(department)) {
    return res.status(400).json({ error: 'Dipartimento non valido' });
  }
  try {
    const { rows } = await db.query(
      'UPDATE users SET name=$1, department=$2, updated_at=NOW() WHERE id=$3 RETURNING id, name, email, role, department',
      [name.trim(), department || null, req.user.id]
    );
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Errore del server' });
  }
});

// PUT /api/users/me/password — cambia password
router.put('/me/password', authenticate, async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  if (!currentPassword || !newPassword) {
    return res.status(400).json({ error: 'Tutti i campi sono obbligatori' });
  }
  
  if (newPassword.length < 8) return res.status(400).json({ error: 'La password deve essere di almeno 8 caratteri' });
  if (!/[A-Z]/.test(newPassword)) return res.status(400).json({ error: 'La password deve contenere almeno una lettera maiuscola' });
  if (!/[0-9]/.test(newPassword)) return res.status(400).json({ error: 'La password deve contenere almeno un numero' });
  if (!/[^a-zA-Z0-9]/.test(newPassword)) return res.status(400).json({ error: 'La password deve contenere almeno un simbolo' });
  try {
const bcrypt = require('bcrypt');
    const { rows } = await db.query('SELECT password FROM users WHERE id=$1', [req.user.id]);
    if (!rows.length) return res.status(404).json({ error: 'Utente non trovato' });
    const valid = await bcrypt.compare(currentPassword, rows[0].password);
    if (!valid) return res.status(400).json({ error: 'Password attuale non corretta' });
    const hash = await bcrypt.hash(newPassword, 10);
await db.query('UPDATE users SET password=$1, updated_at=NOW() WHERE id=$2', [hash, req.user.id]);
    res.json({ message: 'Password aggiornata con successo' });
  } catch (err) {
    res.status(500).json({ error: 'Errore del server' });
  }
});
module.exports = router;
