from pydantic import BaseModel
from typing import Optional, List


class ScheduleRequest(BaseModel):
    semester_id:  int
    dept_id:      Optional[str] = None   # None = schedule all departments
    dry_run:      bool = False            # True = validate only, don't save
    max_retries:  int  = 3               # retry greedy solve with different random seeds


class TimetableEntry(BaseModel):
    timetable_id: int
    section_id:   str
    subject_id:   str
    subject_name: str
    teacher_id:   str
    teacher_name: str
    room_id:      str
    day:          str
    start_time:   str
    end_time:     str
    is_lab:       bool

    class Config:
        from_attributes = True


class SectionTimetable(BaseModel):
    section_id: str
    dept_id:    str
    year:       int
    schedule:   List[TimetableEntry]


class TeacherTimetable(BaseModel):
    teacher_id:   str
    teacher_name: str
    dept_id:      str
    schedule:     List[TimetableEntry]


class ScheduleResult(BaseModel):
    status:        str                   # "success" | "infeasible" | "error"
    message:       str
    semester_id:   int
    entries_saved: int
    departments:   List[str]
    warnings:      List[str]


class HealthResponse(BaseModel):
    status:   str
    db:       str
    version:  str
