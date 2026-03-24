"""
app/routers/admin.py
====================
Admin CRUD endpoints — protected by require_admin dependency.

Covers:
  Teachers    GET/POST /admin/teachers,  DELETE /admin/teachers/{id}
  Rooms       GET/POST /admin/rooms,     DELETE /admin/rooms/{id}
  Subjects    GET/POST /admin/subjects,  DELETE /admin/subjects/{id}
  Sections    GET/POST /admin/sections,  DELETE /admin/sections/{id}
  Mappings    GET/POST /admin/mappings,  DELETE /admin/mappings/{id}
  Availability POST /admin/availability, DELETE /admin/availability/{id}
  Timetable override  POST /admin/timetable/override
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import (
    Teacher, Room, Subject, Section,
    SubjectTeacherMapping, TeacherAvailability, Timetable,
    Building, Department, Semester, TimeSlot, SchedulerConfig
)
from app.routers.auth import require_admin
from app.models import User

router = APIRouter(prefix="/admin", tags=["Admin"])


# ═════════════════════════════════════════════════════════════════════════
# Schemas
# ═════════════════════════════════════════════════════════════════════════

class TeacherCreate(BaseModel):
    teacher_id:         str
    teacher_name:       str
    dept_id:            str
    preferred_building: Optional[str] = None
    max_hours_per_day:  int = 6
    email:              Optional[str] = None
    phone:              Optional[str] = None


class TeacherOut(TeacherCreate):
    is_active: bool
    class Config: from_attributes = True


class RoomCreate(BaseModel):
    room_id:     str
    building_id: str
    room_type:   str        # CLASS | LAB | SEMINAR
    capacity:    int
    floor:       int = 0


class RoomOut(RoomCreate):
    is_active: bool
    class Config: from_attributes = True


class SubjectCreate(BaseModel):
    subject_id:   str
    subject_name: str
    dept_id:      str
    weekly_hours: int
    is_lab:       bool = False
    slot_count:   int  = 1


class SubjectOut(SubjectCreate):
    class Config: from_attributes = True


class SectionCreate(BaseModel):
    section_id:     str
    year:           int
    dept_id:        str
    total_students: int


class SectionOut(SectionCreate):
    class Config: from_attributes = True


class MappingCreate(BaseModel):
    subject_id: str
    teacher_id: str


class MappingOut(MappingCreate):
    mapping_id: int
    class Config: from_attributes = True


class AvailabilityCreate(BaseModel):
    teacher_id: str
    slot_id:    int
    is_blocked: bool = True
    reason:     Optional[str] = None


class AvailabilityOut(AvailabilityCreate):
    avail_id: int
    class Config: from_attributes = True


class TimetableOverride(BaseModel):
    """Manually assign a single slot in the timetable."""
    semester_id: int
    section_id:  str
    subject_id:  str
    teacher_id:  str
    room_id:     str
    slot_id:     int


class BuildingCreate(BaseModel):
    building_id:   str
    building_name: str


class BuildingOut(BuildingCreate):
    class Config: from_attributes = True


class DepartmentCreate(BaseModel):
    dept_id:   str
    dept_name: str


class DepartmentOut(DepartmentCreate):
    class Config: from_attributes = True


class SemesterCreate(BaseModel):
    academic_year: str
    semester:      int
    is_active:     bool = False


class SemesterOut(SemesterCreate):
    semester_id: int
    class Config: from_attributes = True


class TimeSlotCreate(BaseModel):
    day:        str
    start_time: str
    end_time:   str
    is_break:   bool = False


class TimeSlotOut(TimeSlotCreate):
    slot_id: int
    class Config: from_attributes = True


class ConfigUpdate(BaseModel):
    max_continuous_classes: int
    mandatory_break:        bool
    max_hours_per_day:      int
    same_building_pref:     bool


class ConfigOut(ConfigUpdate):
    config_id: int
    class Config: from_attributes = True


# ═════════════════════════════════════════════════════════════════════════
# Teachers
# ═════════════════════════════════════════════════════════════════════════

@router.get("/teachers", response_model=List[TeacherOut], summary="List all teachers")
def list_teachers(
    dept_id:  Optional[str] = None,
    active:   bool = True,
    db:       Session = Depends(get_db),
    _admin:   User    = Depends(require_admin),
):
    q = db.query(Teacher).filter_by(is_active=active)
    if dept_id:
        q = q.filter_by(dept_id=dept_id)
    return q.order_by(Teacher.teacher_id).all()


@router.post("/teachers", response_model=TeacherOut, status_code=201,
             summary="Add a new teacher")
def create_teacher(
    body:   TeacherCreate,
    db:     Session = Depends(get_db),
    _admin: User    = Depends(require_admin),
):
    if db.query(Teacher).filter_by(teacher_id=body.teacher_id).first():
        raise HTTPException(409, f"Teacher {body.teacher_id} already exists")
    t = Teacher(**body.model_dump())
    db.add(t)
    db.commit()
    db.refresh(t)
    return t


@router.put("/teachers/{teacher_id}", response_model=TeacherOut,
            summary="Update a teacher")
def update_teacher(
    teacher_id: str,
    body:       TeacherCreate,
    db:         Session = Depends(get_db),
    _admin:     User    = Depends(require_admin),
):
    t = db.query(Teacher).filter_by(teacher_id=teacher_id).first()
    if not t:
        raise HTTPException(404, f"Teacher {teacher_id} not found")
    for k, v in body.model_dump().items():
        setattr(t, k, v)
    db.commit()
    db.refresh(t)
    return t


@router.delete("/teachers/{teacher_id}", summary="Deactivate a teacher")
def delete_teacher(
    teacher_id: str,
    db:         Session = Depends(get_db),
    _admin:     User    = Depends(require_admin),
):
    t = db.query(Teacher).filter_by(teacher_id=teacher_id).first()
    if not t:
        raise HTTPException(404, f"Teacher {teacher_id} not found")
    t.is_active = False
    db.commit()
    return {"message": f"Teacher {teacher_id} deactivated"}


# ═════════════════════════════════════════════════════════════════════════
# Rooms
# ═════════════════════════════════════════════════════════════════════════

@router.get("/rooms", response_model=List[RoomOut], summary="List all rooms")
def list_rooms(
    building_id: Optional[str] = None,
    room_type:   Optional[str] = None,
    db:          Session = Depends(get_db),
    _admin:      User    = Depends(require_admin),
):
    q = db.query(Room).filter_by(is_active=True)
    if building_id: q = q.filter_by(building_id=building_id)
    if room_type:   q = q.filter_by(room_type=room_type)
    return q.order_by(Room.room_id).all()


@router.post("/rooms", response_model=RoomOut, status_code=201,
             summary="Add a new room")
def create_room(
    body:   RoomCreate,
    db:     Session = Depends(get_db),
    _admin: User    = Depends(require_admin),
):
    if db.query(Room).filter_by(room_id=body.room_id).first():
        raise HTTPException(409, f"Room {body.room_id} already exists")
    r = Room(**body.model_dump())
    db.add(r)
    db.commit()
    db.refresh(r)
    return r


@router.delete("/rooms/{room_id}", summary="Deactivate a room")
def delete_room(
    room_id: str,
    db:      Session = Depends(get_db),
    _admin:  User    = Depends(require_admin),
):
    r = db.query(Room).filter_by(room_id=room_id).first()
    if not r:
        raise HTTPException(404, f"Room {room_id} not found")
    r.is_active = False
    db.commit()
    return {"message": f"Room {room_id} deactivated"}


# ═════════════════════════════════════════════════════════════════════════
# Subjects
# ═════════════════════════════════════════════════════════════════════════

@router.get("/subjects", response_model=List[SubjectOut], summary="List all subjects")
def list_subjects(
    dept_id: Optional[str] = None,
    db:      Session = Depends(get_db),
    _admin:  User    = Depends(require_admin),
):
    q = db.query(Subject)
    if dept_id: q = q.filter_by(dept_id=dept_id)
    return q.order_by(Subject.subject_id).all()


@router.post("/subjects", response_model=SubjectOut, status_code=201,
             summary="Add a new subject")
def create_subject(
    body:   SubjectCreate,
    db:     Session = Depends(get_db),
    _admin: User    = Depends(require_admin),
):
    if db.query(Subject).filter_by(subject_id=body.subject_id).first():
        raise HTTPException(409, f"Subject {body.subject_id} already exists")
    s = Subject(**body.model_dump())
    db.add(s)
    db.commit()
    db.refresh(s)
    return s


@router.delete("/subjects/{subject_id}", summary="Delete a subject")
def delete_subject(
    subject_id: str,
    db:         Session = Depends(get_db),
    _admin:     User    = Depends(require_admin),
):
    s = db.query(Subject).filter_by(subject_id=subject_id).first()
    if not s:
        raise HTTPException(404, f"Subject {subject_id} not found")
    db.delete(s)
    db.commit()
    return {"message": f"Subject {subject_id} deleted"}


# ═════════════════════════════════════════════════════════════════════════
# Sections
# ═════════════════════════════════════════════════════════════════════════

@router.get("/sections", response_model=List[SectionOut], summary="List all sections")
def list_sections(
    dept_id: Optional[str] = None,
    db:      Session = Depends(get_db),
    _admin:  User    = Depends(require_admin),
):
    q = db.query(Section)
    if dept_id: q = q.filter_by(dept_id=dept_id)
    return q.order_by(Section.section_id).all()


@router.post("/sections", response_model=SectionOut, status_code=201,
             summary="Add a new section")
def create_section(
    body:   SectionCreate,
    db:     Session = Depends(get_db),
    _admin: User    = Depends(require_admin),
):
    if db.query(Section).filter_by(section_id=body.section_id).first():
        raise HTTPException(409, f"Section {body.section_id} already exists")
    s = Section(**body.model_dump())
    db.add(s)
    db.commit()
    db.refresh(s)
    return s


@router.delete("/sections/{section_id}", summary="Delete a section")
def delete_section(
    section_id: str,
    db:         Session = Depends(get_db),
    _admin:     User    = Depends(require_admin),
):
    s = db.query(Section).filter_by(section_id=section_id).first()
    if not s:
        raise HTTPException(404, f"Section {section_id} not found")
    db.delete(s)
    db.commit()
    return {"message": f"Section {section_id} deleted"}


# ═════════════════════════════════════════════════════════════════════════
# Subject–Teacher Mappings
# ═════════════════════════════════════════════════════════════════════════

@router.get("/mappings", response_model=List[MappingOut],
            summary="List subject-teacher mappings")
def list_mappings(
    subject_id: Optional[str] = None,
    teacher_id: Optional[str] = None,
    db:         Session = Depends(get_db),
    _admin:     User    = Depends(require_admin),
):
    q = db.query(SubjectTeacherMapping)
    if subject_id: q = q.filter_by(subject_id=subject_id)
    if teacher_id: q = q.filter_by(teacher_id=teacher_id)
    return q.all()


@router.post("/mappings", response_model=MappingOut, status_code=201,
             summary="Assign a teacher to a subject")
def create_mapping(
    body:   MappingCreate,
    db:     Session = Depends(get_db),
    _admin: User    = Depends(require_admin),
):
    exists = db.query(SubjectTeacherMapping).filter_by(
        subject_id=body.subject_id, teacher_id=body.teacher_id
    ).first()
    if exists:
        raise HTTPException(409, "Mapping already exists")
    m = SubjectTeacherMapping(**body.model_dump())
    db.add(m)
    db.commit()
    db.refresh(m)
    return m


@router.delete("/mappings/{mapping_id}", summary="Remove a subject-teacher mapping")
def delete_mapping(
    mapping_id: int,
    db:         Session = Depends(get_db),
    _admin:     User    = Depends(require_admin),
):
    m = db.query(SubjectTeacherMapping).filter_by(mapping_id=mapping_id).first()
    if not m:
        raise HTTPException(404, "Mapping not found")
    db.delete(m)
    db.commit()
    return {"message": f"Mapping {mapping_id} deleted"}


# ═════════════════════════════════════════════════════════════════════════
# Teacher Availability (block slots)
# ═════════════════════════════════════════════════════════════════════════

@router.get("/availability", response_model=List[AvailabilityOut],
            summary="List teacher availability blocks")
def list_availability(
    teacher_id: Optional[str] = None,
    db:         Session = Depends(get_db),
    _admin:     User    = Depends(require_admin),
):
    q = db.query(TeacherAvailability)
    if teacher_id: q = q.filter_by(teacher_id=teacher_id)
    return q.all()


@router.post("/availability", response_model=AvailabilityOut, status_code=201,
             summary="Block a teacher from a specific slot")
def create_availability(
    body:   AvailabilityCreate,
    db:     Session = Depends(get_db),
    _admin: User    = Depends(require_admin),
):
    existing = db.query(TeacherAvailability).filter_by(
        teacher_id=body.teacher_id, slot_id=body.slot_id
    ).first()
    if existing:
        # Update instead of 409
        existing.is_blocked = body.is_blocked
        existing.reason     = body.reason
        db.commit()
        db.refresh(existing)
        return existing
    a = TeacherAvailability(**body.model_dump())
    db.add(a)
    db.commit()
    db.refresh(a)
    return a


@router.delete("/availability/{avail_id}", summary="Remove an availability block")
def delete_availability(
    avail_id: int,
    db:       Session = Depends(get_db),
    _admin:   User    = Depends(require_admin),
):
    a = db.query(TeacherAvailability).filter_by(avail_id=avail_id).first()
    if not a:
        raise HTTPException(404, "Availability record not found")
    db.delete(a)
    db.commit()
    return {"message": f"Availability block {avail_id} removed"}


# ═════════════════════════════════════════════════════════════════════════
# Timetable manual override
# ═════════════════════════════════════════════════════════════════════════

@router.post("/timetable/override", status_code=201,
             summary="Manually assign a single slot in the timetable")
def timetable_override(
    body:   TimetableOverride,
    db:     Session = Depends(get_db),
    _admin: User    = Depends(require_admin),
):
    """
    Inserts or replaces a single timetable entry.
    Enforces the same unique constraints the auto-scheduler uses:
      - section + slot must be free
      - teacher + slot must be free
      - room + slot must be free
    """
    # Check section conflict
    if db.query(Timetable).filter_by(
        section_id=body.section_id, slot_id=body.slot_id
    ).filter(Timetable.semester_id == body.semester_id).first():
        raise HTTPException(409, f"Section {body.section_id} is already busy at slot {body.slot_id}")

    # Check teacher conflict
    if db.query(Timetable).filter_by(
        teacher_id=body.teacher_id, slot_id=body.slot_id
    ).filter(Timetable.semester_id == body.semester_id).first():
        raise HTTPException(409, f"Teacher {body.teacher_id} is already busy at slot {body.slot_id}")

    # Check room conflict
    if db.query(Timetable).filter_by(
        room_id=body.room_id, slot_id=body.slot_id
    ).filter(Timetable.semester_id == body.semester_id).first():
        raise HTTPException(409, f"Room {body.room_id} is already busy at slot {body.slot_id}")

    entry = Timetable(
        semester_id=body.semester_id,
        section_id =body.section_id,
        subject_id =body.subject_id,
        teacher_id =body.teacher_id,
        room_id    =body.room_id,
        slot_id    =body.slot_id,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return {"message": "Slot assigned", "timetable_id": entry.timetable_id}


# ═════════════════════════════════════════════════════════════════════════
# Buildings
# ═════════════════════════════════════════════════════════════════════════

@router.get("/buildings", response_model=List[BuildingOut], summary="List all buildings")
def list_buildings(
    db:      Session = Depends(get_db),
    _admin:  User    = Depends(require_admin),
):
    return db.query(Building).order_by(Building.building_id).all()


@router.post("/buildings", response_model=BuildingOut, status_code=201, summary="Add a new building")
def create_building(
    body:   BuildingCreate,
    db:     Session = Depends(get_db),
    _admin: User    = Depends(require_admin),
):
    if db.query(Building).filter_by(building_id=body.building_id).first():
        raise HTTPException(409, f"Building {body.building_id} already exists")
    b = Building(**body.model_dump())
    db.add(b)
    db.commit()
    db.refresh(b)
    return b


@router.delete("/buildings/{building_id}", summary="Delete a building")
def delete_building(
    building_id: str,
    db:          Session = Depends(get_db),
    _admin:      User    = Depends(require_admin),
):
    b = db.query(Building).filter_by(building_id=building_id).first()
    if not b:
        raise HTTPException(404, "Building not found")
    db.delete(b)
    db.commit()
    return {"message": f"Building {building_id} deleted"}


# ═════════════════════════════════════════════════════════════════════════
# Departments
# ═════════════════════════════════════════════════════════════════════════

@router.get("/departments", response_model=List[DepartmentOut], summary="List all departments")
def list_departments(
    db:      Session = Depends(get_db),
    _admin:  User    = Depends(require_admin),
):
    return db.query(Department).order_by(Department.dept_id).all()


@router.post("/departments", response_model=DepartmentOut, status_code=201, summary="Add a new department")
def create_department(
    body:   DepartmentCreate,
    db:     Session = Depends(get_db),
    _admin: User    = Depends(require_admin),
):
    if db.query(Department).filter_by(dept_id=body.dept_id).first():
        raise HTTPException(409, f"Department {body.dept_id} already exists")
    d = Department(**body.model_dump())
    db.add(d)
    db.commit()
    db.refresh(d)
    return d


@router.delete("/departments/{dept_id}", summary="Delete a department")
def delete_department(
    dept_id: str,
    db:      Session = Depends(get_db),
    _admin:  User    = Depends(require_admin),
):
    d = db.query(Department).filter_by(dept_id=dept_id).first()
    if not d:
        raise HTTPException(404, "Department not found")
    db.delete(d)
    db.commit()
    return {"message": f"Department {dept_id} deleted"}


# ═════════════════════════════════════════════════════════════════════════
# Semesters
# ═════════════════════════════════════════════════════════════════════════

@router.get("/semesters", response_model=List[SemesterOut], summary="List all semesters")
def list_semesters(
    db:      Session = Depends(get_db),
    _admin:  User    = Depends(require_admin),
):
    return db.query(Semester).order_by(Semester.semester_id).all()


@router.post("/semesters", response_model=SemesterOut, status_code=201, summary="Add a new semester")
def create_semester(
    body:   SemesterCreate,
    db:     Session = Depends(get_db),
    _admin: User    = Depends(require_admin),
):
    s = Semester(**body.model_dump())
    db.add(s)
    db.commit()
    db.refresh(s)
    return s


@router.delete("/semesters/{semester_id}", summary="Delete a semester")
def delete_semester(
    semester_id: int,
    db:          Session = Depends(get_db),
    _admin:      User    = Depends(require_admin),
):
    s = db.query(Semester).filter_by(semester_id=semester_id).first()
    if not s:
        raise HTTPException(404, "Semester not found")
    db.delete(s)
    db.commit()
    return {"message": f"Semester {semester_id} deleted"}


# ═════════════════════════════════════════════════════════════════════════
# Time Slots
# ═════════════════════════════════════════════════════════════════════════

@router.get("/timeslots", response_model=List[TimeSlotOut], summary="List all time slots")
def list_timeslots(
    db:      Session = Depends(get_db),
    _admin:  User    = Depends(require_admin),
):
    return db.query(TimeSlot).order_by(TimeSlot.slot_id).all()


@router.post("/timeslots", response_model=TimeSlotOut, status_code=201, summary="Add a new time slot")
def create_timeslot(
    body:   TimeSlotCreate,
    db:     Session = Depends(get_db),
    _admin: User    = Depends(require_admin),
):
    t = TimeSlot(**body.model_dump())
    db.add(t)
    db.commit()
    db.refresh(t)
    return t


@router.delete("/timeslots/{slot_id}", summary="Delete a time slot")
def delete_timeslot(
    slot_id: int,
    db:      Session = Depends(get_db),
    _admin:  User    = Depends(require_admin),
):
    t = db.query(TimeSlot).filter_by(slot_id=slot_id).first()
    if not t:
        raise HTTPException(404, "Time slot not found")
    db.delete(t)
    db.commit()
    return {"message": f"Time slot {slot_id} deleted"}


# ═════════════════════════════════════════════════════════════════════════
# Configuration
# ═════════════════════════════════════════════════════════════════════════

@router.get("/config", response_model=List[ConfigOut], summary="Get scheduler configurations")
def get_config(
    db:      Session = Depends(get_db),
    _admin:  User    = Depends(require_admin),
):
    return db.query(SchedulerConfig).all()


@router.put("/config/{config_id}", response_model=ConfigOut, summary="Update scheduler configuration")
def update_config(
    config_id: int,
    body:      ConfigUpdate,
    db:        Session = Depends(get_db),
    _admin:    User    = Depends(require_admin),
):
    c = db.query(SchedulerConfig).filter_by(config_id=config_id).first()
    if not c:
        raise HTTPException(404, "Config not found")
    for k, v in body.model_dump().items():
        setattr(c, k, v)
    db.commit()
    db.refresh(c)
    return c
