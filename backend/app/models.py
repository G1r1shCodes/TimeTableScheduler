from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, UniqueConstraint, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base


class Building(Base):
    __tablename__ = "buildings"
    building_id   = Column(String, primary_key=True)
    building_name = Column(String, nullable=False)


class Department(Base):
    __tablename__ = "departments"
    dept_id   = Column(String, primary_key=True)
    dept_name = Column(String, nullable=False)


class Semester(Base):
    __tablename__ = "semesters"
    semester_id   = Column(Integer, primary_key=True, autoincrement=True)
    academic_year = Column(String, nullable=False)
    semester      = Column(Integer, nullable=False)
    is_active     = Column(Boolean, default=False)


class Room(Base):
    __tablename__ = "rooms"
    room_id     = Column(String, primary_key=True)
    building_id = Column(String, ForeignKey("buildings.building_id"), nullable=False)
    room_type   = Column(String, nullable=False)
    capacity    = Column(Integer, nullable=False)
    floor       = Column(Integer, default=0)
    is_active   = Column(Boolean, default=True)


class TimeSlot(Base):
    __tablename__ = "time_slots"
    slot_id    = Column(Integer, primary_key=True, autoincrement=True)
    day        = Column(String, nullable=False)
    start_time = Column(String, nullable=False)
    end_time   = Column(String, nullable=False)
    is_break   = Column(Boolean, default=False)


class Teacher(Base):
    __tablename__ = "teachers"
    teacher_id         = Column(String, primary_key=True)
    teacher_name       = Column(String, nullable=False)
    dept_id            = Column(String, ForeignKey("departments.dept_id"), nullable=False)
    preferred_building = Column(String, ForeignKey("buildings.building_id"))
    max_hours_per_day  = Column(Integer, default=6)
    email              = Column(String)
    phone              = Column(String)
    is_active          = Column(Boolean, default=True)


class Section(Base):
    __tablename__ = "sections"
    section_id     = Column(String, primary_key=True)
    year           = Column(Integer, nullable=False)
    dept_id        = Column(String, ForeignKey("departments.dept_id"), nullable=False)
    total_students = Column(Integer, nullable=False)


class Subject(Base):
    __tablename__ = "subjects"
    subject_id   = Column(String, primary_key=True)
    subject_name = Column(String, nullable=False)
    dept_id      = Column(String, ForeignKey("departments.dept_id"), nullable=False)
    weekly_hours = Column(Integer, nullable=False)
    is_lab       = Column(Boolean, default=False)
    slot_count   = Column(Integer, default=1)


class SubjectTeacherMapping(Base):
    __tablename__ = "subject_teacher_mapping"
    mapping_id = Column(Integer, primary_key=True, autoincrement=True)
    subject_id = Column(String, ForeignKey("subjects.subject_id"), nullable=False)
    teacher_id = Column(String, ForeignKey("teachers.teacher_id"), nullable=False)
    __table_args__ = (UniqueConstraint("subject_id", "teacher_id"),)


class SchedulerConfig(Base):
    __tablename__ = "scheduler_config"
    config_id              = Column(Integer, primary_key=True)
    max_continuous_classes = Column(Integer, default=3)
    mandatory_break        = Column(Boolean, default=True)
    max_hours_per_day      = Column(Integer, default=6)
    same_building_pref     = Column(Boolean, default=True)


class Timetable(Base):
    __tablename__ = "timetables"
    timetable_id = Column(Integer, primary_key=True, autoincrement=True)
    semester_id  = Column(Integer, ForeignKey("semesters.semester_id"), nullable=False)
    section_id   = Column(String, ForeignKey("sections.section_id"), nullable=False)
    subject_id   = Column(String, ForeignKey("subjects.subject_id"), nullable=False)
    teacher_id   = Column(String, ForeignKey("teachers.teacher_id"), nullable=False)
    room_id      = Column(String, ForeignKey("rooms.room_id"), nullable=False)
    slot_id      = Column(Integer, ForeignKey("time_slots.slot_id"), nullable=False)
    __table_args__ = (
        UniqueConstraint("section_id", "slot_id"),
        UniqueConstraint("teacher_id", "slot_id"),
        UniqueConstraint("room_id",    "slot_id"),
    )


class TeacherAvailability(Base):
    """
    Blocks a teacher from being scheduled in specific slots.
    Populated by admins for sick days, off-campus commitments, etc.
    The scheduler pre-loads this table and treats blocked slots as
    hard unavailability constraints.
    """
    __tablename__ = "teacher_availability"
    avail_id   = Column(Integer, primary_key=True, autoincrement=True)
    teacher_id = Column(String, ForeignKey("teachers.teacher_id"), nullable=False)
    slot_id    = Column(Integer, ForeignKey("time_slots.slot_id"),  nullable=False)
    is_blocked = Column(Boolean, default=True, nullable=False)
    reason     = Column(String)
    __table_args__ = (UniqueConstraint("teacher_id", "slot_id"),)


class User(Base):
    """
    Application users with role-based access.
    role: 'admin' | 'teacher' | 'student'
    linked_id: teacher_id or section_id depending on role (None for admin).
    """
    __tablename__ = "users"
    user_id          = Column(Integer, primary_key=True, autoincrement=True)
    username         = Column(String, unique=True, nullable=False)
    hashed_password  = Column(String, nullable=False)
    role             = Column(String, nullable=False)   # admin | teacher | student
    linked_id        = Column(String)                   # optional FK to teacher/section
    is_active        = Column(Boolean, default=True)
    created_at       = Column(DateTime(timezone=True), server_default=func.now())
