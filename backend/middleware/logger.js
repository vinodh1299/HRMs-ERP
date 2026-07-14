import pool from '../db/db.js';

export async function logAudit(actorId, entity, entityId, action, beforeJson = null, afterJson = null) {
  try {
    const beforeStr = beforeJson ? JSON.stringify(beforeJson) : null;
    const afterStr = afterJson ? JSON.stringify(afterJson) : null;
    await pool.query(
      `INSERT INTO audit_log (actor_id, entity, entity_id, action, before_json, after_json) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [actorId, entity, entityId, action, beforeStr, afterStr]
    );
  } catch (err) {
    console.error('Audit Log writing failed:', err);
  }
}
