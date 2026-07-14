# Roh HRMS — HRMS Platform

A fully functional, responsive, and secure HRMS and Payroll platform. Serves the needs of HR, managers, and employees with clean responsive design interfaces adapting to desktop, tablet, and mobile views.

---

## 1. Project Directory Structure

```text
hrms-erp/
│
├── backend/                  # Node.js + Express REST API Server
│   ├── db/                   # Database migrations (migrate.js) & seeds (seed.js)
│   ├── middleware/           # JWT Authentication, RBAC, and audit log logger
│   ├── routes/               # Modular REST endpoints
│   ├── .env                  # Configuration file (DB credentials, JWT secrets)
│   └── server.js             # Main entry point bootstrapping database and server
│
└── frontend/                 # Flutter Application (Single Codebase, Multi-platform)
    ├── lib/
    │   ├── core/             # Responsive utility, design system, theme, Dio network client
    │   ├── models/           # Dart representation models matching MySQL entities
    │   ├── providers/        # Riverpod State Management controllers
    │   ├── screens/          # Dashboard, Me, Inbox, My Team, Finances, Org, Engage, Helpdesk screens
    │   └── main.dart         # Entry point defining routes, auth checks, and shell layout
    │   └── services/         # API Service and database interface
    └── pubspec.yaml          # Project dependency definition
```

---

## 2. Setup Instructions

### Prerequisites
*   **Node.js** (v16+)
*   **Flutter SDK** (v3.12+)
*   **MySQL Server** running locally

### Database Setup
1.  Open MySQL Command Line or Workbench.
2.  Create the database schema named `roh`:
    ```sql
    CREATE DATABASE IF NOT EXISTS roh;
    ```

### Backend Setup
1.  Navigate to the `backend/` directory:
    ```bash
    cd backend
    ```
2.  Install dependencies:
    ```bash
    npm install
    ```
3.  Configure environment variables. Place a `.env` file directly under the `backend/` directory with the following contents:
    ```env
    DB_HOST=127.0.0.1
    DB_PORT=3306
    DB_NAME=roh
    DB_USER=root
    DB_PASSWORD=ACAdev@123#
    JWT_SECRET=hrms_platform_jwt_secret_token_2026_key
    PORT=3000
    ```
4.  Run the server:
    ```bash
    npm run dev
    ```
    *On startup, the server automatically runs migration queries to create all 29 database tables (both in-scope and stub structures), and populates initial seed records (roles, demo profiles, shifts, leaves, bank accounts, statutory parameters, mock announcements, and polls).*

### Frontend Setup
1.  Navigate to the `frontend/` directory:
    ```bash
    cd frontend
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the application on your desired device:
    *   **Web (Chrome)**:
        ```bash
        flutter run -d chrome
        ```
    *   **macOS Desktop**:
        ```bash
        flutter run -d macos
        ```
    *   **Windows Desktop**:
        ```bash
        flutter run -d windows
        ```
    *   **iOS Simulator**:
        ```bash
        flutter run -d iphonesimulator
        ```
    *   **Android Emulator**:
        ```bash
        flutter run -d android
        ```

---

## 3. Demo User Profiles (Auto-Fills Available on Login Screen)

| Role | Email | Password | Access Capabilities |
|---|---|---|---|
| **Admin** | `admin@acaindia.org` | `admin123` | Global system read/write, adding employees, auditing actions, viewing full org stats. |
| **Manager** | `manager@acaindia.org` | `manager123` | Team approvals inbox, direct reportee logs, team calendars, personal check-in/out. |
| **Employee** | `employee@acaindia.org` | `employee123` | Self-service check-in/out, leave application submissions, payslip downloads, personal records. |
