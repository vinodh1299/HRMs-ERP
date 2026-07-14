import bcrypt from 'bcryptjs';
import pool from './db.js';

export async function runSeeding() {
  console.log('Checking database seeding...');
  
  // 1. Check if roles table is already populated
  const [existingRoles] = await pool.query('SELECT COUNT(*) as count FROM roles');
  if (existingRoles[0].count > 0) {
    console.log('Database already contains data, skipping seeding.');
    return;
  }

  console.log('Seeding initial database content...');

  // 2. Insert Roles
  const [roleAdminResult] = await pool.query('INSERT INTO roles (name) VALUES (?)', ['Admin']);
  const [roleManagerResult] = await pool.query('INSERT INTO roles (name) VALUES (?)', ['Manager']);
  const [roleEmployeeResult] = await pool.query('INSERT INTO roles (name) VALUES (?)', ['Employee']);
  const adminRoleId = roleAdminResult.insertId;
  const managerRoleId = roleManagerResult.insertId;
  const employeeRoleId = roleEmployeeResult.insertId;

  // 3. Insert Permissions
  const permissionsToSeed = [
    // Admin permissions
    { roleId: adminRoleId, module: 'auth', action: 'all' },
    { roleId: adminRoleId, module: 'employees', action: 'all' },
    { roleId: adminRoleId, module: 'attendance', action: 'all' },
    { roleId: adminRoleId, module: 'leaves', action: 'all' },
    { roleId: adminRoleId, module: 'finances', action: 'all' },
    { roleId: adminRoleId, module: 'inbox', action: 'all' },
    { roleId: adminRoleId, module: 'admin', action: 'all' },

    // Manager permissions
    { roleId: managerRoleId, module: 'auth', action: 'self' },
    { roleId: managerRoleId, module: 'employees', action: 'team' },
    { roleId: managerRoleId, module: 'attendance', action: 'team' },
    { roleId: managerRoleId, module: 'leaves', action: 'team' },
    { roleId: managerRoleId, module: 'finances', action: 'self' },
    { roleId: managerRoleId, module: 'inbox', action: 'approve' },

    // Employee permissions
    { roleId: employeeRoleId, module: 'auth', action: 'self' },
    { roleId: employeeRoleId, module: 'employees', action: 'self' },
    { roleId: employeeRoleId, module: 'attendance', action: 'self' },
    { roleId: employeeRoleId, module: 'leaves', action: 'self' },
    { roleId: employeeRoleId, module: 'finances', action: 'self' }
  ];

  for (const perm of permissionsToSeed) {
    await pool.query('INSERT INTO permissions (role_id, module, action) VALUES (?, ?, ?)', [
      perm.roleId,
      perm.module,
      perm.action
    ]);
  }

  // 4. Insert Locations
  const [locResult1] = await pool.query('INSERT INTO locations (name, address, timezone) VALUES (?, ?, ?)', [
    'Chennai HQ',
    'ACA Campus, Chennai, Tamil Nadu, India',
    'Asia/Kolkata'
  ]);
  const [locResult2] = await pool.query('INSERT INTO locations (name, address, timezone) VALUES (?, ?, ?)', [
    'Bangalore Branch',
    'Indiranagar, Bangalore, Karnataka, India',
    'Asia/Kolkata'
  ]);
  const chennaiLocId = locResult1.insertId;
  const bangaloreLocId = locResult2.insertId;

  // 5. Insert Departments
  const [deptEngineeringResult] = await pool.query('INSERT INTO departments (name, parent_department_id) VALUES (?, NULL)', ['Engineering']);
  const [deptHRResult] = await pool.query('INSERT INTO departments (name, parent_department_id) VALUES (?, NULL)', ['HR']);
  const [deptFinanceResult] = await pool.query('INSERT INTO departments (name, parent_department_id) VALUES (?, NULL)', ['Finance']);
  const engineeringDeptId = deptEngineeringResult.insertId;
  const hrDeptId = deptHRResult.insertId;
  const financeDeptId = deptFinanceResult.insertId;

  // 6. Insert Designations
  const [desigDirector] = await pool.query('INSERT INTO designations (title, grade) VALUES (?, ?)', ['Director', 'D1']);
  const [desigManager] = await pool.query('INSERT INTO designations (title, grade) VALUES (?, ?)', ['Engineering Manager', 'E5']);
  const [desigHRLead] = await pool.query('INSERT INTO designations (title, grade) VALUES (?, ?)', ['HR Executive', 'E2']);
  const [desigDev] = await pool.query('INSERT INTO designations (title, grade) VALUES (?, ?)', ['Software Engineer', 'E3']);
  
  // 7. Insert Shifts
  const [shiftGeneral] = await pool.query('INSERT INTO shifts (name, start_time, end_time, grace_minutes) VALUES (?, ?, ?, ?)', [
    'General Shift',
    '09:00:00',
    '18:00:00',
    15
  ]);
  const shiftId = shiftGeneral.insertId;

  // 8. Insert Employees (Admin, Manager, Employee)
  // Admin Employee profile
  const [empAdminResult] = await pool.query(
    `INSERT INTO employees (employee_code, first_name, last_name, dob, gender, personal_email, phone, pan, aadhaar, department_id, designation_id, location_id, reporting_manager_id, date_of_joining, employment_type, status) 
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, ?, ?)`,
    [
      'ACA001',
      'Vijay',
      'Kumar',
      '1980-01-15',
      'Male',
      'vijay.kumar@acaindia.org',
      '9876543210',
      'ABCDE1234F',
      '123456789012',
      hrDeptId,
      desigDirector.insertId,
      chennaiLocId,
      '2020-01-01',
      'Full-Time',
      'Active'
    ]
  );
  const adminEmpId = empAdminResult.insertId;

  // Manager Employee profile (reports to Admin)
  const [empManagerResult] = await pool.query(
    `INSERT INTO employees (employee_code, first_name, last_name, dob, gender, personal_email, phone, pan, aadhaar, department_id, designation_id, location_id, reporting_manager_id, date_of_joining, employment_type, status) 
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      'ACA002',
      'Vinodh',
      'Raj',
      '1985-06-20',
      'Male',
      'vinodh.raj@acaindia.org',
      '9876543211',
      'FGHIJ5678K',
      '234567890123',
      engineeringDeptId,
      desigManager.insertId,
      chennaiLocId,
      adminEmpId,
      '2022-04-10',
      'Full-Time',
      'Active'
    ]
  );
  const managerEmpId = empManagerResult.insertId;

  // Regular Employee profile (reports to Manager)
  const [empEmployeeResult] = await pool.query(
    `INSERT INTO employees (employee_code, first_name, last_name, dob, gender, personal_email, phone, pan, aadhaar, department_id, designation_id, location_id, reporting_manager_id, date_of_joining, employment_type, status) 
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      'ACA003',
      'Suresh',
      'Raina',
      '1992-11-27',
      'Male',
      'suresh.raina@acaindia.org',
      '9876543212',
      'LMNOP9012Q',
      '345678901234',
      engineeringDeptId,
      desigDev.insertId,
      bangaloreLocId,
      managerEmpId,
      '2024-02-15',
      'Full-Time',
      'Active'
    ]
  );
  const employeeEmpId = empEmployeeResult.insertId;

  // 9. Assign Shift
  await pool.query('INSERT INTO employee_shift_assignments (employee_id, shift_id, effective_from) VALUES (?, ?, ?)', [adminEmpId, shiftId, '2020-01-01']);
  await pool.query('INSERT INTO employee_shift_assignments (employee_id, shift_id, effective_from) VALUES (?, ?, ?)', [managerEmpId, shiftId, '2022-04-10']);
  await pool.query('INSERT INTO employee_shift_assignments (employee_id, shift_id, effective_from) VALUES (?, ?, ?)', [employeeEmpId, shiftId, '2024-02-15']);

  // 10. Insert Users
  const salt = bcrypt.genSaltSync(10);
  const adminPasswordHash = bcrypt.hashSync('admin123', salt);
  const managerPasswordHash = bcrypt.hashSync('manager123', salt);
  const employeePasswordHash = bcrypt.hashSync('employee123', salt);

  await pool.query('INSERT INTO users (employee_id, email, password_hash, role_id) VALUES (?, ?, ?, ?)', [
    adminEmpId,
    'admin@acaindia.org',
    adminPasswordHash,
    adminRoleId
  ]);
  await pool.query('INSERT INTO users (employee_id, email, password_hash, role_id) VALUES (?, ?, ?, ?)', [
    managerEmpId,
    'manager@acaindia.org',
    managerPasswordHash,
    managerRoleId
  ]);
  await pool.query('INSERT INTO users (employee_id, email, password_hash, role_id) VALUES (?, ?, ?, ?)', [
    employeeEmpId,
    'employee@acaindia.org',
    employeePasswordHash,
    employeeRoleId
  ]);

  // 11. Leave Types
  const [leaveSick] = await pool.query('INSERT INTO leave_types (name, accrual_type, max_carry_forward, encashable) VALUES (?, ?, ?, ?)', ['Sick Leave', 'Monthly', 5, 0]);
  const [leaveCasual] = await pool.query('INSERT INTO leave_types (name, accrual_type, max_carry_forward, encashable) VALUES (?, ?, ?, ?)', ['Casual Leave', 'Monthly', 3, 0]);
  const [leaveEarned] = await pool.query('INSERT INTO leave_types (name, accrual_type, max_carry_forward, encashable) VALUES (?, ?, ?, ?)', ['Earned Leave', 'Yearly', 15, 1]);
  const sickLeaveId = leaveSick.insertId;
  const casualLeaveId = leaveCasual.insertId;
  const earnedLeaveId = leaveEarned.insertId;

  // 12. Leave Balances for 2026
  const employeesList = [adminEmpId, managerEmpId, employeeEmpId];
  for (const empId of employeesList) {
    await pool.query('INSERT INTO leave_balances (employee_id, leave_type_id, year, opening, accrued, used) VALUES (?, ?, ?, ?, ?, ?)', [empId, sickLeaveId, 2026, 5.0, 3.0, 1.0]);
    await pool.query('INSERT INTO leave_balances (employee_id, leave_type_id, year, opening, accrued, used) VALUES (?, ?, ?, ?, ?, ?)', [empId, casualLeaveId, 2026, 4.0, 2.0, 0.5]);
    await pool.query('INSERT INTO leave_balances (employee_id, leave_type_id, year, opening, accrued, used) VALUES (?, ?, ?, ?, ?, ?)', [empId, earnedLeaveId, 2026, 10.0, 5.0, 2.0]);
  }

  // 13. Bank & Statutory Details
  await pool.query('INSERT INTO employee_bank_details (employee_id, account_no, ifsc, bank_name) VALUES (?, ?, ?, ?)', [
    employeeEmpId,
    '123456789012',
    'SBIN0001234',
    'State Bank of India'
  ]);
  await pool.query('INSERT INTO employee_bank_details (employee_id, account_no, ifsc, bank_name) VALUES (?, ?, ?, ?)', [
    managerEmpId,
    '987654321098',
    'ICIC0005678',
    'ICICI Bank'
  ]);

  await pool.query('INSERT INTO statutory_info (employee_id, pf_account, esi_status, pt_state, lwf_status) VALUES (?, ?, ?, ?, ?)', [
    employeeEmpId,
    'MH/BAN/1234567/7654321',
    '1234567890',
    'Karnataka Professional Tax',
    'Enabled'
  ]);
  await pool.query('INSERT INTO statutory_info (employee_id, pf_account, esi_status, pt_state, lwf_status) VALUES (?, ?, ?, ?, ?)', [
    managerEmpId,
    'TN/CHE/7654321/1234567',
    'Not Applicable',
    'Tamil Nadu Professional Tax',
    'Enabled'
  ]);

  // 14. Holidays
  await pool.query('INSERT INTO holidays (location_id, date, name) VALUES (NULL, ?, ?)', ['2026-01-01', 'New Year Day']);
  await pool.query('INSERT INTO holidays (location_id, date, name) VALUES (NULL, ?, ?)', ['2026-01-26', 'Republic Day']);
  await pool.query('INSERT INTO holidays (location_id, date, name) VALUES (NULL, ?, ?)', ['2026-08-15', 'Independence Day']);
  await pool.query('INSERT INTO holidays (location_id, date, name) VALUES (NULL, ?, ?)', ['2026-10-02', 'Gandhi Jayanti']);
  await pool.query('INSERT INTO holidays (location_id, date, name) VALUES (NULL, ?, ?)', ['2026-12-25', 'Christmas Day']);

  // 15. Mock Payslips
  const [payrollRun] = await pool.query('INSERT INTO payroll_runs (month, year, status, run_date) VALUES (?, ?, ?, ?)', [
    6,
    2026,
    'Disbursed',
    '2026-06-30'
  ]);
  const runId = payrollRun.insertId;

  // Payslip for Suresh Raina (Employee)
  await pool.query('INSERT INTO payslips (payroll_run_id, employee_id, gross, deductions, net_pay, pdf_url) VALUES (?, ?, ?, ?, ?, ?)', [
    runId,
    employeeEmpId,
    75000.00,
    8000.00,
    67000.00,
    '/payslips/jun_2026_suresh.pdf'
  ]);

  // Payslip for Vinodh Raj (Manager)
  await pool.query('INSERT INTO payslips (payroll_run_id, employee_id, gross, deductions, net_pay, pdf_url) VALUES (?, ?, ?, ?, ?, ?)', [
    runId,
    managerEmpId,
    145000.00,
    16000.00,
    129000.00,
    '/payslips/jun_2026_vinodh.pdf'
  ]);

  // 16. Announcements
  await pool.query('INSERT INTO announcements (title, category, content) VALUES (?, ?, ?)', [
    'Annual Creche Facilities Open',
    'Creche',
    'We are excited to announce that the campus creche is now fully equipped and open for enrollment starting this week. Please contact HR for registrations.'
  ]);
  await pool.query('INSERT INTO announcements (title, category, content) VALUES (?, ?, ?)', [
    'Annual General Meeting 2026',
    'Corporate',
    'The AGM for the year 2026 will be held on July 30th at the Chennai headquarters main auditorium. Webex link will be shared for remote employees.'
  ]);

  // 17. Polls
  await pool.query('INSERT INTO polls (question, options_json) VALUES (?, ?)', [
    'Where should we hold the annual team outbound event?',
    JSON.stringify(['Ooty', 'Goa', 'Mahabalipuram', 'Kabini'])
  ]);

  console.log('Seeding completed successfully.');
}
