from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Optional

from app.database import get_db
from app.schemas import TimetableEntry, SectionTimetable, TeacherTimetable

router = APIRouter(prefix="/timetable", tags=["Timetable"])

# ── Shared query ───────────────────────────────────────────────────────────────

BASE_QUERY = """
    SELECT
        tt.timetable_id,
        tt.section_id,
        tt.subject_id,
        sub.subject_name,
        tt.teacher_id,
        tch.teacher_name,
        tt.room_id,
        ts.day,
        CAST(ts.start_time AS TEXT) AS start_time,
        CAST(ts.end_time   AS TEXT) AS end_time,
        sub.is_lab
    FROM timetables tt
    JOIN subjects   sub ON sub.subject_id  = tt.subject_id
    JOIN teachers   tch ON tch.teacher_id  = tt.teacher_id
    JOIN time_slots ts  ON ts.slot_id      = tt.slot_id
    WHERE tt.semester_id = :semester_id
"""

DAY_ORDER = ['Mon','Tue','Wed','Thu','Fri','Sat']

def _sort_key(entry: TimetableEntry):
    return (DAY_ORDER.index(entry.day) if entry.day in DAY_ORDER else 99, entry.start_time)

def _row_to_entry(row) -> TimetableEntry:
    return TimetableEntry(
        timetable_id = row.timetable_id,
        section_id   = row.section_id,
        subject_id   = row.subject_id,
        subject_name = row.subject_name,
        teacher_id   = row.teacher_id,
        teacher_name = row.teacher_name,
        room_id      = row.room_id,
        day          = row.day,
        start_time   = row.start_time,
        end_time     = row.end_time,
        is_lab       = row.is_lab,
    )


# ── Endpoints ──────────────────────────────────────────────────────────────────

@router.get(
    "/section/{section_id}",
    response_model=SectionTimetable,
    summary="Get full weekly timetable for a section",
)
def get_section_timetable(
    section_id:  str,
    semester_id: int = Query(..., description="Semester ID"),
    db: Session = Depends(get_db),
):
    from app.models import Section
    sec = db.query(Section).filter_by(section_id=section_id).first()
    if not sec:
        raise HTTPException(status_code=404, detail=f"Section {section_id} not found")

    rows = db.execute(
        text(BASE_QUERY + " AND tt.section_id = :section_id ORDER BY ts.day, ts.start_time"),
        {"semester_id": semester_id, "section_id": section_id}
    ).fetchall()

    entries = sorted([_row_to_entry(r) for r in rows], key=_sort_key)
    return SectionTimetable(
        section_id = sec.section_id,
        dept_id    = sec.dept_id,
        year       = sec.year,
        schedule   = entries,
    )


@router.get(
    "/teacher/{teacher_id}",
    response_model=TeacherTimetable,
    summary="Get full weekly timetable for a teacher",
)
def get_teacher_timetable(
    teacher_id:  str,
    semester_id: int = Query(..., description="Semester ID"),
    db: Session = Depends(get_db),
):
    from app.models import Teacher
    tch = db.query(Teacher).filter_by(teacher_id=teacher_id).first()
    if not tch:
        raise HTTPException(status_code=404, detail=f"Teacher {teacher_id} not found")

    rows = db.execute(
        text(BASE_QUERY + " AND tt.teacher_id = :teacher_id ORDER BY ts.day, ts.start_time"),
        {"semester_id": semester_id, "teacher_id": teacher_id}
    ).fetchall()

    entries = sorted([_row_to_entry(r) for r in rows], key=_sort_key)
    return TeacherTimetable(
        teacher_id   = tch.teacher_id,
        teacher_name = tch.teacher_name,
        dept_id      = tch.dept_id,
        schedule     = entries,
    )


@router.get(
    "/department/{dept_id}",
    response_model=List[SectionTimetable],
    summary="Get timetables for all sections in a department",
)
def get_department_timetable(
    dept_id:     str,
    semester_id: int = Query(..., description="Semester ID"),
    db: Session = Depends(get_db),
):
    from app.models import Section
    sections = db.query(Section).filter_by(dept_id=dept_id).all()
    if not sections:
        raise HTTPException(status_code=404, detail=f"No sections found for dept {dept_id}")

    result = []
    for sec in sections:
        rows = db.execute(
            text(BASE_QUERY + " AND tt.section_id = :section_id ORDER BY ts.day, ts.start_time"),
            {"semester_id": semester_id, "section_id": sec.section_id}
        ).fetchall()
        entries = sorted([_row_to_entry(r) for r in rows], key=_sort_key)
        result.append(SectionTimetable(
            section_id = sec.section_id,
            dept_id    = sec.dept_id,
            year       = sec.year,
            schedule   = entries,
        ))
    return result


@router.get(
    "/room/{room_id}",
    summary="Get room occupancy for the week",
)
def get_room_timetable(
    room_id:     str,
    semester_id: int = Query(..., description="Semester ID"),
    db: Session = Depends(get_db),
):
    rows = db.execute(
        text(BASE_QUERY + " AND tt.room_id = :room_id ORDER BY ts.day, ts.start_time"),
        {"semester_id": semester_id, "room_id": room_id}
    ).fetchall()
    return [_row_to_entry(r) for r in rows]


@router.get(
    "/summary/{semester_id}",
    summary="High-level stats for the dashboard overview",
)
def get_summary(semester_id: int, db: Session = Depends(get_db)):
    stats = db.execute(text("""
        SELECT
            COUNT(*)                                      AS total_classes,
            COUNT(DISTINCT tt.section_id)                 AS sections_scheduled,
            COUNT(DISTINCT tt.teacher_id)                 AS teachers_busy,
            COUNT(DISTINCT tt.room_id)                    AS rooms_used,
            COUNT(DISTINCT d.dept_id)                     AS departments,
            SUM(CASE WHEN sub.is_lab THEN 1 ELSE 0 END)  AS lab_classes
        FROM timetables tt
        JOIN subjects sub ON sub.subject_id = tt.subject_id
        JOIN sections sec ON sec.section_id = tt.section_id
        JOIN departments d ON d.dept_id = sec.dept_id
        WHERE tt.semester_id = :sid
    """), {"sid": semester_id}).fetchone()

    return {
        "semester_id":        semester_id,
        "total_classes":      stats.total_classes,
        "sections_scheduled": stats.sections_scheduled,
        "teachers_busy":      stats.teachers_busy,
        "rooms_used":         stats.rooms_used,
        "departments":        stats.departments,
        "lab_classes":        stats.lab_classes,
    }
