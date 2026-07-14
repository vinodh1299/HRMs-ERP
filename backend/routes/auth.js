import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import pool from '../db/db.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'keka_clone_jwt_secret_token_2026_key';

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ success: false, data: null, error: 'Email and password are required' });
  }

  try {
    // 1. Fetch user by email
    const [users] = await pool.query(
      `SELECT u.id, u.email, u.password_hash, u.employee_id, u.role_id, u.is_active, r.name as role_name 
       FROM users u
       JOIN roles r ON u.role_id = r.id
       WHERE u.email = ?`,
      [email]
    );

    if (users.length === 0) {
      return res.status(400).json({ success: false, data: null, error: 'Invalid email or password' });
    }

    const user = users[0];

    if (!user.is_active) {
      return res.status(403).json({ success: false, data: null, error: 'Account is suspended' });
    }

    // 2. Validate password
    const passwordMatch = bcrypt.compareSync(password, user.password_hash);
    if (!passwordMatch) {
      return res.status(400).json({ success: false, data: null, error: 'Invalid email or password' });
    }

    // 3. Generate JWT Token (expires in 24 hours)
    const token = jwt.sign(
      { id: user.id, email: user.email, employee_id: user.employee_id, role: user.role_name },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    // 4. Log the login event in auth_log
    const ipAddress = req.ip || req.headers['x-forwarded-for'] || '127.0.0.1';
    const userAgent = req.headers['user-agent'] || 'Unknown';
    await pool.query(
      'INSERT INTO auth_log (user_id, action, ip_address, user_agent) VALUES (?, ?, ?, ?)',
      [user.id, 'login', ipAddress, userAgent]
    );

    return res.json({
      success: true,
      data: {
        token,
        user: {
          id: user.id,
          email: user.email,
          employee_id: user.employee_id,
          role: user.role_name
        }
      },
      error: null
    });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ success: false, data: null, error: 'Internal server error during login' });
  }
});

// POST /api/auth/logout
router.post('/logout', authenticateToken, async (req, res) => {
  try {
    const ipAddress = req.ip || req.headers['x-forwarded-for'] || '127.0.0.1';
    const userAgent = req.headers['user-agent'] || 'Unknown';

    // Log the logout event in auth_log
    await pool.query(
      'INSERT INTO auth_log (user_id, action, ip_address, user_agent) VALUES (?, ?, ?, ?)',
      [req.user.id, 'logout', ipAddress, userAgent]
    );

    return res.json({ success: true, data: { message: 'Logged out successfully' }, error: null });
  } catch (err) {
    console.error('Logout error:', err);
    return res.status(500).json({ success: false, data: null, error: 'Internal server error during logout' });
  }
});

// GET /api/auth/profile
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    // Return rich profile information including employee details
    const [empDetails] = await pool.query(
      `SELECT e.*, d.name as department_name, des.title as designation_title, l.name as location_name,
              CONCAT(m.first_name, ' ', m.last_name) as manager_name
       FROM employees e
       LEFT JOIN departments d ON e.department_id = d.id
       LEFT JOIN designations des ON e.designation_id = des.id
       LEFT JOIN locations l ON e.location_id = l.id
       LEFT JOIN employees m ON e.reporting_manager_id = m.id
       WHERE e.id = ?`,
      [req.user.employee_id]
    );

    const employee = empDetails.length > 0 ? empDetails[0] : null;

    return res.json({
      success: true,
      data: {
        user: req.user,
        employee
      },
      error: null
    });
  } catch (err) {
    console.error('Profile fetch error:', err);
    return res.status(500).json({ success: false, data: null, error: 'Internal server error fetching profile' });
  }
});

export default router;
