# HRMS + Payroll Platform — Full Technical Specification
### (Modeled on standard modular HRMS structure)

---

## 1. Scope & Positioning

An HRMS platform isn't one app — it's four bundled products sold as tiers:

1. **HRMS & Payroll (CoreHR)** — employee records, attendance, leave, payroll, compliance
2. **Hiring (ATS)** — recruitment, career page, onboarding
3. **Performance & Culture** — goals/OKRs, reviews, 360° feedback, engagement
4. **Projects & Timesheets (PSA)** — project time tracking, billing, profitability

Building a complete HRMS platform = building all four as independently deployable modules sharing one Core HR data layer (single source of truth for employee records, which every other module reads from).

**Realistic approach:** build Core HR + Attendance + Leave + Payroll first (this alone is a sellable product for Indian SMBs). Add ATS, Performance, Engagement, PSA in later phases.

---

## 2. Recommended Tech Stack (matched to what you already run)

| Layer | Recommendation | Why |
|---|---|---|
| Backend | **Java 17 + Spring Boot 3** (REST) — or Node.js/Express if you want faster iteration | Spring Boot is the natural upgrade path for enterprise-grade modularity and handles RBAC, scheduled jobs (payroll runs), and validation well |
| Frontend | **React + TypeScript**, Tailwind or MUI | You already build React frontends |
| Mobile | **Flutter** (attendance punch-in, leave apply, payslip view) | You already ship Flutter apps |
| DB | **MySQL 8** (or PostgreSQL if you want better JSON/window-function support for reports) | Matches standard cloud relational DB needs |
| Auth | JWT + refresh tokens, RBAC (role × module × action) | Multi-tenant needs strict permission layering |
| File storage | S3-compatible (documents, payslips, resumes) | HRMS platforms store a *lot* of documents per employee |
| Background jobs | Spring `@Scheduled` / Quartz, or a queue (BullMQ if Node) | Payroll runs, leave-accrual, reminder emails all need cron-like jobs |
| PDF generation | iText (Java) / Puppeteer (Node) | Payslips, offer letters, Form 16 |
| Notifications | Email (SES/SMTP) + push (FCM) + in-app | Approvals, reminders |

**Multi-tenancy decision (important, decide early):** since SaaS platforms serve many companies, you need either (a) one schema per tenant, or (b) shared schema with `tenant_id`/`org_id` on every table. For a single-company internal tool, skip multi-tenancy entirely and simplify massively.

---

## 3. Module-by-Module Breakdown

For each module: **sub-features → core entities → key functions/endpoints**

### 3.1 Core HR (HRIS) — the foundation everything else depends on

**Sub-features**
- Employee master data (personal, contact, statutory IDs — PAN/Aadhaar/UAN/ESI)
- Org structure: departments, designations, business units, locations, reporting hierarchy
- Employee directory + org chart (visual tree)
- Document repository per employee (offer letter, ID proofs, certificates)
- Employee lifecycle: joining → confirmation → transfer → promotion → exit
- Policy documents & acknowledgment tracking
- Custom fields per organization

**Core entities**
```
Organization(id, name, industry, pan, tan, gstin, ...)
Location(id, org_id, name, address, timezone)
Department(id, org_id, name, parent_department_id)
Designation(id, org_id, title, grade)
Employee(id, org_id, employee_code, first_name, last_name, dob, gender,
          personal_email, phone, pan, aadhaar, uan, esi_number,
          department_id, designation_id, location_id, reporting_manager_id,
          date_of_joining, employment_type, status)
EmployeeDocument(id, employee_id, doc_type, file_url, uploaded_at, verified)
EmployeeBankDetail(id, employee_id, account_no, ifsc, bank_name)
Policy(id, org_id, title, content, version, effective_date)
PolicyAcknowledgment(id, policy_id, employee_id, acknowledged_at)
```

**Key functions / API**
```
POST   /employees                     createEmployee()
GET    /employees/{id}                getEmployeeProfile()
PUT    /employees/{id}                updateEmployee()
GET    /employees?dept=&manager=      searchEmployees()
GET    /org-chart                     buildOrgChart()          // recursive tree build
POST   /employees/{id}/documents      uploadDocument()
POST   /employees/{id}/transfer       transferEmployee()       // dept/location change + audit log
POST   /employees/{id}/exit           initiateExit()           // triggers offboarding workflow
GET    /employees/{id}/timeline       getEmploymentTimeline()
```

---

### 3.2 Onboarding

**Sub-features**
- Pre-joining portal (candidate fills personal details, uploads docs before day 1)
- Onboarding task checklists (IT asset allocation, ID card, induction)
- Buddy/mentor assignment
- Digital policy acknowledgment
- Provisioning triggers (auto-create email, Slack invite, payroll record)

**Core entities**
```
OnboardingTemplate(id, org_id, name)
OnboardingTask(id, template_id, title, assignee_role, due_offset_days)
OnboardingInstance(id, employee_id, template_id, status)
OnboardingTaskStatus(id, instance_id, task_id, status, completed_at)
```

**Key functions**
```
POST /onboarding/templates              createChecklistTemplate()
POST /onboarding/{employeeId}/start      startOnboarding()        // clones template into instance
PUT  /onboarding/tasks/{id}/complete     markTaskComplete()
GET  /onboarding/{employeeId}/progress   getOnboardingProgress()  // % complete
```

---

### 3.3 Attendance & Time Tracking

**Sub-features**
- Web/mobile clock-in/out, GPS geofencing, biometric device integration, QR code check-in
- Shift management (fixed, rotational, split shifts)
- Attendance regularization (request correction, manager approval)
- Overtime calculation per labor law rules
- Timesheet (project-linked, billable/non-billable — feeds into PSA module)

**Core entities**
```
Shift(id, org_id, name, start_time, end_time, grace_minutes)
EmployeeShiftAssignment(id, employee_id, shift_id, effective_from)
AttendanceLog(id, employee_id, date, check_in, check_out, source, latitude, longitude)
RegularizationRequest(id, employee_id, date, reason, requested_in, requested_out, status)
Timesheet(id, employee_id, project_id, date, hours, billable, description)
```

**Key functions**
```
POST /attendance/checkin                recordCheckIn()          // validates geofence/device
POST /attendance/checkout                recordCheckOut()
POST /attendance/regularize              submitRegularization()
PUT  /attendance/regularize/{id}/approve approveRegularization()
GET  /attendance/{employeeId}/summary    getMonthlyAttendanceSummary()  // present/absent/late/OT
POST /timesheets                         logTimesheetEntry()
GET  /timesheets/{projectId}/report      getProjectTimeReport()
CRON calculateDailyAttendanceStatus()    // nightly job: marks absent, computes OT, applies grace period
```

---

### 3.4 Leave Management

**Sub-features**
- Leave types (casual, sick, earned, comp-off) with configurable accrual rules
- Leave balance tracking, carry-forward, encashment
- Apply/approve workflow with holiday-aware calendar display
- Leave calendar (team view)

**Core entities**
```
LeaveType(id, org_id, name, accrual_type, max_carry_forward, encashable)
LeaveBalance(id, employee_id, leave_type_id, year, opening, accrued, used, balance)
LeaveApplication(id, employee_id, leave_type_id, from_date, to_date, days, reason, status)
Holiday(id, org_id, location_id, date, name)
```

**Key functions**
```
POST /leaves/apply                    applyLeave()             // checks balance + holiday overlap
PUT  /leaves/{id}/approve              approveLeave()           // deducts balance atomically
GET  /leaves/balance/{employeeId}      getLeaveBalance()
CRON accrueMonthlyLeave()              // runs 1st of month, credits per accrual policy
CRON carryForwardYearEnd()             // Dec 31 job: caps carry-forward, expires excess
POST /leaves/encash                    requestEncashment()
```

---

### 3.5 Payroll & Statutory Compliance (the hardest, highest-value module)

**Sub-features**
- Salary structure builder (CTC breakup: basic, HRA, allowances, deductions)
- Monthly payroll run (compute gross → deductions → net) with pre-run variance report
- Statutory compliance: PF, ESI, TDS (income tax per new/old regime), Professional Tax, LWF, Gratuity
- Investment declarations (Section 80C/80D) + proof verification
- Payslip generation (PDF), Form 16, Form 24Q
- Loans & advances, reimbursements, full & final settlement

**Core entities**
```
SalaryStructure(id, employee_id, ctc_annual, effective_from)
SalaryComponent(id, structure_id, component_name, type[earning/deduction], calc_type, value)
PayrollRun(id, org_id, month, year, status, run_date)
Payslip(id, payroll_run_id, employee_id, gross, deductions, net_pay, pdf_url)
PayslipComponent(id, payslip_id, component_name, amount)
InvestmentDeclaration(id, employee_id, financial_year, section, declared_amount, proof_url, verified)
LoanAdvance(id, employee_id, amount, emi, remaining_balance)
StatutoryFiling(id, org_id, type[PF/ESI/TDS], period, filed_at, ack_number)
```

**Key functions**
```
POST /payroll/salary-structure          defineSalaryStructure()
POST /payroll/run                       initiatePayrollRun()      // locks attendance/leave data for period
POST /payroll/run/{id}/compute          computePayroll()          // per employee: gross→PF→ESI→PT→TDS→net
     computeTDS(employee, financialYear) // slab-based, old vs new regime comparison
     computePF(basic)                    // 12% employee + 12% employer, capped at wage ceiling
     computeESI(gross)                   // if gross <= threshold
     computeProfessionalTax(state, gross)// state-specific slabs
GET  /payroll/run/{id}/variance         getVarianceReport()        // flags >X% change vs last month
POST /payroll/run/{id}/approve          approvePayrollRun()
POST /payroll/run/{id}/disburse         generateBankTransferFile() // NEFT/bank-specific format
GET  /payslips/{employeeId}/{month}     downloadPayslip()          // PDF via iText/Puppeteer
POST /payroll/fnf                       processFullAndFinalSettlement()
GET  /compliance/form16/{employeeId}    generateForm16()
```

⚠️ This module carries real legal/financial risk if built incorrectly (wrong TDS = compliance violation for your client's company). Budget the most QA time here, and validate PF/ESI/PT slab rules against current government notifications before going live — these change yearly.

---

### 3.6 Performance Management

**Sub-features**
- Goals/OKRs (individual, team, cascading from company objectives)
- Review cycles (self, manager, peer, 360°)
- Continuous feedback / check-ins
- 9-box grid (performance × potential)
- Skill gap & career path mapping

**Core entities**
```
ReviewCycle(id, org_id, name, start_date, end_date, type)
Goal(id, employee_id, cycle_id, title, description, weight, target_value, current_value, status)
ReviewForm(id, cycle_id, questions_json)
ReviewSubmission(id, cycle_id, reviewer_id, reviewee_id, relationship[self/manager/peer], responses_json, submitted_at)
Feedback(id, from_employee_id, to_employee_id, content, created_at, is_public)
NineBoxRating(id, employee_id, cycle_id, performance_score, potential_score)
```

**Key functions**
```
POST /performance/cycles                 createReviewCycle()
POST /performance/goals                  createGoal()
PUT  /performance/goals/{id}/progress     updateGoalProgress()
POST /performance/reviews/{cycle}/submit  submitReview()
GET  /performance/reviews/{cycle}/summary aggregateReviewScores()   // averages across reviewers
GET  /performance/nine-box/{cycle}        getNineBoxDistribution()
POST /performance/feedback                giveFeedback()
```

---

### 3.7 Recruitment / ATS

**Sub-features**
- Job requisitions & approvals
- Career page (public job listing)
- Resume parsing, candidate pipeline (Kanban: applied → screening → interview → offer → hired)
- Interview scheduling & scorecards
- Offer letter generation & e-signature
- Job board integrations (Naukri, LinkedIn)

**Core entities**
```
JobRequisition(id, org_id, title, department_id, headcount, status)
JobPosting(id, requisition_id, description, published_at, career_page_slug)
Candidate(id, name, email, phone, resume_url, source)
Application(id, candidate_id, job_posting_id, stage, status, applied_at)
Interview(id, application_id, interviewer_id, scheduled_at, scorecard_json)
Offer(id, application_id, ctc, joining_date, status, letter_url, signed_at)
```

**Key functions**
```
POST /recruitment/requisitions             createRequisition()
POST /recruitment/postings/{id}/publish     publishToCareerPage()
POST /recruitment/apply                     submitApplication()      // public endpoint
PUT  /recruitment/applications/{id}/stage   moveApplicationStage()   // Kanban drag-drop backend
POST /recruitment/interviews                scheduleInterview()
POST /recruitment/offers                    generateOfferLetter()   // PDF template merge
POST /recruitment/offers/{id}/accept        recordOfferAcceptance() // triggers onboarding
```

---

### 3.8 Expense Management

**Sub-features**
- Expense claim submission (multi-line, category-wise, receipt upload)
- Approval workflow (multi-level based on amount)
- Reimbursement in payroll or separate disbursement
- Policy limits per category

**Core entities**
```
ExpenseCategory(id, org_id, name, policy_limit)
ExpenseClaim(id, employee_id, total_amount, status, submitted_at)
ExpenseLine(id, claim_id, category_id, amount, date, receipt_url, description)
```

**Key functions**
```
POST /expenses/claims                submitExpenseClaim()
PUT  /expenses/claims/{id}/approve    approveClaim()          // checks policy_limit breach
GET  /expenses/claims?employee=       getClaimHistory()
POST /expenses/claims/{id}/reimburse  markReimbursed()        // links to payroll or standalone payment
```

---

### 3.9 Employee Self-Service (ESS) Portal

This isn't a separate backend module — it's a **permission-scoped view** into Core HR, Attendance, Leave, Payroll, Expenses where employees can only see/edit their own records.

**Sub-features**
- Dashboard (leave balance, upcoming holidays, birthdays, to-do list, announcements)
- Apply leave, regularize attendance, submit expense, view payslip
- Update personal details (with approval for sensitive fields)
- Org directory, social wall / announcements

**Key functions**
```
GET /ess/dashboard/{employeeId}        getDashboardWidgets()   // aggregates from multiple modules
GET /ess/directory                     searchDirectory()
POST /ess/announcements                postAnnouncement()      // admin only
GET /ess/announcements                 getFeed()
```

---

### 3.10 Engagement & Culture

**Sub-features**
- Pulse surveys (eNPS, custom)
- Recognition / shoutouts (peer-to-peer badges)
- Polls & announcements

**Core entities**
```
Survey(id, org_id, title, questions_json, anonymous, start_date, end_date)
SurveyResponse(id, survey_id, employee_id_nullable, responses_json)
Recognition(id, from_employee_id, to_employee_id, badge_type, message, created_at)
```

---

### 3.11 Helpdesk / HR Case Management

**Sub-features**
- Employee raises tickets (payroll query, HR query, IT query) categorized by type
- SLA tracking, assignment to HR/IT staff

**Core entities**
```
Ticket(id, employee_id, category, subject, description, status, priority, assigned_to)
TicketComment(id, ticket_id, author_id, comment, created_at)
```

---

### 3.12 Assets Management

**Sub-features**
- Asset inventory (laptops, ID cards, SIM cards)
- Allocation/return tracking tied to onboarding/offboarding

**Core entities**
```
Asset(id, org_id, asset_tag, category, purchase_date, status)
AssetAllocation(id, asset_id, employee_id, allocated_at, returned_at)
```

---

### 3.13 Reports & Analytics

**Sub-features**
- Headcount, attrition, diversity dashboards
- Payroll cost reports
- Attendance/leave trend reports
- Custom report builder (drag-drop fields)

**Key functions**
```
GET /reports/headcount?groupBy=department        getHeadcountReport()
GET /reports/attrition?period=                    getAttritionRate()      // (exits / avg headcount) × 100
GET /reports/payroll-cost?month=                  getPayrollCostBreakdown()
POST /reports/custom                              buildCustomReport()     // dynamic query builder
```

---

### 3.14 Admin / Settings / Platform

**Sub-features**
- Role-based access control (role → module → permission: view/edit/approve/admin)
- Multi-location/entity configuration
- Workflow builder (approval chains per module)
- Audit log (who changed what, when)
- Integrations (accounting software, Slack/Teams, biometric devices)

**Core entities**
```
Role(id, org_id, name)
Permission(id, role_id, module, action)          // e.g. (HR_MANAGER, leave, approve)
UserRole(id, user_id, role_id, scope[dept/location/all])
AuditLog(id, org_id, actor_id, entity, entity_id, action, before_json, after_json, created_at)
WorkflowRule(id, org_id, module, condition_json, approver_chain_json)
```

**Key functions**
```
POST /admin/roles                        createRole()
POST /admin/roles/{id}/permissions        assignPermission()
GET  /admin/audit-log?entity=&user=       queryAuditLog()
POST /admin/workflows                     defineApprovalWorkflow()   // e.g. leave >5 days needs 2 approvers
```

---

## 4. Cross-Cutting Concerns (easy to underestimate, critical to get right)

- **Approval workflow engine**: leave, expense, payroll, onboarding tasks, regularization all need multi-level, conditional approval chains. Build this ONCE as a generic engine (`WorkflowRule` + `ApprovalInstance` + `ApprovalStep`), not per-module.
- **Notification engine**: centralize email/push/in-app triggers off domain events (e.g. `LeaveApplied`, `PayrollRunCompleted`) rather than hardcoding notification calls inside business logic.
- **Audit trail**: every write to Employee, SalaryStructure, LeaveBalance must be logged — payroll audits require this.
- **RBAC everywhere**: every endpoint must check role scope (self / team / department / org) before returning data.
- **File storage & retention**: payslips, Form 16, resumes — plan storage lifecycle and access-control per document type.
- **Statutory rule versioning**: PF/ESI/TDS/PT rates change yearly (often at Budget time). Store rates as versioned config, not hardcoded constants.

---

## 5. Suggested Build Order (phased roadmap)

| Phase | Modules | Why this order |
|---|---|---|
| 1 | Core HR + Admin/RBAC + Auth | Everything else depends on employee master data & permissions |
| 2 | Attendance + Leave | Self-contained, high daily-use value, builds your approval-workflow engine |
| 3 | Payroll + Statutory Compliance | Depends on attendance/leave data being reliable; highest complexity, do after workflow engine is proven |
| 4 | ESS Portal + Notifications | Wraps phases 1–3 into employee-facing experience |
| 5 | Expense Management + Helpdesk + Assets | Lower complexity, incremental value |
| 6 | Recruitment/ATS + Onboarding | Independent module, can be built in parallel by a second dev if you have one |
| 7 | Performance Management + Engagement | Most schema-flexible (JSON-heavy), do last |
| 8 | Reports & Analytics + PSA (project timesheets/billing) | Needs mature data from all other modules to be meaningful |

For a single developer, Phases 1–4 alone (Core HR + Attendance + Leave + Payroll + ESS) is a legitimate, sellable HRMS product for the Indian SMB market — that's roughly what early-stage platforms shipped.

---

## 6. A Note on standard modular HRMS positioning

Two things worth flagging as you plan this:

1. **UI/branding**: don't clone specific visual designs, logos, or copy — build your own interface on top of the same *functional* blueprint above. That keeps you clean of trademark/copyright issues while still delivering equivalent capability.
2. **Compliance modules (PF/ESI/TDS) require careful legal accuracy** — these aren't just code, they need to track government-notified rates and formats, and errors have real financial consequences for whoever uses the software. Budget time to validate against official sources (EPFO, ESIC, Income Tax Dept circulars) each fiscal year rather than treating them as fixed logic.

If you want, I can go deeper on any single module next — e.g. a full ER diagram + migration scripts for Core HR + Attendance + Leave, or the payroll calculation engine logic in detail — since that's the highest-complexity piece.
