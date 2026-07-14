import express from 'express';
import pool from '../db/db.js';
import { authenticateToken } from '../middleware/auth.js';
import { logAudit } from '../middleware/logger.js';

const router = express.Router();

// GET /api/leaves/types
router.get('/types', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM leave_types');
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// GET /api/leaves/balances
router.get('/balances', authenticateToken, async (req, res) => {
  const employeeId = req.query.employee_id || req.user.employee_id;
  const year = req.query.year || new Date().getFullYear();

  if (req.user.role === 'Employee' && req.user.employee_id != employeeId) {
    return res.status(403).json({ success: false, data: null, error: 'Access denied' });
  }

  try {
    const [rows] = await pool.query(
      `SELECT lb.*, lt.name as leave_type_name
       FROM leave_balances lb
       JOIN leave_types lt ON lb.leave_type_id = lt.id
       WHERE lb.employee_id = ? AND lb.year = ?`,
      [employeeId, year]
    );
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// GET /api/leaves/applications
router.get('/applications', authenticateToken, async (req, res) => {
  const employeeId = req.query.employee_id || req.user.employee_id;

  if (req.user.role === 'Employee' && req.user.employee_id != employeeId) {
    return res.status(403).json({ success: false, data: null, error: 'Access denied' });
  }

  try {
    const [rows] = await pool.query(
      `SELECT la.*, lt.name as leave_type_name
       FROM leave_applications la
       JOIN leave_types lt ON la.leave_type_id = lt.id
       WHERE la.employee_id = ?
       ORDER BY la.created_at DESC`,
      [employeeId]
    );
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// POST /api/leaves/apply
router.post('/apply', authenticateToken, async (req, res) => {
  const employeeId = req.user.employee_id;
  const { leave_type_id, from_date, to_date, days, reason } = req.body;

  if (!leave_type_id || !from_date || !to_date || !days || !reason) {
    return res.status(400).json({ success: false, data: null, error: 'All fields are required' });
  }

  const year = new Date(from_date).getFullYear();

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // 1. Check leave balance
    const [balanceRows] = await conn.query(
      'SELECT balance FROM leave_balances WHERE employee_id = ? AND leave_type_id = ? AND year = ?',
      [employeeId, leave_type_id, year]
    );

    if (balanceRows.length === 0) {
      conn.release();
      return res.status(400).json({ success: false, data: null, error: 'No leave balance record found for this leave type and year' });
    }

    const currentBalance = parseFloat(balanceRows[0].balance);
    const requestedDays = parseFloat(days);

    if (currentBalance < requestedDays) {
      conn.release();
      return res.status(400).json({ success: false, data: null, error: `Insufficient leave balance. Available: ${currentBalance}, Requested: ${requestedDays}` });
    }

    // 2. Insert application
    const [result] = await conn.query(
      `INSERT INTO leave_applications (employee_id, leave_type_id, from_date, to_date, days, reason, status) 
       VALUES (?, ?, ?, ?, ?, ?, 'Pending')`,
      [employeeId, leave_type_id, from_date, to_date, requestedDays, reason]
    );

    await conn.commit();

    return res.status(201).json({ success: true, data: { application_id: result.insertId }, error: null });
  } catch (err) {
    await conn.rollback();
    console.error('Leave apply error:', err);
    return res.status(500).json({ success: false, data: null, error: err.message });
  } finally {
    conn.release();
  }
});

// GET /api/leaves/applications/pending (For managers to view pending actions)
router.get('/applications/pending', authenticateToken, async (req, res) => {
  try {
    let query = `
      SELECT la.*, CONCAT(e.first_name, ' ', e.last_name) as employee_name, e.employee_code, lt.name as leave_type_name
      FROM leave_applications la
      JOIN employees e ON la.employee_id = e.id
      JOIN leave_types lt ON la.leave_type_id = lt.id
      WHERE la.status = 'Pending'
    `;
    const params = [];

    // Filter by team if Manager
    if (req.user.role === 'Manager') {
      query += ' AND e.reporting_manager_id = ?';
      params.push(req.user.employee_id);
    } else if (req.user.role === 'Employee') {
      return res.status(403).json({ success: false, data: null, error: 'Access denied' });
    }

    const [rows] = await pool.query(query, params);
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// PUT /api/leaves/applications/:id (Approve/Reject leave)
router.put('/applications/:id', authenticateToken, async (req, res) => {
  const applicationId = req.params.id;
  const { status } = req.body; // 'Approved' or 'Rejected'

  if (!['Approved', 'Rejected'].includes(status)) {
    return res.status(400).json({ success: false, data: null, error: 'Invalid status value' });
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // Fetch application
    const [appRows] = await conn.query('SELECT * FROM leave_applications WHERE id = ?', [applicationId]);
    if (appRows.length === 0) {
      conn.release();
      return res.status(404).json({ success: false, data: null, error: 'Leave application not found' });
    }
    const app = appRows[0];

    if (app.status !== 'Pending') {
      conn.release();
      return res.status(400).json({ success: false, data: null, error: 'Application has already been processed' });
    }

    // Verify Manager/Admin access
    if (req.user.role === 'Manager') {
      const [emp] = await conn.query('SELECT reporting_manager_id FROM employees WHERE id = ?', [app.employee_id]);
      if (emp[0].reporting_manager_id != req.user.employee_id) {
        conn.release();
        return res.status(403).json({ success: false, data: null, error: 'Access denied' });
      }
    }

    // Update application status
    await conn.query('UPDATE leave_applications SET status = ? WHERE id = ?', [status, applicationId]);

    // If approved, deduct from leave_balances
    if (status === 'Approved') {
      const year = new Date(app.from_date).getFullYear();
      await conn.query(
        `UPDATE leave_balances 
         SET used = used + ? 
         WHERE employee_id = ? AND leave_type_id = ? AND year = ?`,
        [app.days, app.employee_id, app.leave_type_id, year]
      );
    }

    await conn.commit();

    await logAudit(req.user.id, 'leave_applications', applicationId, 'APPROVE', app, { ...app, status });

    return res.json({ success: true, data: { message: `Leave application successfully ${status.toLowerCase()}` }, error: null });
  } catch (err) {
    await conn.rollback();
    console.error('Error processing leave application:', err);
    return res.status(500).json({ success: false, data: null, error: err.message });
  } finally {
    conn.release();
  }
});

// GET /api/leaves/holidays
router.get('/holidays', authenticateToken, async (req, res) => {
  try {
    // Return all holidays
    const [rows] = await pool.query('SELECT * FROM holidays ORDER BY date ASC');
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

export default router;
