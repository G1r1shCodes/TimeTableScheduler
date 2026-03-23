-- =====================================================================
-- COLLEGE TIMETABLE DATABASE — PostgreSQL Schema v3.0
-- Compatible with: PostgreSQL 13+
-- Managed by: Alembic (see backend/alembic/)
-- Tables: 13  |  Indexes: 14  |  Foreign Keys: enforced
-- =====================================================================

-- ── SCHEMA ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS buildings (
    building_id   TEXT PRIMARY KEY,
    building_name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS departments (
    dept_id   TEXT PRIMARY KEY,
    dept_name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS semesters (
    semester_id   SERIAL PRIMARY KEY,
    academic_year TEXT    NOT NULL,
    semester      INTEGER NOT NULL CHECK (semester BETWEEN 1 AND 8),
    is_active     BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (academic_year, semester)
);

CREATE TABLE IF NOT EXISTS rooms (
    room_id     TEXT    PRIMARY KEY,
    building_id TEXT    NOT NULL REFERENCES buildings(building_id),
    room_type   TEXT    NOT NULL CHECK (room_type IN ('CLASS', 'LAB', 'SEMINAR')),
    capacity    INTEGER NOT NULL CHECK (capacity > 0),
    floor       INTEGER NOT NULL DEFAULT 0,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS time_slots (
    slot_id    SERIAL PRIMARY KEY,
    day        TEXT    NOT NULL CHECK (day IN ('Mon','Tue','Wed','Thu','Fri','Sat')),
    start_time TEXT    NOT NULL,
    end_time   TEXT    NOT NULL,
    is_break   BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (day, start_time)
);

CREATE TABLE IF NOT EXISTS teachers (
    teacher_id         TEXT    PRIMARY KEY,
    teacher_name       TEXT    NOT NULL,
    dept_id            TEXT    NOT NULL REFERENCES departments(dept_id),
    preferred_building TEXT    REFERENCES buildings(building_id),
    max_hours_per_day  INTEGER NOT NULL DEFAULT 6 CHECK (max_hours_per_day BETWEEN 1 AND 8),
    email              TEXT    UNIQUE,
    phone              TEXT,
    is_active          BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS sections (
    section_id     TEXT    PRIMARY KEY,
    year           INTEGER NOT NULL CHECK (year BETWEEN 1 AND 4),
    dept_id        TEXT    NOT NULL REFERENCES departments(dept_id),
    total_students INTEGER NOT NULL CHECK (total_students > 0)
);

CREATE TABLE IF NOT EXISTS subjects (
    subject_id   TEXT    PRIMARY KEY,
    subject_name TEXT    NOT NULL,
    dept_id      TEXT    NOT NULL REFERENCES departments(dept_id),
    weekly_hours INTEGER NOT NULL CHECK (weekly_hours > 0),
    is_lab       BOOLEAN NOT NULL DEFAULT FALSE,
    slot_count   INTEGER NOT NULL DEFAULT 1 CHECK (slot_count IN (1, 2))
);

CREATE TABLE IF NOT EXISTS subject_teacher_mapping (
    mapping_id SERIAL PRIMARY KEY,
    subject_id TEXT NOT NULL REFERENCES subjects(subject_id),
    teacher_id TEXT NOT NULL REFERENCES teachers(teacher_id),
    UNIQUE (subject_id, teacher_id)
);

CREATE TABLE IF NOT EXISTS scheduler_config (
    config_id              INTEGER PRIMARY KEY CHECK (config_id = 1),
    max_continuous_classes INTEGER NOT NULL DEFAULT 3  CHECK (max_continuous_classes BETWEEN 1 AND 5),
    mandatory_break        BOOLEAN NOT NULL DEFAULT TRUE,
    max_hours_per_day      INTEGER NOT NULL DEFAULT 6  CHECK (max_hours_per_day BETWEEN 1 AND 8),
    same_building_pref     BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS timetables (
    timetable_id SERIAL PRIMARY KEY,
    semester_id  INTEGER NOT NULL REFERENCES semesters(semester_id),
    section_id   TEXT    NOT NULL REFERENCES sections(section_id),
    subject_id   TEXT    NOT NULL REFERENCES subjects(subject_id),
    teacher_id   TEXT    NOT NULL REFERENCES teachers(teacher_id),
    room_id      TEXT    NOT NULL REFERENCES rooms(room_id),
    slot_id      INTEGER NOT NULL REFERENCES time_slots(slot_id),
    UNIQUE (section_id, slot_id),
    UNIQUE (teacher_id, slot_id),
    UNIQUE (room_id,    slot_id)
);

-- NEW: teacher unavailability (sick days, off-campus, etc.)
CREATE TABLE IF NOT EXISTS teacher_availability (
    avail_id   SERIAL  PRIMARY KEY,
    teacher_id TEXT    NOT NULL REFERENCES teachers(teacher_id),
    slot_id    INTEGER NOT NULL REFERENCES time_slots(slot_id),
    is_blocked BOOLEAN NOT NULL DEFAULT TRUE,
    reason     TEXT,
    UNIQUE (teacher_id, slot_id)
);

-- NEW: users for auth (admin / teacher / student roles)
CREATE TABLE IF NOT EXISTS users (
    user_id        SERIAL  PRIMARY KEY,
    username       TEXT    NOT NULL UNIQUE,
    hashed_password TEXT   NOT NULL,
    role           TEXT    NOT NULL CHECK (role IN ('admin', 'teacher', 'student')),
    linked_id      TEXT,   -- teacher_id or section_id depending on role
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ── INDEXES ─────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_tt_semester  ON timetables(semester_id);
CREATE INDEX IF NOT EXISTS idx_tt_section   ON timetables(section_id);
CREATE INDEX IF NOT EXISTS idx_tt_teacher   ON timetables(teacher_id);
CREATE INDEX IF NOT EXISTS idx_tt_slot      ON timetables(slot_id);
CREATE INDEX IF NOT EXISTS idx_tt_room      ON timetables(room_id);
CREATE INDEX IF NOT EXISTS idx_stm_teacher  ON subject_teacher_mapping(teacher_id);
CREATE INDEX IF NOT EXISTS idx_stm_subject  ON subject_teacher_mapping(subject_id);
CREATE INDEX IF NOT EXISTS idx_tch_dept     ON teachers(dept_id);
CREATE INDEX IF NOT EXISTS idx_sec_dept     ON sections(dept_id);
CREATE INDEX IF NOT EXISTS idx_sub_dept     ON subjects(dept_id);
CREATE INDEX IF NOT EXISTS idx_rooms_bldg   ON rooms(building_id);
CREATE INDEX IF NOT EXISTS idx_slots_day    ON time_slots(day);
CREATE INDEX IF NOT EXISTS idx_avail_teacher ON teacher_availability(teacher_id);
CREATE INDEX IF NOT EXISTS idx_users_role    ON users(role);

-- ── SEED DATA ─────────────────────────────────────────────────────────
-- Run this after schema creation on a fresh database.

INSERT INTO buildings (building_id, building_name) VALUES
    ('IGSM', 'IGSM Block'),
    ('LAW',  'Law Block'),
    ('EB',   'Engineering Block'),
    ('SVH',  'Swami Vivekananda Hall'),
    ('GH',   'Glass House')
ON CONFLICT DO NOTHING;

INSERT INTO departments (dept_id, dept_name) VALUES
    ('CSE',      'Computer Science'),
    ('BT',       'Biotechnology'),
    ('ROBOTICS', 'Robotics')
ON CONFLICT DO NOTHING;

INSERT INTO semesters (semester_id, academic_year, semester, is_active) VALUES
    (1, '2024-25', 5, TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO scheduler_config
    (config_id, max_continuous_classes, mandatory_break, max_hours_per_day, same_building_pref)
VALUES (1, 3, TRUE, 6, TRUE)
ON CONFLICT DO NOTHING;

-- Time slots: Mon–Fri, 09:00–17:00 with lunch break at 13:00–14:00
INSERT INTO time_slots (day, start_time, end_time, is_break) VALUES
    ('Mon','09:00','10:00',FALSE), ('Mon','10:00','11:00',FALSE),
    ('Mon','11:00','12:00',FALSE), ('Mon','12:00','13:00',FALSE),
    ('Mon','13:00','14:00',TRUE),  ('Mon','14:00','15:00',FALSE),
    ('Mon','15:00','16:00',FALSE), ('Mon','16:00','17:00',FALSE),
    ('Tue','09:00','10:00',FALSE), ('Tue','10:00','11:00',FALSE),
    ('Tue','11:00','12:00',FALSE), ('Tue','12:00','13:00',FALSE),
    ('Tue','13:00','14:00',TRUE),  ('Tue','14:00','15:00',FALSE),
    ('Tue','15:00','16:00',FALSE), ('Tue','16:00','17:00',FALSE),
    ('Wed','09:00','10:00',FALSE), ('Wed','10:00','11:00',FALSE),
    ('Wed','11:00','12:00',FALSE), ('Wed','12:00','13:00',FALSE),
    ('Wed','13:00','14:00',TRUE),  ('Wed','14:00','15:00',FALSE),
    ('Wed','15:00','16:00',FALSE), ('Wed','16:00','17:00',FALSE),
    ('Thu','09:00','10:00',FALSE), ('Thu','10:00','11:00',FALSE),
    ('Thu','11:00','12:00',FALSE), ('Thu','12:00','13:00',FALSE),
    ('Thu','13:00','14:00',TRUE),  ('Thu','14:00','15:00',FALSE),
    ('Thu','15:00','16:00',FALSE), ('Thu','16:00','17:00',FALSE),
    ('Fri','09:00','10:00',FALSE), ('Fri','10:00','11:00',FALSE),
    ('Fri','11:00','12:00',FALSE), ('Fri','12:00','13:00',FALSE),
    ('Fri','13:00','14:00',TRUE),  ('Fri','14:00','15:00',FALSE),
    ('Fri','15:00','16:00',FALSE), ('Fri','16:00','17:00',FALSE)
ON CONFLICT DO NOTHING;

-- Default admin user (password: admin123 — change immediately in production)
-- hashed_password below is bcrypt of 'admin123'
INSERT INTO users (username, hashed_password, role, is_active) VALUES
    ('admin', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 'admin', TRUE)
ON CONFLICT DO NOTHING;
