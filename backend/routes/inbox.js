import express from 'express';
import pool from '../db/db.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

// GET /api/inbox/pending
router.get('/pending', authenticateToken, async (req, res) => {
  if (req.user.role === 'Employee') {
    return res.json({ success: true, data: { leaves: [], regularizations: [] }, error: null });
  }

  try {
    const managerEmpId = req.user.employee_id;
    const isAdmin = req.user.role === 'Admin';

    // 1. Fetch pending leaves
    let leaveQuery = `
      SELECT la.*, CONCAT(e.first_name, ' ', e.last_name) as employee_name, e.employee_code, lt.name as leave_type_name
      FROM leave_applications la
      JOIN employees e ON la.employee_id = e.id
      JOIN leave_types lt ON la.leave_type_id = lt.id
      WHERE la.status = 'Pending'
    `;
    const leaveParams = [];
    if (!isAdmin) {
      leaveQuery += ' AND e.reporting_manager_id = ?';
      leaveParams.push(managerEmpId);
    }
    const [leaves] = await pool.query(leaveQuery, leaveParams);

    // 2. Fetch pending regularizations
    let regQuery = `
      SELECT r.*, CONCAT(e.first_name, ' ', e.last_name) as employee_name, e.employee_code
      FROM regularization_requests r
      JOIN employees e ON r.employee_id = e.id
      WHERE r.status = 'Pending'
    `;
    const regParams = [];
    if (!isAdmin) {
      regQuery += ' AND e.reporting_manager_id = ?';
      regParams.push(managerEmpId);
    }
    const [regularizations] = await pool.query(regQuery, regParams);

    return res.json({
      success: true,
      data: {
        leaves,
        regularizations
      },
      error: null
    });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

export default router;
