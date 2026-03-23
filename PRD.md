---

# 📄 🧠 PRODUCT REQUIREMENTS DOCUMENT (PRD)

---

# 🟦 1. PRODUCT OVERVIEW

## 🏷 Product Name

**Smart AI Timetable & Resource Management System**

---

## 🎯 Objective

To design and implement an **intelligent timetable generation system** that:

* Eliminates scheduling conflicts
* Reduces physical movement between buildings
* Creates balanced, non-hectic schedules
* Provides centralized access to timetable and resources

---

## 👥 Target Users

| User Type | Role                            |
| --------- | ------------------------------- |
| Students  | View timetable, find free rooms |
| Teachers  | Check schedule, availability    |
| Admin     | Create and manage timetables    |

---

# 🟦 2. PROBLEM STATEMENT

Current manual scheduling systems suffer from:

* ❌ Teacher clashes
* ❌ Room conflicts
* ❌ Multiple building movement
* ❌ Uneven workload distribution
* ❌ Lack of centralized visibility
* ❌ Inefficient time usage

---

# 🟦 3. SOLUTION OVERVIEW

The system introduces:

```text
AI-based timetable generation
+
Centralized portal
+
Constraint-based scheduling
+
Resource optimization
```

---

# 🟦 4. KEY FEATURES

---

## 🔹 4.1 Timetable Generation (CORE)

* Automatic timetable generation using:

  * Genetic Algorithm (GA)
  * Simulated Annealing (SA)
* Hybrid optimization approach

---

## 🔹 4.2 Constraint Handling

### Hard Constraints (must satisfy)

* No teacher clash
* No room clash
* No section clash
* Teacher max hours per day
* Room capacity must fit students

---

### Soft Constraints (optimization)

* Same building preference
* Minimum gaps
* Compact schedules
* Balanced workload

---

## 🔹 4.3 Teacher Availability View

* View teacher schedule
* Identify free slots

---

## 🔹 4.4 Section-wise Timetable

* Input section → get full timetable

---

## 🔹 4.5 Room/Lab Availability

* Find free rooms for self-study
* View lab schedules

---

## 🔹 4.6 Admin Builder

* Manual override system
* Assign:

  * teacher
  * subject
  * room
  * time

---

## 🔹 4.7 Role-Based Access

| Role    | Permissions    |
| ------- | -------------- |
| Admin   | Full control   |
| Teacher | View schedule  |
| Student | View timetable |

---

## 🔹 4.8 Demo Mode

* Predefined login:

  * admin / teacher / student
* No dependency on DB
* Safe for presentation

---

# 🟦 5. SYSTEM ARCHITECTURE

---

## 🧱 Tech Stack

| Layer    | Technology               |
| -------- | ------------------------ |
| Frontend | React + Vite + Tailwind  |
| Backend  | Node.js + Express        |
| Database | PostgreSQL               |
| Auth     | JWT                      |
| AI Logic | GA + Simulated Annealing |

---

## 🧠 Architecture Diagram

```text
Frontend (React)
      ↓
Backend API (Node/Express)
      ↓
AI Engine (GA + SA)
      ↓
PostgreSQL Database
```

---

# 🟦 6. AI / ALGORITHM DESIGN

---

## 🧬 Genetic Algorithm

### Steps:

1. Generate initial population
2. Evaluate fitness
3. Select best candidates
4. Apply crossover
5. Apply mutation

---

## 🔥 Simulated Annealing

* Refines best GA solution
* Avoids local optimum
* Improves final output

---

## 🎯 Fitness Function

```text
Score =
+ No conflicts
+ Compact schedule
+ Same building
- Gaps
- Clashes
```

---

# 🟦 7. DATABASE DESIGN

---

## Core Tables

* teachers
* subjects
* sections
* rooms
* buildings
* time_slots
* timetables
* subject_teacher_mapping
* users

---

## Example Table (timetables)

| Field      | Description |
| ---------- | ----------- |
| section_id | Section     |
| subject_id | Subject     |
| teacher_id | Teacher     |
| room_id    | Room        |
| slot_id    | Time slot   |

---

# 🟦 8. USER FLOW

---

## 🧑‍💻 Login Flow

```text
Login → Token stored → Access dashboard
```

---

## 🧠 Timetable Generation Flow

```text
Click Generate →
Run GA →
Apply SA →
Save result →
Display timetable
```

---

## 📊 Dashboard Flow

```text
Dashboard →
View stats →
Access modules →
Generate timetable
```

---

# 🟦 9. UI COMPONENTS

---

## Main Pages

* Login Page
* Dashboard
* Teacher Schedule
* Section Timetable
* Room Availability
* Admin Builder
* Profile

---

## UI Features

* Loading indicators
* Toast notifications
* Responsive design
* Clean modern layout

---

# 🟦 10. FUNCTIONAL REQUIREMENTS

---

✔ Generate timetable automatically
✔ Avoid all conflicts
✔ Provide centralized access
✔ Support manual editing
✔ Support multiple roles

---

# 🟦 11. NON-FUNCTIONAL REQUIREMENTS

---

✔ Performance: Generate within seconds
✔ Scalability: 2000+ students
✔ Reliability: No crashes
✔ Usability: Simple UI

---

# 🟦 12. LIMITATIONS

---

* NP-hard problem → no guaranteed perfect solution
* Depends on input data quality
* Optimization may take time

---

# 🟦 13. FUTURE SCOPE

---

🚀 Add Machine Learning prediction
🚀 Mobile app
🚀 Real-time scheduling updates
🚀 Multi-campus support
🚀 Cloud deployment

---

# 🟦 14. TESTING STRATEGY

---

✔ Unit testing (backend APIs)
✔ UI testing
✔ Conflict validation
✔ Stress testing with large data

---

# 🟦 15. DEPLOYMENT PLAN

---

* Frontend: Vercel / Netlify
* Backend: Render / Railway
* DB: PostgreSQL cloud

---

# 🟦 16. SUCCESS METRICS

---

✔ Zero timetable conflicts
✔ Reduced idle gaps
✔ Reduced building movement
✔ Fast generation time

---

# 🟦 17. TEAM CONTRIBUTION

---

| Member | Role              |
| ------ | ----------------- |
| You    | Architecture + AI |
| Kunal  | Backend + DB      |
| KD     | Frontend          |

---

# 🟦 18. FINAL SUMMARY

---

This project delivers:

✔ AI-powered scheduling
✔ Centralized system
✔ Real-world applicability
✔ Scalable architecture

---

# 🎯 FINAL NOTE

This PRD is:

✔ Industry-level
✔ Viva-ready
✔ Submission-ready