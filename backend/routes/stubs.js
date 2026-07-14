import express from 'express';
import pool from '../db/db.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

// 1. Announcements (Engage)
router.get('/announcements', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM announcements ORDER BY published_at DESC');
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// 2. Polls (Engage)
router.get('/polls', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM polls ORDER BY created_at DESC');
    // Ensure options_json is parsed correctly if returned as string from DB
    const processed = rows.map(r => ({
      ...r,
      options: typeof r.options_json === 'string' ? JSON.parse(r.options_json) : r.options_json
    }));
    return res.json({ success: true, data: processed, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// 3. Performance (Goals)
router.get('/performance/goals', authenticateToken, async (req, res) => {
  const employeeId = req.query.employee_id || req.user.employee_id;
  try {
    const [rows] = await pool.query('SELECT * FROM goals WHERE employee_id = ?', [employeeId]);
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// 4. Recruitment/ATS (Job Requisitions)
router.get('/recruitment/requisitions', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM job_requisitions');
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// 5. Expense Claims
router.get('/expenses/claims', authenticateToken, async (req, res) => {
  const employeeId = req.query.employee_id || req.user.employee_id;
  try {
    const [rows] = await pool.query('SELECT * FROM expense_claims WHERE employee_id = ?', [employeeId]);
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// 6. Helpdesk Tickets
router.get('/tickets', authenticateToken, async (req, res) => {
  const employeeId = req.query.employee_id || req.user.employee_id;
  try {
    const [rows] = await pool.query(
      `SELECT t.*, CONCAT(e.first_name, ' ', e.last_name) as employee_name 
       FROM tickets t
       JOIN employees e ON t.employee_id = e.id
       WHERE t.employee_id = ?`,
      [employeeId]
    );
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// 7. Assets
router.get('/assets', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM assets');
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// 8. Reports & Analytics Stubs
router.get('/reports/headcount', authenticateToken, async (req, res) => {
  return res.json({
    success: true,
    data: {
      total: 3,
      department_wise: [
        { department: 'Engineering', count: 2 },
        { department: 'HR', count: 1 }
      ],
      location_wise: [
        { location: 'Chennai HQ', count: 2 },
        { location: 'Bangalore Branch', count: 1 }
      ]
    },
    error: null
  });
});

router.get('/reports/attrition', authenticateToken, async (req, res) => {
  return res.json({
    success: true,
    data: {
      attrition_rate: 0.0, // no exits yet
      active_employees: 3,
      exits: 0
    },
    error: null
  });
});

router.get('/reports/payroll-cost', authenticateToken, async (req, res) => {
  return res.json({
    success: true,
    data: {
      currency: 'INR',
      monthly_cost: [
        { month: 'Jun 2026', cost: 220000.00 } // Suresh (75k) + Vinodh (145k)
      ]
    },
    error: null
  });
});

export default router;
