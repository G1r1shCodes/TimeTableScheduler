from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.database import get_db, engine
from app.schemas import HealthResponse
from app.routers import scheduler as scheduler_router
from app.routers import timetable as timetable_router
from app.routers import validation as validation_router
from app.routers import admin as admin_router
from app.routers import auth as auth_router

app = FastAPI(
    title       = "College Timetable Scheduler API",
    description = "Constraint-based timetable generator with admin CRUD, auth, and validation",
    version     = "3.0.0",
    docs_url    = "/docs",
    redoc_url   = "/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins     = ["*"],
    allow_methods     = ["*"],
    allow_headers     = ["*"],
)

app.include_router(auth_router.router)
app.include_router(scheduler_router.router)
app.include_router(timetable_router.router)
app.include_router(validation_router.router)
app.include_router(admin_router.router)


@app.on_event("startup")
def startup():
    """Create all tables and seed minimal data so the app works out of the box."""
    import app.models as _models  # noqa: F401 — registers all ORM models
    _models.Base.metadata.create_all(bind=engine)

    # Seed reference data + default admin user
    from app.database import SessionLocal
    db = SessionLocal()
    try:
        _seed(db)
    finally:
        db.close()


def _seed(db: Session):
    from app.models import (
        Building, Department, Semester, SchedulerConfig,
        TimeSlot, User, Teacher, Room, Subject,
        SubjectTeacherMapping, Section,
    )
    import bcrypt

    def _hash_password(plain: str) -> str:
        return bcrypt.hashpw(plain.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    def upsert(model, pk_field, pk_val, **kwargs):
        obj = db.query(model).filter(getattr(model, pk_field) == pk_val).first()
        if not obj:
            obj = model(**{pk_field: pk_val}, **kwargs)
            db.add(obj)
        return obj

    # Buildings
    for bid, bname in [('EB','Engineering Block'),('GH','Glass House'),('SVH','Swami Vivekananda Hall')]:
        upsert(Building, 'building_id', bid, building_name=bname)

    # Departments
    for did, dname in [('CSE','Computer Science'),('BT','Biotechnology'),('ECE','Electronics')]:
        upsert(Department, 'dept_id', did, dept_name=dname)

    # Semester
    if not db.query(Semester).first():
        db.add(Semester(academic_year='2024-25', semester=5, is_active=True))

    # Scheduler config
    if not db.query(SchedulerConfig).filter_by(config_id=1).first():
        db.add(SchedulerConfig(config_id=1, max_continuous_classes=3,
                               mandatory_break=True, max_hours_per_day=6,
                               same_building_pref=True))

    # Time slots Mon-Fri 09:00-17:00 with lunch break
    times = [('09:00','10:00'),('10:00','11:00'),('11:00','12:00'),('12:00','13:00'),
             ('13:00','14:00'),('14:00','15:00'),('15:00','16:00'),('16:00','17:00')]
    for day in ['Mon','Tue','Wed','Thu','Fri']:
        for start, end in times:
            is_break = (start == '13:00')
            if not db.query(TimeSlot).filter_by(day=day, start_time=start).first():
                db.add(TimeSlot(day=day, start_time=start, end_time=end, is_break=is_break))

    # Rooms
    db_rooms = [
        # CSE Labs & Classrooms (EB)
        ('CSE-LAB-1','EB','LAB',60), ('CSE-LAB-2','EB','LAB',60), ('CSE-LAB-3','EB','LAB',60),
        ('CR-101','EB','CLASS',60),  ('CR-102','EB','CLASS',60),
        ('CR-103','EB','CLASS',60),  ('CR-104','EB','CLASS',60),
        ('CR-105','EB','CLASS',60),  ('CR-106','EB','CLASS',60),
        # BT Classrooms & Labs (GH)
        ('BT-LAB-1','GH','LAB',40),  ('BT-LAB-2','GH','LAB',40),
        ('CR-201','GH','CLASS',60),  ('CR-202','GH','CLASS',60),
        # ECE & Generic (SVH)
        ('ECE-LAB-1','SVH','LAB',50),
        ('CR-301','SVH','CLASS',60), ('CR-302','SVH','CLASS',60), ('CR-303','SVH','CLASS',120)
    ]
    for rid, bld, rtype, cap in db_rooms:
        upsert(Room, 'room_id', rid, building_id=bld, room_type=rtype, capacity=cap, floor=1)

    # Teachers
    db_teachers = [
        ('T001','Dr. Sharma','CSE','EB'), ('T002','Dr. Gupta','CSE','EB'), ('T003','Dr. Patel','CSE','EB'),
        ('T004','Dr. Singh','CSE','EB'),  ('T005','Dr. Verma','CSE','EB'), ('T006','Dr. Mehta','CSE','EB'),
        ('T007','Dr. Kumar','CSE','EB'),  ('T008','Dr. Joshi','CSE','EB'), ('T009','Dr. Nair','CSE','EB'),
        ('T010','Prof. Reddy','BT','GH'), ('T011','Dr. Das','BT','GH'),    ('T012','Prof. Sen','BT','GH'),
        ('T013','Dr. Roy','BT','GH'),     ('T014','Prof. Bose','ECE','SVH'),('T015','Dr. Rao','ECE','SVH'),
        ('T016','Prof. Ali','ECE','SVH')
    ]
    for tid, tname, dept, bld in db_teachers:
        upsert(Teacher, 'teacher_id', tid, teacher_name=tname, dept_id=dept,
               preferred_building=bld, max_hours_per_day=6)

    # Subjects
    db_subjects = [
        ('CSE501','Data Structures','CSE',4,False,1),
        ('CSE502','Operating Systems','CSE',4,False,1),
        ('CSE503','DBMS','CSE',3,False,1),
        ('CSE504','AI & ML','CSE',3,False,1),
        ('CSE505','Computer Networks','CSE',3,False,1),
        ('CSE506L','OS Lab','CSE',2,True,2),
        ('CSE507L','DBMS Lab','CSE',2,True,2),
        
        ('CSE101','Programming in C','CSE',4,False,1),
        ('CSE102L','C Programming Lab','CSE',2,True,2),
        
        ('BT301','Genetics','BT',4,False,1),
        ('BT302','Microbiology','BT',3,False,1),
        ('BT303L','Microbiology Lab','BT',2,True,2),

        ('ECE401','Digital Electronics','ECE',4,False,1),
        ('ECE402','Signals & Systems','ECE',3,False,1),
        ('ECE403L','Digital Lab','ECE',2,True,2),
    ]
    for sid, sname, did, wh, islab, sc in db_subjects:
        upsert(Subject, 'subject_id', sid, subject_name=sname, dept_id=did,
               weekly_hours=wh, is_lab=islab, slot_count=sc)

    # Subject-Teacher mappings
    mappings = [
        ('CSE501','T001'),('CSE501','T002'),('CSE101','T001'),
        ('CSE502','T003'),('CSE502','T004'),('CSE102L','T003'),
        ('CSE503','T005'),('CSE503','T006'),
        ('CSE504','T007'),('CSE505','T008'),
        ('CSE506L','T003'),('CSE507L','T005'),
        ('BT301','T010'),('BT302','T011'),('BT303L','T012'),
        ('ECE401','T014'),('ECE402','T015'),('ECE403L','T016')
    ]
    for subj_id, t_id in mappings:
        if not db.query(SubjectTeacherMapping).filter_by(subject_id=subj_id, teacher_id=t_id).first():
            db.add(SubjectTeacherMapping(subject_id=subj_id, teacher_id=t_id))

    # Sections (Expanded for full DB experience)
    sections_data = [
        ('1CSE1',1,'CSE',60), ('1CSE2',1,'CSE',60), ('1CSE3',1,'CSE',60),
        ('2CSE1',2,'CSE',60), ('2CSE2',2,'CSE',60),
        ('3CSE1',3,'CSE',60), ('3CSE2',3,'CSE',60),
        ('4CSE1',4,'CSE',60),
        ('2BT1',2,'BT',40),   ('3BT1',3,'BT',40),
        ('2ECE1',2,'ECE',50), ('3ECE1',3,'ECE',50)
    ]
    for sec_id, yr, dept, std in sections_data:
        upsert(Section, 'section_id', sec_id, year=yr, dept_id=dept, total_students=std)

    # Default admin user
    if not db.query(User).filter_by(username='admin').first():
        db.add(User(
            username='admin',
            hashed_password=_hash_password('admin123'),
            role='admin',
            is_active=True,
        ))

    db.commit()


@app.get("/", response_model=HealthResponse, tags=["Health"])
def health(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        db_status = "connected"
    except Exception:
        db_status = "error"
    return HealthResponse(status="ok", db=db_status, version="3.0.0")

