import express from 'express';
import pool from '../db/db.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

// GET /api/finances/summary
router.get('/summary', authenticateToken, async (req, res) => {
  const employeeId = req.query.employee_id || req.user.employee_id;

  if (req.user.role === 'Employee' && req.user.employee_id != employeeId) {
    return res.status(403).json({ success: false, data: null, error: 'Access denied' });
  }

  try {
    // 1. Fetch bank details
    const [bank] = await pool.query('SELECT * FROM employee_bank_details WHERE employee_id = ?', [employeeId]);

    // 2. Fetch statutory details
    const [statutory] = await pool.query('SELECT * FROM statutory_info WHERE employee_id = ?', [employeeId]);

    // 3. Fetch basic details (PAN/Aadhaar)
    const [emp] = await pool.query('SELECT pan, aadhaar, dob, personal_email FROM employees WHERE id = ?', [employeeId]);

    return res.json({
      success: true,
      data: {
        bank_details: bank.length > 0 ? bank[0] : null,
        statutory_info: statutory.length > 0 ? statutory[0] : null,
        identity: emp.length > 0 ? emp[0] : null
      },
      error: null
    });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// GET /api/finances/payslips
router.get('/payslips', authenticateToken, async (req, res) => {
  const employeeId = req.query.employee_id || req.user.employee_id;

  if (req.user.role === 'Employee' && req.user.employee_id != employeeId) {
    return res.status(403).json({ success: false, data: null, error: 'Access denied' });
  }

  try {
    const [rows] = await pool.query(
      `SELECT p.*, pr.month, pr.year, pr.status as run_status
       FROM payslips p
       JOIN payroll_runs pr ON p.payroll_run_id = pr.id
       WHERE p.employee_id = ?
       ORDER BY pr.year DESC, pr.month DESC`,
      [employeeId]
    );

    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

export default router;
