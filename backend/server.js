import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Import DB initialization & seed
import { runMigrations } from './db/migrate.js';
import { runSeeding } from './db/seed.js';

// Import Routers
import authRouter from './routes/auth.js';
import employeeRouter from './routes/employees.js';
import attendanceRouter from './routes/attendance.js';
import leaveRouter from './routes/leaves.js';
import financeRouter from './routes/finances.js';
import inboxRouter from './routes/inbox.js';
import adminRouter from './routes/admin.js';
import stubsRouter from './routes/stubs.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Mount routes
app.use('/api/auth', authRouter);
app.use('/api/employees', employeeRouter);
app.use('/api/attendance', attendanceRouter);
app.use('/api/leaves', leaveRouter);
app.use('/api/finances', financeRouter);
app.use('/api/inbox', inboxRouter);
app.use('/api/admin', adminRouter);

// Mount stub/engage routes
app.use('/api', stubsRouter);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date() });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled server error:', err);
  res.status(500).json({
    success: false,
    data: null,
    error: err.message || 'Internal server error'
  });
});

// Initialize database and start listening
async function startServer() {
  try {
    // 1. Run migrations to auto-create schema
    await runMigrations();
    
    // 2. Populate initial records
    await runSeeding();
    
    // 3. Start server
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`HRMS Backend running on port ${PORT}`);
    });
  } catch (err) {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
}

startServer();
