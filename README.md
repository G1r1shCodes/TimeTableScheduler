# 📅 Smart AI Timetable & Resource Management

A professional, full-stack, enterprise-grade Timetable Scheduling system. It uses a constraint-satisfaction heuristic algorithm to automatically generate conflict-free schedules for university sections, teachers, and rooms.

![Timetable Scheduler Demo Mode](https://img.shields.io/badge/Status-Production_Ready-success?style=for-the-badge)
![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688?style=for-the-badge&logo=fastapi)
![React](https://img.shields.io/badge/Frontend-React-61DAFB?style=for-the-badge&logo=react)
![SQLite](https://img.shields.io/badge/Database-SQLite%2FPostgreSQL-003B57?style=for-the-badge&logo=sqlite)

---

## ✨ Features

- **🧠 Auto-Scheduling Engine**: Generates complete, collision-free weekly schedules using a randomized heuristic solver with automatic retry loops and graceful hard-constraint fallback.
- **🛡️ Strict Constraint Enforcement**: 
  - Prevents Teacher & Room double-booking.
  - Enforces Room capacity limits against Section sizes.
  - Honors Teacher maximum daily hours and building preferences.
- **📊 Advanced Data Organization**: Manage distinct relationships between Sections, Subjects, Labs/Theory, Departments, and Buildings.
- **👨‍💻 Role-Based Access (JWT)**: Secure login system with Admin functionality restricted from standard users.
- **🎛️ Admin Builder**: Full integrated CRUD interface to manage Teachers, Rooms, Subjects, and Sections.
- **🗓️ Timetable Viewer**: Dedicated, intuitive UI allowing filtering and viewing precise weekly schedules for specific Sections, Teachers, or Rooms.
- **💎 Premium SaaS UX**: A clean, minimalistic interface focusing on readability, typography, and professional design principles.

---

## 🏗️ Architecture

The project is structured as a decoupled Full-Stack Single Page Application (SPA):

- **Frontend**: React + Vite. Uses standard `axios` for API queries, protected React routes, and a pure CSS layout system (CSS Grid/Flexbox).
- **Backend**: Python + FastAPI. Employs `SQLAlchemy` as the ORM to manage database interactions.
- **Database**: Default configured to use **SQLite** (`college_timetable.db`) with auto-seeding for instantaneous local setup, but fully compatible with mature RDBMS like PostgreSQL for production.

---

## 🚀 Quick Start (Demo Mode)

The system is configured to work out-of-the-box using SQLite. When the backend starts, it automatically creates the necessary tables and seeds default dummy data, including an `admin` user.

### 1. Start the Backend

```bash
cd backend

# Install dependencies
pip install -r requirements.txt

# Run the FastAPI server
python run.py
```
*The backend API and Swagger Docs will be available at `http://localhost:8000/docs`.*

### 2. Start the Frontend

In a new terminal window:

```bash
cd frontend

# Install Node dependencies
npm install

# Start the Vite dev server
npm run dev
```
*The React application will be available at `http://localhost:5173`.*

### 3. Log In

Access the frontend and log in using the auto-seeded admin credentials:
- **Username:** `admin`
- **Password:** `admin123`

---

## ⚙️ Configuration

If you wish to switch from the local SQLite database to a production PostgreSQL instance, copy `.env.example` to `.env` inside the `backend/` folder and update the `DATABASE_URL`:

```env
DATABASE_URL=postgresql://user:password@localhost/college_timetable
```

---

## 📝 License

Designed and developed for robust institutional resource management. Feel free to fork, learn, and expand upon this architecture!
