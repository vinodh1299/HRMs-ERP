import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pool from '../db/db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.join(__dirname, '../.env') });

const JWT_SECRET = process.env.JWT_SECRET || 'keka_clone_jwt_secret_token_2026_key';

export function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, data: null, error: 'Access token missing or invalid' });
  }

  jwt.verify(token, JWT_SECRET, async (err, decoded) => {
    if (err) {
      return res.status(401).json({ success: false, data: null, error: 'Invalid or expired session token' });
    }

    try {
      // Fetch latest permissions and employee status to ensure user is still active
      const [rows] = await pool.query(
        `SELECT u.id, u.email, u.employee_id, r.name as role_name, u.is_active
         FROM users u
         JOIN roles r ON u.role_id = r.id
         WHERE u.id = ?`,
        [decoded.id]
      );

      if (rows.length === 0 || !rows[0].is_active) {
        return res.status(401).json({ success: false, data: null, error: 'User is inactive or deleted' });
      }

      const user = rows[0];

      // Fetch user's permissions
      const [perms] = await pool.query(
        `SELECT module, action FROM permissions WHERE role_id = (
          SELECT role_id FROM users WHERE id = ?
        )`,
        [user.id]
      );

      req.user = {
        id: user.id,
        email: user.email,
        employee_id: user.employee_id,
        role: user.role_name,
        permissions: perms
      };

      next();
    } catch (dbErr) {
      console.error('Auth middleware DB error:', dbErr);
      return res.status(500).json({ success: false, data: null, error: 'Internal server error in authorization check' });
    }
  });
}

export function requirePermission(module, action) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ success: false, data: null, error: 'Unauthorized' });
    }

    // Admin has superuser access
    if (req.user.role === 'Admin') {
      return next();
    }

    // Verify module & action
    const hasPerm = req.user.permissions.some(p => {
      const matchModule = p.module === module || p.module === 'all' || p.module === '*';
      const matchAction = p.action === action || p.action === 'all' || p.action === '*';
      return matchModule && matchAction;
    });

    if (!hasPerm) {
      return res.status(403).json({ success: false, data: null, error: `Forbidden: Missing action '${action}' for module '${module}'` });
    }

    next();
  };
}
