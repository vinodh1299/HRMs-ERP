import express from 'express';
import bcrypt from 'bcryptjs';
import pool from '../db/db.js';
import { authenticateToken, requirePermission } from '../middleware/auth.js';
import { logAudit } from '../middleware/logger.js';

const router = express.Router();

// GET /api/employees/locations
router.get('/locations', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM locations');
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// GET /api/employees/departments
router.get('/departments', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM departments');
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// GET /api/employees/designations
router.get('/designations', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM designations');
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// GET /api/employees/org/tree
router.get('/org/tree', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT e.id, e.first_name, e.last_name, e.employee_code, e.reporting_manager_id,
              d.name as department_name, des.title as designation_title
       FROM employees e
       LEFT JOIN departments d ON e.department_id = d.id
       LEFT JOIN designations des ON e.designation_id = des.id
       WHERE e.status = 'Active'`
    );
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// GET /api/employees (Search & List)
router.get('/', authenticateToken, async (req, res) => {
  const { dept, loc, manager, search } = req.query;
  let query = `
    SELECT e.*, d.name as department_name, des.title as designation_title, l.name as location_name,
           CONCAT(m.first_name, ' ', m.last_name) as manager_name
    FROM employees e
    LEFT JOIN departments d ON e.department_id = d.id
    LEFT JOIN designations des ON e.designation_id = des.id
    LEFT JOIN locations l ON e.location_id = l.id
    LEFT JOIN employees m ON e.reporting_manager_id = m.id
    WHERE 1=1
  `;
  const params = [];

  if (dept) {
    query += ' AND e.department_id = ?';
    params.push(dept);
  }
  if (loc) {
    query += ' AND e.location_id = ?';
    params.push(loc);
  }
  if (manager) {
    query += ' AND e.reporting_manager_id = ?';
    params.push(manager);
  }
  if (search) {
    query += ' AND (e.first_name LIKE ? OR e.last_name LIKE ? OR e.employee_code LIKE ?)';
    const searchParam = `%${search}%`;
    params.push(searchParam, searchParam, searchParam);
  }

  try {
    const [rows] = await pool.query(query, params);
    return res.json({ success: true, data: rows, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// GET /api/employees/:id (Profile detail)
router.get('/:id', authenticateToken, async (req, res) => {
  const empId = req.params.id;

  try {
    const [empRows] = await pool.query(
      `SELECT e.*, d.name as department_name, des.title as designation_title, l.name as location_name,
              CONCAT(m.first_name, ' ', m.last_name) as manager_name
       FROM employees e
       LEFT JOIN departments d ON e.department_id = d.id
       LEFT JOIN designations des ON e.designation_id = des.id
       LEFT JOIN locations l ON e.location_id = l.id
       LEFT JOIN employees m ON e.reporting_manager_id = m.id
       WHERE e.id = ?`,
      [empId]
    );

    if (empRows.length === 0) {
      return res.status(404).json({ success: false, data: null, error: 'Employee not found' });
    }

    const employee = empRows[0];

    // Fetch bank details
    const [bankRows] = await pool.query('SELECT * FROM employee_bank_details WHERE employee_id = ?', [empId]);
    employee.bank_details = bankRows.length > 0 ? bankRows[0] : null;

    // Fetch documents
    const [docRows] = await pool.query('SELECT * FROM employee_documents WHERE employee_id = ?', [empId]);
    employee.documents = docRows;

    return res.json({ success: true, data: employee, error: null });
  } catch (err) {
    return res.status(500).json({ success: false, data: null, error: err.message });
  }
});

// POST /api/employees (Create employee)
router.post('/', authenticateToken, requirePermission('employees', 'all'), async (req, res) => {
  const {
    employee_code, first_name, last_name, dob, gender, personal_email, phone,
    pan, aadhaar, department_id, designation_id, location_id, reporting_manager_id,
    date_of_joining, employment_type, account_no, ifsc, bank_name
  } = req.body;

  // Validation
  if (!employee_code || !first_name || !last_name || !dob || !gender || !personal_email || !phone || !date_of_joining) {
    return res.status(400).json({ success: false, data: null, error: 'Required fields missing' });
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // 1. Create employee record
    const [empResult] = await conn.query(
      `INSERT INTO employees (employee_code, first_name, last_name, dob, gender, personal_email, phone, pan, aadhaar, 
                               department_id, designation_id, location_id, reporting_manager_id, date_of_joining, employment_type, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Active')`,
      [
        employee_code, first_name, last_name, dob, gender, personal_email, phone, pan, aadhaar,
        department_id || null, designation_id || null, location_id || null, reporting_manager_id || null,
        date_of_joining, employment_type || 'Full-Time'
      ]
    );
    const newEmpId = empResult.insertId;

    // 2. Create bank details if provided
    if (account_no && ifsc && bank_name) {
      await conn.query(
        'INSERT INTO employee_bank_details (employee_id, account_no, ifsc, bank_name) VALUES (?, ?, ?, ?)',
        [newEmpId, account_no, ifsc, bank_name]
      );
    }

    // 3. Create default statutory info entry
    await conn.query(
      'INSERT INTO statutory_info (employee_id, pf_account, esi_status, pt_state, lwf_status) VALUES (?, NULL, ?, NULL, ?)',
      [newEmpId, 'Not Applicable', 'Disabled']
    );

    // 4. Create leave balances for the year 2026
    const [leaveTypes] = await conn.query('SELECT id FROM leave_types');
    for (const lt of leaveTypes) {
      await conn.query(
        'INSERT INTO leave_balances (employee_id, leave_type_id, year, opening, accrued, used) VALUES (?, ?, 2026, 6.00, 0.00, 0.00)',
        [newEmpId, lt.id]
      );
    }

    // 5. Auto-create user login account
    const salt = bcrypt.genSaltSync(10);
    const defaultPasswordHash = bcrypt.hashSync('employee123', salt);
    // Find Employee Role ID
    const [roles] = await conn.query('SELECT id FROM roles WHERE name = ?', ['Employee']);
    const employeeRoleId = roles[0]?.id || 3;

    await conn.query(
      'INSERT INTO users (employee_id, email, password_hash, role_id) VALUES (?, ?, ?, ?)',
      [newEmpId, personal_email, defaultPasswordHash, employeeRoleId]
    );

    await conn.commit();

    // Log to system audit trail
    await logAudit(req.user.id, 'employees', newEmpId, 'CREATE', null, req.body);

    return res.status(201).json({ success: true, data: { employee_id: newEmpId }, error: null });
  } catch (err) {
    await conn.rollback();
    console.error('Error creating employee:', err);
    return res.status(500).json({ success: false, data: null, error: err.message });
  } finally {
    conn.release();
  }
});

// PUT /api/employees/:id (Update employee)
router.put('/:id', authenticateToken, async (req, res) => {
  const empId = req.params.id;

  // Enforce security check: employees can only edit themselves unless they are Admin/Manager
  if (req.user.role === 'Employee' && req.user.employee_id != empId) {
    return res.status(403).json({ success: false, data: null, error: 'Access denied: Cannot edit other employee records' });
  }

  const {
    first_name, last_name, dob, gender, personal_email, phone, pan, aadhaar,
    department_id, designation_id, location_id, reporting_manager_id, status,
    account_no, ifsc, bank_name
  } = req.body;

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // Fetch before state for audit log
    const [beforeRows] = await conn.query('SELECT * FROM employees WHERE id = ?', [empId]);
    if (beforeRows.length === 0) {
      conn.release();
      return res.status(404).json({ success: false, data: null, error: 'Employee not found' });
    }
    const beforeState = beforeRows[0];

    // Update fields
    await conn.query(
      `UPDATE employees 
       SET first_name = ?, last_name = ?, dob = ?, gender = ?, personal_email = ?, phone = ?, 
           pan = ?, aadhaar = ?, department_id = ?, designation_id = ?, location_id = ?, 
           reporting_manager_id = ?, status = ?
       WHERE id = ?`,
      [
        first_name || beforeState.first_name,
        last_name || beforeState.last_name,
        dob || beforeState.dob,
        gender || beforeState.gender,
        personal_email || beforeState.personal_email,
        phone || beforeState.phone,
        pan !== undefined ? pan : beforeState.pan,
        aadhaar !== undefined ? aadhaar : beforeState.aadhaar,
        department_id !== undefined ? department_id : beforeState.department_id,
        designation_id !== undefined ? designation_id : beforeState.designation_id,
        location_id !== undefined ? location_id : beforeState.location_id,
        reporting_manager_id !== undefined ? reporting_manager_id : beforeState.reporting_manager_id,
        status || beforeState.status,
        empId
      ]
    );

    // Update bank details if provided
    if (account_no && ifsc && bank_name) {
      const [bankCheck] = await conn.query('SELECT id FROM employee_bank_details WHERE employee_id = ?', [empId]);
      if (bankCheck.length > 0) {
        await conn.query(
          'UPDATE employee_bank_details SET account_no = ?, ifsc = ?, bank_name = ? WHERE employee_id = ?',
          [account_no, ifsc, bank_name, empId]
        );
      } else {
        await conn.query(
          'INSERT INTO employee_bank_details (employee_id, account_no, ifsc, bank_name) VALUES (?, ?, ?, ?)',
          [empId, account_no, ifsc, bank_name]
        );
      }
    }

    await conn.commit();

    // Fetch after state
    const [afterRows] = await pool.query('SELECT * FROM employees WHERE id = ?', [empId]);
    await logAudit(req.user.id, 'employees', empId, 'UPDATE', beforeState, afterRows[0]);

    return res.json({ success: true, data: { message: 'Employee updated successfully' }, error: null });
  } catch (err) {
    await conn.rollback();
    console.error('Error updating employee:', err);
    return res.status(500).json({ success: false, data: null, error: err.message });
  } finally {
    conn.release();
  }
});

export default router;
