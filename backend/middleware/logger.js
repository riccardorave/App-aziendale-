const db = require('../db/pool');

const logActivity = async ({ userId, userName, userEmail, action, entityType, entityId, details, ip }) => {
  try {
    await db.query(
      `INSERT INTO activity_logs (user_id, user_name, user_email, action, entity_type, entity_id, details, ip_address)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [userId || null, userName || null, userEmail || null, action, entityType || null, entityId || null, details || null, ip || null]
    );
  } catch (err) {
    console.error('Errore log:', err.message);
  }
};

module.exports = { logActivity };
