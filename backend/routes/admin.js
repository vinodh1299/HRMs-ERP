import express from 'express';
import pool from '../db/db.js';
import { authenticateToken, requirePermission } from '../middleware/auth.js';

const router = express.Router();

// GET /api/admin/audit-logs
router.get('/audit-logs', authenticateToken, requirePermission('admin', 'all'), async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT al.*, u.email as actor_email, CONCAT(e.first_name, ' ', e.last_name) as actor_name
       FROM audit_log al
       LEFT JOIN users u ON al.actor_id = u.id
       LEFT JOIN employees e ON u.employee_id = e.id
       ORDER BY al.created_at DESC
       LIMIT 100`
    );
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// GET /api/admin/roles
router.get('/roles', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM roles');
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

export default router;
