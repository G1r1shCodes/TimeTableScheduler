-- =====================================================================
-- COLLEGE TIMETABLE DATABASE — CORRECTED SCHEMA v2.0
-- Generated for: IILM University (sample data)
-- Tables: 11 | Indexes: 12 | Foreign Keys: enforced
-- Replace teacher/subject/room data with real institutional data
--   before production use.
-- =====================================================================

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- ── SCHEMA ──────────────────────────────────────────────────────────────
CREATE TABLE buildings (
    building_id   TEXT PRIMARY KEY,
    building_name TEXT NOT NULL UNIQUE
);

CREATE TABLE departments (
    dept_id   TEXT PRIMARY KEY,
    dept_name TEXT NOT NULL UNIQUE
);

CREATE TABLE semesters (
    semester_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    academic_year TEXT    NOT NULL,
    semester      INTEGER NOT NULL CHECK (semester BETWEEN 1 AND 8),
    is_active     INTEGER NOT NULL DEFAULT 0 CHECK (is_active IN (0,1)),
    UNIQUE (academic_year, semester)
);

CREATE TABLE rooms (
    room_id      TEXT    PRIMARY KEY,
    building_id  TEXT    NOT NULL,
    room_type    TEXT    NOT NULL CHECK (room_type IN ('CLASS','LAB','SEMINAR')),
    capacity     INTEGER NOT NULL CHECK (capacity > 0),
    floor        INTEGER NOT NULL DEFAULT 0,
    is_active    INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0,1)),
    FOREIGN KEY (building_id) REFERENCES buildings(building_id)
);

CREATE TABLE time_slots (
    slot_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    day        TEXT    NOT NULL CHECK (day IN ('Mon','Tue','Wed','Thu','Fri','Sat')),
    start_time TEXT    NOT NULL,
    end_time   TEXT    NOT NULL,
    is_break   INTEGER NOT NULL DEFAULT 0 CHECK (is_break IN (0,1)),
    UNIQUE (day, start_time)
);

CREATE TABLE teachers (
    teacher_id         TEXT    PRIMARY KEY,
    teacher_name       TEXT    NOT NULL,
    dept_id            TEXT    NOT NULL,
    preferred_building TEXT,
    max_hours_per_day  INTEGER NOT NULL DEFAULT 6 CHECK (max_hours_per_day BETWEEN 1 AND 8),
    email              TEXT    UNIQUE,
    phone              TEXT,
    is_active          INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0,1)),
    FOREIGN KEY (dept_id)            REFERENCES departments(dept_id),
    FOREIGN KEY (preferred_building) REFERENCES buildings(building_id)
);

CREATE TABLE sections (
    section_id     TEXT    PRIMARY KEY,
    year           INTEGER NOT NULL CHECK (year BETWEEN 1 AND 4),
    dept_id        TEXT    NOT NULL,
    total_students INTEGER NOT NULL CHECK (total_students > 0),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE subjects (
    subject_id   TEXT    PRIMARY KEY,
    subject_name TEXT    NOT NULL,
    dept_id      TEXT    NOT NULL,
    weekly_hours INTEGER NOT NULL CHECK (weekly_hours > 0),
    is_lab       INTEGER NOT NULL DEFAULT 0 CHECK (is_lab IN (0,1)),
    slot_count   INTEGER NOT NULL DEFAULT 1 CHECK (slot_count IN (1,2)),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE subject_teacher_mapping (
    mapping_id INTEGER PRIMARY KEY AUTOINCREMENT,
    subject_id TEXT NOT NULL,
    teacher_id TEXT NOT NULL,
    UNIQUE (subject_id, teacher_id),
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id)
);

CREATE TABLE scheduler_config (
    config_id              INTEGER PRIMARY KEY CHECK (config_id = 1),
    max_continuous_classes INTEGER NOT NULL DEFAULT 3  CHECK (max_continuous_classes BETWEEN 1 AND 5),
    mandatory_break        INTEGER NOT NULL DEFAULT 1  CHECK (mandatory_break IN (0,1)),
    max_hours_per_day      INTEGER NOT NULL DEFAULT 6  CHECK (max_hours_per_day BETWEEN 1 AND 8),
    same_building_pref     INTEGER NOT NULL DEFAULT 1  CHECK (same_building_pref IN (0,1))
);

CREATE TABLE timetables (
    timetable_id INTEGER PRIMARY KEY AUTOINCREMENT,
    semester_id  INTEGER NOT NULL,
    section_id   TEXT    NOT NULL,
    subject_id   TEXT    NOT NULL,
    teacher_id   TEXT    NOT NULL,
    room_id      TEXT    NOT NULL,
    slot_id      INTEGER NOT NULL,
    UNIQUE (section_id, slot_id),
    UNIQUE (teacher_id, slot_id),
    UNIQUE (room_id,    slot_id),
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id),
    FOREIGN KEY (section_id)  REFERENCES sections(section_id),
    FOREIGN KEY (subject_id)  REFERENCES subjects(subject_id),
    FOREIGN KEY (teacher_id)  REFERENCES teachers(teacher_id),
    FOREIGN KEY (room_id)     REFERENCES rooms(room_id),
    FOREIGN KEY (slot_id)     REFERENCES time_slots(slot_id)
);

-- ── INDEXES ─────────────────────────────────────────────────────────────
CREATE INDEX idx_tt_semester ON timetables(semester_id);
CREATE INDEX idx_tt_section  ON timetables(section_id);
CREATE INDEX idx_tt_teacher  ON timetables(teacher_id);
CREATE INDEX idx_tt_slot     ON timetables(slot_id);
CREATE INDEX idx_tt_room     ON timetables(room_id);
CREATE INDEX idx_stm_teacher ON subject_teacher_mapping(teacher_id);
CREATE INDEX idx_stm_subject ON subject_teacher_mapping(subject_id);
CREATE INDEX idx_tch_dept    ON teachers(dept_id);
CREATE INDEX idx_sec_dept    ON sections(dept_id);
CREATE INDEX idx_sub_dept    ON subjects(dept_id);
CREATE INDEX idx_rooms_bldg  ON rooms(building_id);
CREATE INDEX idx_slots_day   ON time_slots(day);

-- ── SEED DATA ───────────────────────────────────────────────────────────
-- buildings
INSERT INTO buildings (building_id,building_name) VALUES ('IGSM','IGSM Block');
INSERT INTO buildings (building_id,building_name) VALUES ('LAW','Law Block');
INSERT INTO buildings (building_id,building_name) VALUES ('EB','Engineering Block');
INSERT INTO buildings (building_id,building_name) VALUES ('SVH','Swami Vivekananda Hall');
INSERT INTO buildings (building_id,building_name) VALUES ('GH','Glass House');

-- departments
INSERT INTO departments (dept_id,dept_name) VALUES ('CSE','Computer Science');
INSERT INTO departments (dept_id,dept_name) VALUES ('BT','Biotechnology');
INSERT INTO departments (dept_id,dept_name) VALUES ('ROBOTICS','Robotics');

-- semesters
INSERT INTO semesters (semester_id,academic_year,semester,is_active) VALUES (1,'2024-25',5,1);

-- scheduler_config
INSERT INTO scheduler_config (config_id,max_continuous_classes,mandatory_break,max_hours_per_day,same_building_pref) VALUES (1,3,1,6,1);

-- time_slots
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (1,'Mon','09:00','10:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (2,'Mon','10:00','11:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (3,'Mon','11:00','12:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (4,'Mon','12:00','13:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (5,'Mon','13:00','14:00',1);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (6,'Mon','14:00','15:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (7,'Mon','15:00','16:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (8,'Mon','16:00','17:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (9,'Tue','09:00','10:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (10,'Tue','10:00','11:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (11,'Tue','11:00','12:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (12,'Tue','12:00','13:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (13,'Tue','13:00','14:00',1);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (14,'Tue','14:00','15:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (15,'Tue','15:00','16:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (16,'Tue','16:00','17:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (17,'Wed','09:00','10:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (18,'Wed','10:00','11:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (19,'Wed','11:00','12:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (20,'Wed','12:00','13:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (21,'Wed','13:00','14:00',1);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (22,'Wed','14:00','15:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (23,'Wed','15:00','16:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (24,'Wed','16:00','17:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (25,'Thu','09:00','10:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (26,'Thu','10:00','11:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (27,'Thu','11:00','12:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (28,'Thu','12:00','13:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (29,'Thu','13:00','14:00',1);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (30,'Thu','14:00','15:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (31,'Thu','15:00','16:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (32,'Thu','16:00','17:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (33,'Fri','09:00','10:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (34,'Fri','10:00','11:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (35,'Fri','11:00','12:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (36,'Fri','12:00','13:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (37,'Fri','13:00','14:00',1);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (38,'Fri','14:00','15:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (39,'Fri','15:00','16:00',0);
INSERT INTO time_slots (slot_id,day,start_time,end_time,is_break) VALUES (40,'Fri','16:00','17:00',0);

-- rooms
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R001','SVH','CLASS',60,2,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R002','SVH','CLASS',60,2,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R003','SVH','CLASS',60,3,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R004','SVH','CLASS',60,3,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R005','SVH','SEMINAR',80,4,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R006','LAW','CLASS',60,1,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R007','LAW','CLASS',60,1,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R008','LAW','CLASS',60,2,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R009','LAW','CLASS',60,2,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R010','LAW','SEMINAR',40,3,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R011','EB','CLASS',60,1,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R012','EB','CLASS',60,1,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R013','EB','CLASS',60,2,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R014','EB','CLASS',60,2,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R015','EB','CLASS',60,3,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R016','EB','CLASS',60,3,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R017','EB','CLASS',60,4,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R018','EB','CLASS',60,4,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R019','EB','LAB',60,0,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R020','EB','LAB',60,0,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R021','EB','LAB',60,1,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R022','EB','LAB',60,1,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R023','GH','CLASS',60,1,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R024','GH','CLASS',60,2,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R025','GH','CLASS',60,3,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R026','GH','CLASS',60,4,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R027','GH','CLASS',60,5,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R028','IGSM','CLASS',60,1,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R029','IGSM','CLASS',60,1,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R030','IGSM','CLASS',60,2,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R031','IGSM','CLASS',60,2,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R032','IGSM','CLASS',60,3,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R033','IGSM','LAB',60,0,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R034','IGSM','LAB',60,0,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R035','IGSM','SEMINAR',40,3,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R036','SVH','LAB',60,1,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R037','SVH','LAB',60,1,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R038','LAW','CLASS',60,3,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R039','GH','CLASS',60,5,1);
INSERT INTO rooms (room_id,building_id,room_type,capacity,floor,is_active) VALUES ('R040','EB','CLASS',60,5,1);

-- subjects
INSERT INTO subjects (subject_id,subject_name,dept_id,weekly_hours,is_lab,slot_count) VALUES ('S01','AI','CSE',4,0,1);
INSERT INTO subjects (subject_id,subject_name,dept_id,weekly_hours,is_lab,slot_count) VALUES ('S02','ML','CSE',4,0,1);
INSERT INTO subjects (subject_id,subject_name,dept_id,weekly_hours,is_lab,slot_count) VALUES ('S03','DBMS','CSE',4,0,1);
INSERT INTO subjects (subject_id,subject_name,dept_id,weekly_hours,is_lab,slot_count) VALUES ('S04','Networks','CSE',3,0,1);
INSERT INTO subjects (subject_id,subject_name,dept_id,weekly_hours,is_lab,slot_count) VALUES ('S05','Compiler','CSE',3,0,1);
INSERT INTO subjects (subject_id,subject_name,dept_id,weekly_hours,is_lab,slot_count) VALUES ('S06','ML Lab','CSE',2,1,2);
INSERT INTO subjects (subject_id,subject_name,dept_id,weekly_hours,is_lab,slot_count) VALUES ('S07','DB Lab','CSE',2,1,2);
INSERT INTO subjects (subject_id,subject_name,dept_id,weekly_hours,is_lab,slot_count) VALUES ('S08','Robotics','ROBOTICS',3,0,1);
INSERT INTO subjects (subject_id,subject_name,dept_id,weekly_hours,is_lab,slot_count) VALUES ('S09','Biotech','BT',3,0,1);

-- sections
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3CSE1',3,'CSE',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3CSE2',3,'CSE',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3CSE3',3,'CSE',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3CSE4',3,'CSE',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3CSE5',3,'CSE',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3CSE6',3,'CSE',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3CSE7',3,'CSE',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3CSE8',3,'CSE',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3CSE9',3,'CSE',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3CSE10',3,'CSE',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3CSE11',3,'CSE',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3CSE12',3,'CSE',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3CSE13',3,'CSE',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3CSE14',3,'CSE',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3CSE15',3,'CSE',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3BT1',3,'BT',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3BT2',3,'BT',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3BT3',3,'BT',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3BT4',3,'BT',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3IT1',3,'ROBOTICS',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3IT2',3,'ROBOTICS',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3IT3',3,'ROBOTICS',60);
INSERT INTO sections (section_id,year,dept_id,total_students) VALUES ('3IT4',3,'ROBOTICS',60);

-- teachers
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T001','Teacher 1','CSE','EB',6,'t1@college.edu','9999000001',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T002','Teacher 2','CSE','EB',6,'t2@college.edu','9999000002',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T003','Teacher 3','CSE','EB',6,'t3@college.edu','9999000003',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T004','Teacher 4','CSE','EB',6,'t4@college.edu','9999000004',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T005','Teacher 5','CSE','EB',6,'t5@college.edu','9999000005',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T006','Teacher 6','CSE','EB',6,'t6@college.edu','9999000006',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T007','Teacher 7','CSE','EB',6,'t7@college.edu','9999000007',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T008','Teacher 8','CSE','EB',6,'t8@college.edu','9999000008',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T009','Teacher 9','CSE','EB',6,'t9@college.edu','9999000009',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T010','Teacher 10','CSE','EB',6,'t10@college.edu','9999000010',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T011','Teacher 11','CSE','EB',6,'t11@college.edu','9999000011',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T012','Teacher 12','CSE','EB',6,'t12@college.edu','9999000012',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T013','Teacher 13','CSE','EB',6,'t13@college.edu','9999000013',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T014','Teacher 14','CSE','EB',6,'t14@college.edu','9999000014',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T015','Teacher 15','CSE','EB',6,'t15@college.edu','9999000015',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T016','Teacher 16','CSE','EB',6,'t16@college.edu','9999000016',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T017','Teacher 17','CSE','EB',6,'t17@college.edu','9999000017',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T018','Teacher 18','CSE','EB',6,'t18@college.edu','9999000018',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T019','Teacher 19','CSE','EB',6,'t19@college.edu','9999000019',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T020','Teacher 20','CSE','EB',6,'t20@college.edu','9999000020',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T021','Teacher 21','CSE','EB',6,'t21@college.edu','9999000021',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T022','Teacher 22','CSE','EB',6,'t22@college.edu','9999000022',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T023','Teacher 23','CSE','EB',6,'t23@college.edu','9999000023',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T024','Teacher 24','CSE','EB',6,'t24@college.edu','9999000024',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T025','Teacher 25','CSE','EB',6,'t25@college.edu','9999000025',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T026','Teacher 26','CSE','EB',6,'t26@college.edu','9999000026',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T027','Teacher 27','CSE','EB',6,'t27@college.edu','9999000027',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T028','Teacher 28','CSE','EB',6,'t28@college.edu','9999000028',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T029','Teacher 29','CSE','EB',6,'t29@college.edu','9999000029',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T030','Teacher 30','CSE','EB',6,'t30@college.edu','9999000030',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T031','Teacher 31','CSE','EB',6,'t31@college.edu','9999000031',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T032','Teacher 32','CSE','EB',6,'t32@college.edu','9999000032',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T033','Teacher 33','CSE','EB',6,'t33@college.edu','9999000033',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T034','Teacher 34','CSE','EB',6,'t34@college.edu','9999000034',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T035','Teacher 35','CSE','EB',6,'t35@college.edu','9999000035',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T036','Teacher 36','CSE','EB',6,'t36@college.edu','9999000036',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T037','Teacher 37','CSE','EB',6,'t37@college.edu','9999000037',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T038','Teacher 38','CSE','EB',6,'t38@college.edu','9999000038',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T039','Teacher 39','CSE','EB',6,'t39@college.edu','9999000039',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T040','Teacher 40','CSE','EB',6,'t40@college.edu','9999000040',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T041','Teacher 41','CSE','EB',6,'t41@college.edu','9999000041',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T042','Teacher 42','CSE','EB',6,'t42@college.edu','9999000042',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T043','Teacher 43','CSE','EB',6,'t43@college.edu','9999000043',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T044','Teacher 44','CSE','EB',6,'t44@college.edu','9999000044',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T045','Teacher 45','CSE','EB',6,'t45@college.edu','9999000045',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T046','Teacher 46','CSE','EB',6,'t46@college.edu','9999000046',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T047','Teacher 47','CSE','EB',6,'t47@college.edu','9999000047',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T048','Teacher 48','CSE','EB',6,'t48@college.edu','9999000048',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T049','Teacher 49','CSE','EB',6,'t49@college.edu','9999000049',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T050','Teacher 50','CSE','EB',6,'t50@college.edu','9999000050',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T051','Teacher 51','CSE','EB',6,'t51@college.edu','9999000051',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T052','Teacher 52','CSE','EB',6,'t52@college.edu','9999000052',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T053','Teacher 53','CSE','EB',6,'t53@college.edu','9999000053',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T054','Teacher 54','CSE','EB',6,'t54@college.edu','9999000054',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T055','Teacher 55','CSE','EB',6,'t55@college.edu','9999000055',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T056','Teacher 56','CSE','EB',6,'t56@college.edu','9999000056',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T057','Teacher 57','CSE','EB',6,'t57@college.edu','9999000057',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T058','Teacher 58','CSE','EB',6,'t58@college.edu','9999000058',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T059','Teacher 59','CSE','EB',6,'t59@college.edu','9999000059',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T060','Teacher 60','CSE','EB',6,'t60@college.edu','9999000060',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T061','Teacher 61','CSE','EB',6,'t61@college.edu','9999000061',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T062','Teacher 62','CSE','EB',6,'t62@college.edu','9999000062',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T063','Teacher 63','CSE','EB',6,'t63@college.edu','9999000063',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T064','Teacher 64','CSE','EB',6,'t64@college.edu','9999000064',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T065','Teacher 65','CSE','EB',6,'t65@college.edu','9999000065',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T066','Teacher 66','CSE','EB',6,'t66@college.edu','9999000066',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T067','Teacher 67','CSE','EB',6,'t67@college.edu','9999000067',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T068','Teacher 68','CSE','EB',6,'t68@college.edu','9999000068',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T069','Teacher 69','CSE','EB',6,'t69@college.edu','9999000069',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T070','Teacher 70','CSE','EB',6,'t70@college.edu','9999000070',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T071','Teacher 71','CSE','EB',6,'t71@college.edu','9999000071',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T072','Teacher 72','CSE','EB',6,'t72@college.edu','9999000072',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T073','Teacher 73','CSE','EB',6,'t73@college.edu','9999000073',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T074','Teacher 74','CSE','EB',6,'t74@college.edu','9999000074',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T075','Teacher 75','CSE','EB',6,'t75@college.edu','9999000075',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T076','Teacher 76','CSE','EB',6,'t76@college.edu','9999000076',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T077','Teacher 77','CSE','EB',6,'t77@college.edu','9999000077',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T078','Teacher 78','CSE','EB',6,'t78@college.edu','9999000078',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T079','Teacher 79','CSE','EB',6,'t79@college.edu','9999000079',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T080','Teacher 80','CSE','EB',6,'t80@college.edu','9999000080',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T081','Teacher 81','CSE','EB',6,'t81@college.edu','9999000081',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T082','Teacher 82','CSE','EB',6,'t82@college.edu','9999000082',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T083','Teacher 83','CSE','EB',6,'t83@college.edu','9999000083',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T084','Teacher 84','CSE','EB',6,'t84@college.edu','9999000084',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T085','Teacher 85','CSE','EB',6,'t85@college.edu','9999000085',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T086','Teacher 86','CSE','EB',6,'t86@college.edu','9999000086',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T087','Teacher 87','CSE','EB',6,'t87@college.edu','9999000087',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T088','Teacher 88','CSE','EB',6,'t88@college.edu','9999000088',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T089','Teacher 89','CSE','EB',6,'t89@college.edu','9999000089',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T090','Teacher 90','CSE','EB',6,'t90@college.edu','9999000090',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T091','Teacher 91','CSE','EB',6,'t91@college.edu','9999000091',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T092','Teacher 92','CSE','EB',6,'t92@college.edu','9999000092',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T093','Teacher 93','CSE','EB',6,'t93@college.edu','9999000093',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T094','Teacher 94','CSE','EB',6,'t94@college.edu','9999000094',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T095','Teacher 95','CSE','EB',6,'t95@college.edu','9999000095',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T096','Teacher 96','CSE','EB',6,'t96@college.edu','9999000096',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T097','Teacher 97','CSE','EB',6,'t97@college.edu','9999000097',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T098','Teacher 98','CSE','EB',6,'t98@college.edu','9999000098',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T099','Teacher 99','CSE','EB',6,'t99@college.edu','9999000099',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T100','Teacher 100','CSE','EB',6,'t100@college.edu','9999000100',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T101','Teacher 101','ROBOTICS','EB',6,'t101@college.edu','9999000101',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T102','Teacher 102','ROBOTICS','EB',6,'t102@college.edu','9999000102',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T103','Teacher 103','ROBOTICS','EB',6,'t103@college.edu','9999000103',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T104','Teacher 104','ROBOTICS','EB',6,'t104@college.edu','9999000104',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T105','Teacher 105','ROBOTICS','EB',6,'t105@college.edu','9999000105',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T106','Teacher 106','ROBOTICS','EB',6,'t106@college.edu','9999000106',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T107','Teacher 107','ROBOTICS','EB',6,'t107@college.edu','9999000107',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T108','Teacher 108','ROBOTICS','EB',6,'t108@college.edu','9999000108',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T109','Teacher 109','ROBOTICS','EB',6,'t109@college.edu','9999000109',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T110','Teacher 110','ROBOTICS','EB',6,'t110@college.edu','9999000110',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T111','Teacher 111','ROBOTICS','EB',6,'t111@college.edu','9999000111',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T112','Teacher 112','ROBOTICS','EB',6,'t112@college.edu','9999000112',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T113','Teacher 113','ROBOTICS','EB',6,'t113@college.edu','9999000113',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T114','Teacher 114','ROBOTICS','EB',6,'t114@college.edu','9999000114',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T115','Teacher 115','ROBOTICS','EB',6,'t115@college.edu','9999000115',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T116','Teacher 116','ROBOTICS','EB',6,'t116@college.edu','9999000116',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T117','Teacher 117','ROBOTICS','EB',6,'t117@college.edu','9999000117',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T118','Teacher 118','ROBOTICS','EB',6,'t118@college.edu','9999000118',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T119','Teacher 119','ROBOTICS','EB',6,'t119@college.edu','9999000119',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T120','Teacher 120','ROBOTICS','EB',6,'t120@college.edu','9999000120',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T121','Teacher 121','ROBOTICS','EB',6,'t121@college.edu','9999000121',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T122','Teacher 122','ROBOTICS','EB',6,'t122@college.edu','9999000122',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T123','Teacher 123','ROBOTICS','EB',6,'t123@college.edu','9999000123',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T124','Teacher 124','ROBOTICS','EB',6,'t124@college.edu','9999000124',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T125','Teacher 125','ROBOTICS','EB',6,'t125@college.edu','9999000125',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T126','Teacher 126','ROBOTICS','EB',6,'t126@college.edu','9999000126',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T127','Teacher 127','ROBOTICS','EB',6,'t127@college.edu','9999000127',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T128','Teacher 128','ROBOTICS','EB',6,'t128@college.edu','9999000128',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T129','Teacher 129','ROBOTICS','EB',6,'t129@college.edu','9999000129',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T130','Teacher 130','ROBOTICS','EB',6,'t130@college.edu','9999000130',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T131','Teacher 131','ROBOTICS','EB',6,'t131@college.edu','9999000131',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T132','Teacher 132','ROBOTICS','EB',6,'t132@college.edu','9999000132',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T133','Teacher 133','ROBOTICS','EB',6,'t133@college.edu','9999000133',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T134','Teacher 134','ROBOTICS','EB',6,'t134@college.edu','9999000134',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T135','Teacher 135','ROBOTICS','EB',6,'t135@college.edu','9999000135',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T136','Teacher 136','ROBOTICS','EB',6,'t136@college.edu','9999000136',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T137','Teacher 137','ROBOTICS','EB',6,'t137@college.edu','9999000137',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T138','Teacher 138','ROBOTICS','EB',6,'t138@college.edu','9999000138',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T139','Teacher 139','ROBOTICS','EB',6,'t139@college.edu','9999000139',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T140','Teacher 140','ROBOTICS','EB',6,'t140@college.edu','9999000140',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T141','Teacher 141','ROBOTICS','EB',6,'t141@college.edu','9999000141',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T142','Teacher 142','ROBOTICS','EB',6,'t142@college.edu','9999000142',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T143','Teacher 143','ROBOTICS','EB',6,'t143@college.edu','9999000143',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T144','Teacher 144','ROBOTICS','EB',6,'t144@college.edu','9999000144',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T145','Teacher 145','ROBOTICS','EB',6,'t145@college.edu','9999000145',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T146','Teacher 146','ROBOTICS','EB',6,'t146@college.edu','9999000146',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T147','Teacher 147','ROBOTICS','EB',6,'t147@college.edu','9999000147',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T148','Teacher 148','ROBOTICS','EB',6,'t148@college.edu','9999000148',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T149','Teacher 149','ROBOTICS','EB',6,'t149@college.edu','9999000149',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T150','Teacher 150','ROBOTICS','EB',6,'t150@college.edu','9999000150',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T151','Teacher 151','BT','GH',6,'t151@college.edu','9999000151',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T152','Teacher 152','BT','GH',6,'t152@college.edu','9999000152',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T153','Teacher 153','BT','GH',6,'t153@college.edu','9999000153',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T154','Teacher 154','BT','GH',6,'t154@college.edu','9999000154',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T155','Teacher 155','BT','GH',6,'t155@college.edu','9999000155',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T156','Teacher 156','BT','GH',6,'t156@college.edu','9999000156',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T157','Teacher 157','BT','GH',6,'t157@college.edu','9999000157',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T158','Teacher 158','BT','GH',6,'t158@college.edu','9999000158',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T159','Teacher 159','BT','GH',6,'t159@college.edu','9999000159',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T160','Teacher 160','BT','GH',6,'t160@college.edu','9999000160',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T161','Teacher 161','BT','GH',6,'t161@college.edu','9999000161',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T162','Teacher 162','BT','GH',6,'t162@college.edu','9999000162',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T163','Teacher 163','BT','GH',6,'t163@college.edu','9999000163',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T164','Teacher 164','BT','GH',6,'t164@college.edu','9999000164',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T165','Teacher 165','BT','GH',6,'t165@college.edu','9999000165',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T166','Teacher 166','BT','GH',6,'t166@college.edu','9999000166',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T167','Teacher 167','BT','GH',6,'t167@college.edu','9999000167',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T168','Teacher 168','BT','GH',6,'t168@college.edu','9999000168',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T169','Teacher 169','BT','GH',6,'t169@college.edu','9999000169',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T170','Teacher 170','BT','GH',6,'t170@college.edu','9999000170',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T171','Teacher 171','BT','GH',6,'t171@college.edu','9999000171',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T172','Teacher 172','BT','GH',6,'t172@college.edu','9999000172',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T173','Teacher 173','BT','GH',6,'t173@college.edu','9999000173',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T174','Teacher 174','BT','GH',6,'t174@college.edu','9999000174',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T175','Teacher 175','BT','GH',6,'t175@college.edu','9999000175',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T176','Teacher 176','BT','GH',6,'t176@college.edu','9999000176',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T177','Teacher 177','BT','GH',6,'t177@college.edu','9999000177',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T178','Teacher 178','BT','GH',6,'t178@college.edu','9999000178',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T179','Teacher 179','BT','GH',6,'t179@college.edu','9999000179',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T180','Teacher 180','BT','GH',6,'t180@college.edu','9999000180',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T181','Teacher 181','BT','GH',6,'t181@college.edu','9999000181',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T182','Teacher 182','BT','GH',6,'t182@college.edu','9999000182',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T183','Teacher 183','BT','GH',6,'t183@college.edu','9999000183',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T184','Teacher 184','BT','GH',6,'t184@college.edu','9999000184',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T185','Teacher 185','BT','GH',6,'t185@college.edu','9999000185',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T186','Teacher 186','BT','GH',6,'t186@college.edu','9999000186',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T187','Teacher 187','BT','GH',6,'t187@college.edu','9999000187',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T188','Teacher 188','BT','GH',6,'t188@college.edu','9999000188',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T189','Teacher 189','BT','GH',6,'t189@college.edu','9999000189',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T190','Teacher 190','BT','GH',6,'t190@college.edu','9999000190',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T191','Teacher 191','BT','GH',6,'t191@college.edu','9999000191',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T192','Teacher 192','BT','GH',6,'t192@college.edu','9999000192',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T193','Teacher 193','BT','GH',6,'t193@college.edu','9999000193',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T194','Teacher 194','BT','GH',6,'t194@college.edu','9999000194',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T195','Teacher 195','BT','GH',6,'t195@college.edu','9999000195',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T196','Teacher 196','BT','GH',6,'t196@college.edu','9999000196',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T197','Teacher 197','BT','GH',6,'t197@college.edu','9999000197',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T198','Teacher 198','BT','GH',6,'t198@college.edu','9999000198',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T199','Teacher 199','BT','GH',6,'t199@college.edu','9999000199',1);
INSERT INTO teachers (teacher_id,teacher_name,dept_id,preferred_building,max_hours_per_day,email,phone,is_active) VALUES ('T200','Teacher 200','BT','GH',6,'t200@college.edu','9999000200',1);

-- subject_teacher_mapping
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (1,'S01','T082');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (2,'S01','T015');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (3,'S01','T004');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (4,'S01','T095');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (5,'S01','T036');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (6,'S01','T032');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (7,'S01','T029');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (8,'S01','T018');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (9,'S01','T014');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (10,'S01','T087');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (11,'S01','T070');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (12,'S01','T012');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (13,'S01','T076');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (14,'S01','T055');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (15,'S02','T005');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (16,'S02','T004');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (17,'S02','T012');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (18,'S02','T028');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (19,'S02','T030');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (20,'S02','T065');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (21,'S02','T078');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (22,'S02','T072');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (23,'S02','T026');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (24,'S02','T092');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (25,'S02','T084');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (26,'S02','T090');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (27,'S02','T070');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (28,'S02','T054');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (29,'S03','T029');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (30,'S03','T058');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (31,'S03','T076');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (32,'S03','T036');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (33,'S03','T001');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (34,'S03','T098');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (35,'S03','T021');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (36,'S03','T090');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (37,'S03','T055');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (38,'S03','T044');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (39,'S03','T020');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (40,'S03','T028');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (41,'S03','T014');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (42,'S03','T012');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (43,'S04','T049');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (44,'S04','T013');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (45,'S04','T046');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (46,'S04','T045');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (47,'S04','T078');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (48,'S04','T034');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (49,'S04','T006');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (50,'S04','T094');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (51,'S04','T059');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (52,'S04','T069');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (53,'S04','T016');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (54,'S04','T011');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (55,'S04','T071');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (56,'S04','T038');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (57,'S05','T081');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (58,'S05','T080');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (59,'S05','T047');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (60,'S05','T074');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (61,'S05','T025');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (62,'S05','T091');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (63,'S05','T009');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (64,'S05','T006');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (65,'S05','T085');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (66,'S05','T030');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (67,'S05','T099');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (68,'S05','T038');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (69,'S05','T011');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (70,'S05','T013');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (71,'S06','T049');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (72,'S06','T036');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (73,'S06','T059');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (74,'S06','T082');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (75,'S06','T047');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (76,'S06','T021');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (77,'S06','T048');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (78,'S06','T046');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (79,'S06','T027');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (80,'S06','T086');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (81,'S06','T035');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (82,'S06','T090');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (83,'S06','T088');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (84,'S06','T083');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (85,'S07','T010');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (86,'S07','T078');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (87,'S07','T082');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (88,'S07','T022');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (89,'S07','T069');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (90,'S07','T094');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (91,'S07','T032');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (92,'S07','T021');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (93,'S07','T060');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (94,'S07','T049');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (95,'S07','T035');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (96,'S07','T089');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (97,'S07','T072');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (98,'S07','T029');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (99,'S08','T144');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (100,'S08','T121');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (101,'S08','T104');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (102,'S08','T115');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (103,'S08','T103');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (104,'S08','T149');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (105,'S08','T126');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (106,'S08','T118');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (107,'S09','T155');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (108,'S09','T164');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (109,'S09','T187');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (110,'S09','T196');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (111,'S09','T171');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (112,'S09','T199');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (113,'S09','T192');
INSERT INTO subject_teacher_mapping (mapping_id,subject_id,teacher_id) VALUES (114,'S09','T182');
