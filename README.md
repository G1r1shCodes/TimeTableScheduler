# Smart AI Timetable & Resource Management System

## Project Status

| Phase | Status |
|---|---|
| P1 — Register validation router | ✅ Done |
| P2 — Fix double-nested directory | ⚠️ Manual step required (see below) |
| P3 — Delete corrupt `{app,app` dir | ⚠️ Manual step required (see below) |
| P4 — PostgreSQL SQL schema | ✅ Done (`database/schema_postgresql.sql`) |
| P5 — Remove dead `save()` method | ✅ Done |
| P6 — Enforce `max_hours_per_day` | ✅ Done |
| P7 — Room capacity check | ✅ Done |
| P8 — Building preference scoring | ✅ Done |
| P9 — Fix instance-level state bug | ✅ Done |
| P10 — Admin CRUD endpoints | ✅ Done (`routers/admin.py`) |
| P11 — `teacher_availability` table | ✅ Done (model + scheduler integration) |
| P12 — JWT authentication | ✅ Done (`routers/auth.py`) |

---

## Manual Steps Required

### P2 — Fix double-nested directory

Your code currently lives at:
```
Time table Scheduler/scheduler/scheduler/app/
```
It should live at:
```
Time table Scheduler/scheduler/app/
```

**Steps:**
1. Open File Explorer
2. Navigate to `Time table Scheduler\scheduler\`
3. Cut everything inside the inner `scheduler\` folder
4. Paste it one level up (into the outer `scheduler\` folder)
5. Delete the now-empty inner `scheduler\` folder

### P3 — Delete corrupt `{app,app` directory

In the `scheduler\scheduler\` folder there is a corrupt directory named `{app,app`.

**Steps:**
1. Open File Explorer, navigate to that folder
2. If you can't delete it normally, open a terminal and run:
   ```
   rd /s /q "C:\Users\giris\Desktop\Time table Scheduler\scheduler\scheduler\{app,app"
   ```

---

## Quick Start

```bash
# 1. Install dependencies
cd scheduler/scheduler
pip install -r requirements.txt

# 2. Set up environment
cp .env.example .env
# Edit .env with your PostgreSQL credentials and a strong JWT_SECRET_KEY

# 3. Set up database
psql -U postgres -c "CREATE DATABASE college_timetable;"
psql -U postgres -d college_timetable -f ../../database/schema_postgresql.sql

# 4. Run the API
python run.py

# 5. Open the interactive docs
# http://localhost:8000/docs
```

---

## API Overview

| Tag | Endpoints | Auth Required |
|---|---|---|
| Auth | POST /auth/login, POST /auth/register, GET /auth/me | Login only for /me and /register |
| Scheduler | POST /schedule/generate, DELETE /schedule/clear/{id} | Admin |
| Timetable | GET /timetable/section/{id}, /teacher/{id}, /department/{id}, /room/{id}, /summary/{id} | Any authenticated |
| Validation | GET /validate/{semester_id} | Any authenticated |
| Admin | Full CRUD for teachers, rooms, subjects, sections, mappings, availability, override | Admin only |

---

## Directory Structure

```
Time table Scheduler/
├── docs/
│   └── PRD.md
├── database/
│   └── schema_postgresql.sql    ← PostgreSQL schema (replaces old SQLite file)
└── scheduler/                   ← Move contents of scheduler/scheduler/ here
    ├── app/
    │   ├── routers/
    │   │   ├── auth.py          ← NEW: JWT auth
    │   │   ├── admin.py         ← NEW: CRUD endpoints
    │   │   ├── scheduler.py     ← existing
    │   │   ├── timetable.py     ← existing
    │   │   └── validation.py    ← now registered in main.py
    │   ├── main.py              ← all 5 routers now registered
    │   ├── models.py            ← TeacherAvailability + User added
    │   ├── schemas.py
    │   ├── database.py
    │   └── scheduler.py         ← rewritten: all Phase 2 fixes applied
    ├── requirements.txt         ← jose + passlib added
    ├── run.py
    └── .env.example             ← JWT vars added
```
