const router = require('express').Router();
const db = require('../db/pool');
const { authenticate, requireAdmin } = require('../middleware/auth');

// GET /api/logs — solo admin
router.get('/', authenticate, requireAdmin, async (req, res) => {
  try {
    const limit = req.query.limit || 100;
    const { rows } = await db.query(
      `SELECT * FROM activity_logs ORDER BY created_at DESC LIMIT $1`,
      [limit]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Errore del server' });
  }
});

module.exports = router;