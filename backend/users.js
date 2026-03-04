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
  if (!['employee', 'admin'].includes(role)) {
    return res.status(400).json({ error: 'Ruolo non valido' });
  }
  try {
    const { rows } = await db.query(
      'UPDATE users SET role=$1, updated_at=NOW() WHERE id=$2 RETURNING id, name, email, role',
      [role, req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Utente non trovato' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Errore del server' });
  }
});

module.exports = router;
