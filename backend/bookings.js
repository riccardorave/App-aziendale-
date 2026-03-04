const router = require('express').Router();
const { body, validationResult } = require('express-validator');
const db = require('../db/pool');
const { authenticate, requireAdmin } = require('../middleware/auth');

// GET /api/bookings?date=2024-03-15&resource_id=xxx&my=true
router.get('/', authenticate, async (req, res) => {
  const { date, resource_id, my, upcoming } = req.query;
  try {
    let text = `
      SELECT b.*, 
        u.name as user_name, u.email as user_email, u.avatar_color,
        r.name as resource_name, r.type as resource_type, r.location as resource_location
      FROM bookings b
      JOIN users u ON u.id = b.user_id
      JOIN resources r ON r.id = b.resource_id
      WHERE b.status != 'cancelled'
    `;
    const params = [];

    // Regular employees see only their bookings; admins see all
    if (req.user.role !== 'admin' || my === 'true') {
      params.push(req.user.id);
      text += ` AND b.user_id = $${params.length}`;
    }

    if (date) {
      params.push(date);
      text += ` AND b.start_time::date = $${params.length}::date`;
    }

    if (resource_id) {
      params.push(resource_id);
      text += ` AND b.resource_id = $${params.length}`;
    }

    if (upcoming === 'true') {
      text += ` AND b.start_time >= NOW()`;
    }

    text += ` ORDER BY b.start_time ASC`;

    const { rows } = await db.query(text, params);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Errore del server' });
  }
});

// GET /api/bookings/calendar?start=2024-03-01&end=2024-03-31
router.get('/calendar', authenticate, async (req, res) => {
  const { start, end } = req.query;
  try {
    const { rows } = await db.query(`
      SELECT b.id, b.title, b.start_time, b.end_time, b.status,
        u.name as user_name, u.avatar_color,
        r.name as resource_name, r.type as resource_type
      FROM bookings b
      JOIN users u ON u.id = b.user_id
      JOIN resources r ON r.id = b.resource_id
      WHERE b.status = 'confirmed'
        AND b.start_time >= $1::date
        AND b.end_time <= ($2::date + interval '1 day')
      ORDER BY b.start_time
    `, [start || new Date().toISOString().split('T')[0], end || new Date().toISOString().split('T')[0]]);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Errore del server' });
  }
});

// GET /api/bookings/:id
router.get('/:id', authenticate, async (req, res) => {
  try {
    const { rows } = await db.query(`
      SELECT b.*, u.name as user_name, u.avatar_color,
        r.name as resource_name, r.type as resource_type, r.location as resource_location
      FROM bookings b
      JOIN users u ON u.id = b.user_id
      JOIN resources r ON r.id = b.resource_id
      WHERE b.id = $1
    `, [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Prenotazione non trovata' });

    const booking = rows[0];
    // Only owner or admin can view
    if (booking.user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accesso negato' });
    }
    res.json(booking);
  } catch (err) {
    res.status(500).json({ error: 'Errore del server' });
  }
});

// POST /api/bookings
router.post('/', authenticate, [
  body('resource_id').isUUID(),
  body('title').trim().notEmpty(),
  body('start_time').isISO8601(),
  body('end_time').isISO8601(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  const { resource_id, title, notes, start_time, end_time } = req.body;

  // Validate time range
  const start = new Date(start_time);
  const end = new Date(end_time);
  if (end <= start) return res.status(400).json({ error: 'L\'orario di fine deve essere successivo all\'inizio' });
  if (start < new Date()) return res.status(400).json({ error: 'Non puoi prenotare nel passato' });

  const client = await db.getClient();
  try {
    await client.query('BEGIN');

    // Check resource exists
    const resCheck = await client.query('SELECT id, name FROM resources WHERE id=$1 AND is_active=true', [resource_id]);
    if (!resCheck.rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Risorsa non trovata' });
    }

    // Check for conflicts (with row lock)
    const conflict = await client.query(`
      SELECT id, title, start_time, end_time FROM bookings
      WHERE resource_id = $1
        AND status = 'confirmed'
        AND tstzrange(start_time, end_time, '[)') && tstzrange($2::timestamptz, $3::timestamptz, '[)')
      FOR UPDATE
    `, [resource_id, start_time, end_time]);

    if (conflict.rows.length) {
      await client.query('ROLLBACK');
      return res.status(409).json({
        error: 'Risorsa già prenotata in questo orario',
        conflict: conflict.rows[0]
      });
    }

    const { rows } = await client.query(`
      INSERT INTO bookings (user_id, resource_id, title, notes, start_time, end_time)
      VALUES ($1,$2,$3,$4,$5,$6)
      RETURNING *
    `, [req.user.id, resource_id, title, notes, start_time, end_time]);

    await client.query('COMMIT');

    // Fetch full booking with joins
    const full = await db.query(`
      SELECT b.*, u.name as user_name, u.avatar_color,
        r.name as resource_name, r.type as resource_type, r.location as resource_location
      FROM bookings b
      JOIN users u ON u.id = b.user_id
      JOIN resources r ON r.id = b.resource_id
      WHERE b.id = $1
    `, [rows[0].id]);

    res.status(201).json(full.rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    if (err.code === '23P01') { // exclusion constraint
      return res.status(409).json({ error: 'Conflitto di prenotazione rilevato' });
    }
    console.error(err);
    res.status(500).json({ error: 'Errore del server' });
  } finally {
    client.release();
  }
});

// PUT /api/bookings/:id (update title/notes only)
router.put('/:id', authenticate, [
  body('title').optional().trim().notEmpty(),
], async (req, res) => {
  const { title, notes } = req.body;
  try {
    const existing = await db.query('SELECT * FROM bookings WHERE id=$1', [req.params.id]);
    if (!existing.rows.length) return res.status(404).json({ error: 'Prenotazione non trovata' });

    const booking = existing.rows[0];
    if (booking.user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accesso negato' });
    }

    const { rows } = await db.query(
      `UPDATE bookings SET title=COALESCE($1,title), notes=COALESCE($2,notes), updated_at=NOW()
       WHERE id=$3 RETURNING *`,
      [title, notes, req.params.id]
    );
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Errore del server' });
  }
});

// DELETE /api/bookings/:id (cancel)
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const existing = await db.query('SELECT * FROM bookings WHERE id=$1', [req.params.id]);
    if (!existing.rows.length) return res.status(404).json({ error: 'Prenotazione non trovata' });

    const booking = existing.rows[0];
    if (booking.user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accesso negato' });
    }

    await db.query('UPDATE bookings SET status=\'cancelled\', updated_at=NOW() WHERE id=$1', [req.params.id]);
    res.json({ message: 'Prenotazione cancellata' });
  } catch (err) {
    res.status(500).json({ error: 'Errore del server' });
  }
});

// GET /api/bookings/stats/overview (admin)
router.get('/stats/overview', authenticate, requireAdmin, async (req, res) => {
  try {
    const [total, byType, topResources, upcoming] = await Promise.all([
      db.query(`SELECT COUNT(*) as total, COUNT(*) FILTER (WHERE start_time >= NOW()) as upcoming_count FROM bookings WHERE status='confirmed'`),
      db.query(`SELECT r.type, COUNT(*) as count FROM bookings b JOIN resources r ON r.id=b.resource_id WHERE b.status='confirmed' GROUP BY r.type`),
      db.query(`SELECT r.name, r.type, COUNT(*) as booking_count FROM bookings b JOIN resources r ON r.id=b.resource_id WHERE b.status='confirmed' GROUP BY r.id ORDER BY booking_count DESC LIMIT 5`),
      db.query(`SELECT COUNT(*) as count FROM bookings WHERE status='confirmed' AND start_time::date = CURRENT_DATE`),
    ]);
    res.json({
      total: total.rows[0],
      byType: byType.rows,
      topResources: topResources.rows,
      today: upcoming.rows[0],
    });
  } catch (err) {
    res.status(500).json({ error: 'Errore del server' });
  }
});

module.exports = router;
