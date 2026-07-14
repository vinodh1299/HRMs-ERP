import pool from './db.js';

async function cleanup() {
  console.log('Cleaning up existing tables...');
  const tables = [
    'auth_log', 'users', 'roles', 'permissions', 'employee_documents', 
    'employee_bank_details', 'employee_shift_assignments', 'attendance_logs', 
    'regularization_requests', 'leave_balances', 'leave_applications', 'payslips', 
    'statutory_info', 'tickets', 'job_requisitions', 'goals', 'expense_claims', 
    'employees', 'departments', 'designations', 'locations', 'shifts', 
    'leave_types', 'holidays', 'payroll_runs', 'audit_log', 'announcements', 
    'polls', 'assets'
  ];

  const conn = await pool.getConnection();
  try {
    await conn.query('SET FOREIGN_KEY_CHECKS = 0');
    for (const table of tables) {
      console.log(`Dropping table ${table} if exists...`);
      await conn.query(`DROP TABLE IF EXISTS ${table}`);
    }
    await conn.query('SET FOREIGN_KEY_CHECKS = 1');
    console.log('Cleanup completed successfully.');
  } catch (err) {
    console.error('Cleanup failed:', err);
  } finally {
    conn.release();
    process.exit(0);
  }
}

cleanup();
