import express from 'express';
import pool from '../db/db.js';
import { authenticateToken } from '../middleware/auth.js';
import { logAudit } from '../middleware/logger.js';

const router = express.Router();

// GET /api/attendance/logs
// Fetches attendance logs for an employee for a specific month (default current month)
router.get('/logs', authenticateToken, async (req, res) => {
  const employeeId = req.query.employee_id || req.user.employee_id;
  const month = req.query.month || new Date().getMonth() + 1; // 1-12
  const year = req.query.year || new Date().getFullYear();

  // Access check: Employees can only view their own logs
  if (req.user.role === 'Employee' && req.user.employee_id != employeeId) {
    return res.status(403).json({ success: false, data: null, error: 'Forbidden' });
  }

  try {
    const startDate = `${year}-${String(month).padStart(2, '0')}-01`;
    const endDate = `${year}-${String(month).padStart(2, '0')}-31`; // MySQL handles date boundaries

    const [logs] = await pool.query(
      `SELECT * FROM attendance_logs 
       WHERE employee_id = ? AND date BETWEEN ? AND ?
       ORDER BY date ASC`,
      [employeeId, startDate, endDate]
    );

    // Get regularization requests for the same period
    const [regularizations] = await pool.query(
      `SELECT * FROM regularization_requests 
       WHERE employee_id = ? AND date BETWEEN ? AND ?`,
      [employeeId, startDate, endDate]
    );

    return res.json({
      success: true,
      data: {
        logs,
        regularizations
      },
      error: null
    });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// POST /api/attendance/checkin
router.post('/checkin', authenticateToken, async (req, res) => {
  const employeeId = req.user.employee_id;
  const today = new Date().toISOString().split('T')[0];
  const now = new Date().toTimeString().split(' ')[0]; // HH:MM:ss
  const { source, latitude, longitude } = req.body;

  if (!employeeId) {
    return res.status(400).json({ success: false, data: null, error: 'No associated employee record found' });
  }

  try {
    // Check if checkin already exists for today
    const [existing] = await pool.query(
      'SELECT id, check_in FROM attendance_logs WHERE employee_id = ? AND date = ?',
      [employeeId, today]
    );

    if (existing.length > 0) {
      return res.status(400).json({ success: false, data: null, error: 'Already checked in for today' });
    }

    await pool.query(
      `INSERT INTO attendance_logs (employee_id, date, check_in, source, latitude, longitude) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [employeeId, today, now, source || 'Web', latitude || null, longitude || null]
    );

    return res.json({
      success: true,
      data: { check_in: now, date: today },
      error: null
    });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// POST /api/attendance/checkout
router.post('/checkout', authenticateToken, async (req, res) => {
  const employeeId = req.user.employee_id;
  const today = new Date().toISOString().split('T')[0];
  const now = new Date().toTimeString().split(' ')[0]; // HH:MM:ss

  if (!employeeId) {
    return res.status(400).json({ success: false, data: null, error: 'No associated employee record found' });
  }

  try {
    // Check if checkin exists
    const [existing] = await pool.query(
      'SELECT id, check_in, check_out FROM attendance_logs WHERE employee_id = ? AND date = ?',
      [employeeId, today]
    );

    if (existing.length === 0) {
      return res.status(400).json({ success: false, data: null, error: 'Must check in before checking out' });
    }

    if (existing[0].check_out) {
      return res.status(400).json({ success: false, data: null, error: 'Already checked out for today' });
    }

    await pool.query(
      'UPDATE attendance_logs SET check_out = ? WHERE id = ?',
      [now, existing[0].id]
    );

    return res.json({
      success: true,
      data: { check_out: now, date: today },
      error: null
    });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// POST /api/attendance/regularize
router.post('/regularize', authenticateToken, async (req, res) => {
  const employeeId = req.user.employee_id;
  const { date, reason, requested_in, requested_out } = req.body;

  if (!date || !reason) {
    return res.status(400).json({ success: false, data: null, error: 'Date and reason are required' });
  }

  try {
    const [result] = await pool.query(
      `INSERT INTO regularization_requests (employee_id, date, reason, requested_in, requested_out, status) 
       VALUES (?, ?, ?, ?, ?, 'Pending')`,
      [employeeId, date, reason, requested_in || null, requested_out || null]
    );

    return res.json({ success: true, data: { id: result.insertId }, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// GET /api/attendance/regularize/pending (For managers to view pending actions)
router.get('/regularize/pending', authenticateToken, async (req, res) => {
  try {
    let query = `
      SELECT r.*, CONCAT(e.first_name, ' ', e.last_name) as employee_name, e.employee_code
      FROM regularization_requests r
      JOIN employees e ON r.employee_id = e.id
      WHERE r.status = 'Pending'
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

// PUT /api/attendance/regularize/:id (Approve/Reject request)
router.put('/regularize/:id', authenticateToken, async (req, res) => {
  const requestId = req.params.id;
  const { status } = req.body; // 'Approved' or 'Rejected'

  if (!['Approved', 'Rejected'].includes(status)) {
    return res.status(400).json({ success: false, data: null, error: 'Invalid status value' });
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // Fetch the request
    const [requestRows] = await conn.query('SELECT * FROM regularization_requests WHERE id = ?', [requestId]);
    if (requestRows.length === 0) {
      conn.release();
      return res.status(404).json({ success: false, data: null, error: 'Regularization request not found' });
    }
    const request = requestRows[0];

    if (request.status !== 'Pending') {
      conn.release();
      return res.status(400).json({ success: false, data: null, error: 'Request is already processed' });
    }

    // Verify Manager/Admin access
    if (req.user.role === 'Manager') {
      const [emp] = await conn.query('SELECT reporting_manager_id FROM employees WHERE id = ?', [request.employee_id]);
      if (emp[0].reporting_manager_id != req.user.employee_id) {
        conn.release();
        return res.status(403).json({ success: false, data: null, error: 'Access denied' });
      }
    }

    // Update request status
    await conn.query('UPDATE regularization_requests SET status = ? WHERE id = ?', [status, requestId]);

    // If approved, update or insert into attendance_logs
    if (status === 'Approved') {
      const [logCheck] = await conn.query(
        'SELECT id FROM attendance_logs WHERE employee_id = ? AND date = ?',
        [request.employee_id, request.date]
      );

      if (logCheck.length > 0) {
        await conn.query(
          'UPDATE attendance_logs SET check_in = ?, check_out = ?, source = ? WHERE id = ?',
          [request.requested_in, request.requested_out, 'Regularized', logCheck[0].id]
        );
      } else {
        await conn.query(
          `INSERT INTO attendance_logs (employee_id, date, check_in, check_out, source) 
           VALUES (?, ?, ?, ?, ?)`,
          [request.employee_id, request.date, request.requested_in, request.requested_out, 'Regularized']
        );
      }
    }

    await conn.commit();

    await logAudit(req.user.id, 'regularization_requests', requestId, 'APPROVE', request, { ...request, status });

    return res.json({ success: true, data: { message: `Request successfully ${status.toLowerCase()}` }, error: null });
  } catch (err) {
    await conn.rollback();
    console.error('Error processing regularization:', err);
    return res.status(500).json({ success: false, data: null, error: err.message });
  } finally {
    conn.release();
  }
});

export default router;
