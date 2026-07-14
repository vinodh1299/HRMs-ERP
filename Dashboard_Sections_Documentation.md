# HRMS Platform — Dashboard Screen: Sections & Sub-Sections
**Organization:** Asian Christian Academy
**Screen:** Home → Dashboard

---

## 1. Top Navigation Bar
- Product logo
- Organization name display
- Global search bar (search employees or actions, e.g. "Apply Leave")
- Notifications icon
- Help icon
- User profile icon (avatar, quick menu)

## 2. Left Sidebar — Main Navigation
1. **Home** (currently active)
2. **Me** — personal profile section
3. **Inbox** — pending actions/approvals
4. **My Team** — team management view
5. **My Finances** — payroll/salary related section
6. **Org** — organization directory/structure
7. **Engage** — engagement/social features
8. **Helpdesk** — support ticketing

## 3. Page-Level Tabs (within Home)
- **Dashboard** (active tab)
- **Welcome** (onboarding/welcome tab — shown with a notification indicator)

---

## 4. Dashboard — Left Column

### 4.1 Welcome Banner
- Personalized greeting ("Welcome [Employee Name]!")

### 4.2 Quick Access
- **Inbox** widget — shows pending action count/status
- **Holidays** widget — carousel of upcoming holidays with date, with "View All" link
- **On Leave Today** widget — avatars of employees currently on leave
- **Working Remotely** widget — shows who is working remotely today
- **Time Today** widget:
  - Current date display
  - Live clock (current time)
  - Work mode selector (e.g. Work From Home / Other)
  - "View All" link
- **Leave Balances** widget:
  - Circular balance indicators per leave type (e.g. Bereavement, Earned Leave, Sick Leave)
  - "Request Leave" quick action
  - "View All Balances" link

---

## 5. Dashboard — Right Column

### 5.1 Content Tabs
- **Organization** tab (active)
- **Media** tab

### 5.2 Post / Praise Section (under Organization tab)
- **Post** sub-tab — text box to write a post and mention peers
- **Praise** sub-tab — recognition/shoutout feature

### 5.3 Announcements
- List of company announcements with image, title, category
- "View More" link
- Reactions (like count, comment count) on each announcement

### 5.4 Celebrations Panel
- **Birthdays** sub-tab (count + list: "Birthdays Today", "Upcoming Birthdays" with avatars and dates)
- **Work Anniversaries** sub-tab
- **New Joinees** sub-tab

### 5.5 Social/Praise Feed
- Activity feed showing peer recognition posts (e.g. "[Employee] praised [Employees]")
- Timestamp, tagged badge/category (e.g. "High Five"), comments

---

## 6. Summary Table

| Main Section | Sub-Sections / Widgets |
|---|---|
| Top Nav Bar | Search, Notifications, Help, Profile |
| Left Sidebar | Home, Me, Inbox, My Team, My Finances, Org, Engage, Helpdesk |
| Page Tabs | Dashboard, Welcome |
| Left Column (Dashboard) | Welcome Banner, Inbox, Holidays, On Leave Today, Working Remotely, Time Today, Leave Balances |
| Right Column (Dashboard) | Organization/Media tabs, Post/Praise, Announcements, Birthdays/Anniversaries/New Joinees, Social Feed |

---

## 7. Sidebar Modules — Sections & Sub-Sections (Verified from ACA screenshots)

*Everything in this section is confirmed directly from your Asian Christian Academy HRMS instance, based on 8 screenshots. Where a sub-tab is visible but its contents weren't captured in a screenshot, it's marked "(not opened in screenshots)".*

### 7.1 Me
Top-level tabs inside **Me**: **Attendance | Leave | Performance | Expenses & Travel | Helpdesk | Apps**

- **Attendance** *(screenshot captured: Me → Attendance → Logs)*
  - Sub-tabs: **Logs & Requests**, **Attendance Requests**, **Attendance Policy**
  - Timings widget: current clock, work mode (e.g. Work From Home), attendance summary cards — Avg Hrs/Day, On Time Arrival %, On Duty days
  - Attendance Log table — filterable by month (30 Days / Jun / May / Apr / Mar / Feb / Jan), columns: Date, Attendance Visual, Effective Hours, Break Taken, Gross Hours, Arrival status
  - Actions: Partial Day Request
- **Leave** *(not opened in screenshots)*
- **Performance** *(not opened in screenshots)*
- **Expenses & Travel** *(not opened in screenshots)*
- **Helpdesk** *(shortcut into the Helpdesk module — see 7.8)*
- **Apps** *(not opened in screenshots)*

### 7.2 Inbox
Tabs: **Take Action | Notifications | Archive**
- Take Action — pending approval requests needing the user's response (showed "No Pending Requests" at time of screenshot)
- Notifications — system/action notifications
- Archive — past/resolved inbox items

### 7.3 My Team
Tabs: **Summary | Peers**
- **Summary**
  - Who Is Off Today
  - Employees On Time Today (count)
  - Late Arrivals Today (count + names)
  - Not In Yet Today
  - Work From Home / On Duty Today (with WFH/OD icons)
  - Remote Clock-ins Today
  - Team Calendar (monthly view — marks Holiday / Someone on Leave / WFH-OD days)
- **Peers**
  - List of peer employees with photo, name, designation, location, department, email
  - "View Employees" link

### 7.4 My Finances
Tabs: **Summary | My Pay | Manage Tax**
- **Summary** *(screenshot captured)*
  - Payroll Summary for selected month (e.g. "Jun 2026 (01 Jun–30 Jun)") + "View Payslip" link
  - **Payment Information**: salary mode (Bank Transfer), bank account number, IFSC
  - **Identity Information**: PAN card (masked), Date of Birth, Parent's Name, Photo ID, Address Proof
  - **Statutory Information**: PF Account Information, ESI Account Information, PT Details (state-specific, e.g. Tamil Nadu PT), LWF Details (Enabled/Disabled)
- **My Pay** *(not opened in screenshots)*
- **Manage Tax** *(not opened in screenshots — per public docs, typically covers investment declarations, Section 80C/80D, projected tax)*

### 7.5 Org
Top-level tabs inside **Org**: **Employees | Documents | Engage | Helpdesk | Hiring**

- **Employees** *(screenshot captured, both sub-tabs)*
  - **Directory** — filters by Department, Location, Legal Entity; employee search
  - **Organization Tree** — visual reporting hierarchy with employee cards (name, designation); filters: **My Department**, **Top of the Org**, **Group by Department**
- **Documents** *(not opened in screenshots — org-wide policy/document repository)*
- **Engage** *(shortcut into the Engage module — see 7.6)*
- **Helpdesk** *(shortcut into the Helpdesk module — see 7.8)*
- **Hiring** *(not opened in screenshots — ATS/recruitment module)*

### 7.6 Engage
Tabs: **Announcements | Polls | Articles**
- **Announcements** *(screenshot captured)*
  - Announcement list with status filter (e.g. **Active**)
  - Each entry shows title, category/tag (e.g. "Creche"), publish date/time
- **Polls** *(not opened in screenshots)*
- **Articles** *(not opened in screenshots)*

### 7.7 Helpdesk
Tabs: **Summary | Tickets | Reports**
- **Summary** *(screenshot captured — Helpdesk Dashboard)*
  - Ticket counters: Open Tickets, Incoming Today, Closed Today, On Hold
  - Ticket Analysis panel (department-wise, e.g. "Media"): Incoming, Closed, First Response Time, Resolution Time, SAT Score — filterable by period (e.g. Last 7 Days)
  - "Total Open vs Closed Tickets" chart
  - "Top Category-wise Open Tickets" chart
- **Tickets** *(not opened in screenshots — likely ticket list/queue view)*
- **Reports** *(not opened in screenshots)*

---

## 8. Summary Table — All Sidebar Modules (Verified)

| Module | Top Tabs | Confirmed Sub-Sections |
|---|---|---|
| Home | Dashboard, Welcome | Quick Access widgets, Organization/Media wall |
| Me | Attendance, Leave, Performance, Expenses & Travel, Helpdesk, Apps | Attendance → Logs & Requests, Attendance Requests, Attendance Policy |
| Inbox | Take Action, Notifications, Archive | Pending approvals workflow |
| My Team | Summary, Peers | Who's off, on-time/late/remote counts, team calendar, peer directory |
| My Finances | Summary, My Pay, Manage Tax | Payroll summary, payment info, identity info, statutory info (PF/ESI/PT/LWF) |
| Org | Employees, Documents, Engage, Helpdesk, Hiring | Employee Directory, Organization Tree |
| Engage | Announcements, Polls, Articles | Announcement feed with status/category |
| Helpdesk | Summary, Tickets, Reports | Dashboard: open/incoming/closed counts, ticket analysis, SAT score, category chart |

---

*Note: This is now grounded in your actual HRMS instance rather than generic research. A few sub-tabs weren't opened in the screenshots you sent (Me → Leave/Performance/Expenses & Travel/Apps, My Finances → My Pay/Manage Tax, Org → Documents/Hiring, Engage → Polls/Articles, Helpdesk → Tickets/Reports). If you send screenshots of those, I'll fill in the remaining gaps to make this fully complete.*
