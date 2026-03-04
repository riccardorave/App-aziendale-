const router = require('express').Router();
const db = require('../db/pool');
const { authenticate, requireAdmin } = require('../middleware/auth');

router.get('/', authenticate, async (req, res) => {
  const { type, date, start, end } = req.query;
  try {
    const dateParam = date || new Date().toISOString().split('T')[0];

    let queryText = `
      SELECT r.*,
        COALESCE(
          json_agg(
            json_build_object('id', b.id, 'title', b.title, 'start_time', b.start_time, 'end_time', b.end_time, 'user_name', u.name)
          ) FILTER (WHERE b.id IS NOT NULL AND b.start_time::date = CURRENT_DATE),
          '[]'
        ) as today_bookings
      FROM resources r
      LEFT JOIN bookings b ON b.resource_id = r.id AND b.status = 'confirmed'
      LEFT JOIN users u ON u.id = b.user_id
      WHERE r.is_active = true
      GROUP BY r.id ORDER BY r.type, r.name
    `;

    const { rows } = await db.query(queryText);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Errore del server' });
  }
});

router.get('/:id', authenticate, async (req, res) => {
  try {
    const { rows } = await db.query('SELECT * FROM resources WHERE id=$1 AND is_active=true', [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Risorsa non trovata' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Errore del server' });
  }
});

router.post('/', authenticate, requireAdmin, async (req, res) => {
  const { name, type, description, capacity, location, amenities } = req.body;
  if (!name || !type) return res.status(400).json({ error: 'Nome e tipo obbligatori' });
  try {
    const { rows } = await db.query(
      'INSERT INTO resources (name, type, description, capacity, location, amenities) VALUES ($1,$2::resource_type,$3,$4,$5,$6) RETURNING *',
      [name, type, description, capacity, location, JSON.stringify(amenities || [])]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Errore del server' });
  }
});

router.put('/:id', authenticate, requireAdmin, async (req, res) => {
  const { name, description, capacity, location, amenities, is_active } = req.body;
  try {
    const { rows } = await db.query(
      'UPDATE resources SET name=COALESCE($1,name), description=COALESCE($2,description), capacity=COALESCE($3,capacity), location=COALESCE($4,location), amenities=COALESCE($5,amenities), is_active=COALESCE($6,is_active) WHERE id=$7 RETURNING *',
      [name, description, capacity, location, amenities ? JSON.stringify(amenities) : null, is_active, req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Risorsa non trovata' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Errore del server' });
  }
});

router.delete('/:id', authenticate, requireAdmin, async (req, res) => {
  try {
    await db.query('UPDATE resources SET is_active=false WHERE id=$1', [req.params.id]);
    res.json({ message: 'Risorsa disattivata' });
  } catch (err) {
    res.status(500).json({ error: 'Errore del server' });
  }
});

module.exports = router;
