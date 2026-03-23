"""
Timetable Validation Router
===========================
GET /validate/{semester_id}

Runs 6 checks against the timetables table and returns a full report.
Each check returns: passed (bool), count of violations, and details.

Checks:
  1. No teacher double-booked (same teacher, same slot, 2+ sections)
  2. No room double-booked (same room, same slot, 2+ sections)
  3. No section double-booked (same section, same slot, 2+ subjects)
  4. Weekly hours coverage (every section/subject meets required hours)
  5. Labs are consecutive (lab subject slots must be adjacent pairs)
  6. No classes in break slots
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List
from pydantic import BaseModel

from app.database import get_db

router = APIRouter(prefix="/validate", tags=["Validation"])


# ── Response schemas ───────────────────────────────────────────────────────────

class CheckResult(BaseModel):
    check:      str
    passed:     bool
    violations: int
    details:    List[dict]


class ValidationReport(BaseModel):
    semester_id:   int
    overall:       str        # "PASS" | "FAIL"
    total_checks:  int
    passed:        int
    failed:        int
    checks:        List[CheckResult]


# ── Endpoint ───────────────────────────────────────────────────────────────────

@router.get("/{semester_id}", response_model=ValidationReport,
            summary="Run all validation checks on a scheduled timetable")
def validate_timetable(semester_id: int, db: Session = Depends(get_db)):

    checks: List[CheckResult] = []

    # ── Check 1: No teacher double-booked ─────────────────────────────────────
    rows = db.execute(text("""
        SELECT
            tt.teacher_id,
            tch.teacher_name,
            tt.slot_id,
            ts.day,
            CAST(ts.start_time AS TEXT) AS start_time,
            COUNT(*) AS clash_count,
            STRING_AGG(tt.section_id, ', ') AS sections
        FROM timetables tt
        JOIN teachers   tch ON tch.teacher_id = tt.teacher_id
        JOIN time_slots ts  ON ts.slot_id     = tt.slot_id
        WHERE tt.semester_id = :sid
        GROUP BY tt.teacher_id, tch.teacher_name, tt.slot_id, ts.day, ts.start_time
        HAVING COUNT(*) > 1
        ORDER BY clash_count DESC
    """), {"sid": semester_id}).fetchall()

    checks.append(CheckResult(
        check      = "No teacher double-booked",
        passed     = len(rows) == 0,
        violations = len(rows),
        details    = [
            {
                "teacher_id":   r.teacher_id,
                "teacher_name": r.teacher_name,
                "day":          r.day,
                "start_time":   r.start_time,
                "clash_count":  r.clash_count,
                "sections":     r.sections,
            }
            for r in rows
        ],
    ))

    # ── Check 2: No room double-booked ────────────────────────────────────────
    rows = db.execute(text("""
        SELECT
            tt.room_id,
            tt.slot_id,
            ts.day,
            CAST(ts.start_time AS TEXT) AS start_time,
            COUNT(*) AS clash_count,
            STRING_AGG(tt.section_id, ', ') AS sections
        FROM timetables tt
        JOIN time_slots ts ON ts.slot_id = tt.slot_id
        WHERE tt.semester_id = :sid
        GROUP BY tt.room_id, tt.slot_id, ts.day, ts.start_time
        HAVING COUNT(*) > 1
        ORDER BY clash_count DESC
    """), {"sid": semester_id}).fetchall()

    checks.append(CheckResult(
        check      = "No room double-booked",
        passed     = len(rows) == 0,
        violations = len(rows),
        details    = [
            {
                "room_id":     r.room_id,
                "day":         r.day,
                "start_time":  r.start_time,
                "clash_count": r.clash_count,
                "sections":    r.sections,
            }
            for r in rows
        ],
    ))

    # ── Check 3: No section double-booked ─────────────────────────────────────
    rows = db.execute(text("""
        SELECT
            tt.section_id,
            tt.slot_id,
            ts.day,
            CAST(ts.start_time AS TEXT) AS start_time,
            COUNT(*) AS clash_count,
            STRING_AGG(tt.subject_id, ', ') AS subjects
        FROM timetables tt
        JOIN time_slots ts ON ts.slot_id = tt.slot_id
        WHERE tt.semester_id = :sid
        GROUP BY tt.section_id, tt.slot_id, ts.day, ts.start_time
        HAVING COUNT(*) > 1
        ORDER BY clash_count DESC
    """), {"sid": semester_id}).fetchall()

    checks.append(CheckResult(
        check      = "No section double-booked",
        passed     = len(rows) == 0,
        violations = len(rows),
        details    = [
            {
                "section_id":  r.section_id,
                "day":         r.day,
                "start_time":  r.start_time,
                "clash_count": r.clash_count,
                "subjects":    r.subjects,
            }
            for r in rows
        ],
    ))

    # ── Check 4: Weekly hours coverage ────────────────────────────────────────
    rows = db.execute(text("""
        SELECT
            tt.section_id,
            tt.subject_id,
            sub.subject_name,
            sub.weekly_hours AS required,
            COUNT(*) AS scheduled
        FROM timetables tt
        JOIN subjects sub ON sub.subject_id = tt.subject_id
        JOIN sections sec ON sec.section_id = tt.section_id
        WHERE tt.semester_id = :sid
          AND sub.dept_id = sec.dept_id
        GROUP BY tt.section_id, tt.subject_id, sub.subject_name, sub.weekly_hours
        HAVING COUNT(*) != sub.weekly_hours
        ORDER BY tt.section_id, tt.subject_id
    """), {"sid": semester_id}).fetchall()

    checks.append(CheckResult(
        check      = "Weekly hours fully scheduled",
        passed     = len(rows) == 0,
        violations = len(rows),
        details    = [
            {
                "section_id":   r.section_id,
                "subject_id":   r.subject_id,
                "subject_name": r.subject_name,
                "required":     r.required,
                "scheduled":    r.scheduled,
                "missing":      r.required - r.scheduled,
            }
            for r in rows
        ],
    ))

    # ── Check 5: Lab slots are consecutive ────────────────────────────────────
    rows = db.execute(text("""
        WITH lab_slots AS (
            SELECT
                tt.section_id,
                tt.subject_id,
                sub.subject_name,
                ts.day,
                ts.slot_id,
                LAG(ts.slot_id) OVER (
                    PARTITION BY tt.section_id, tt.subject_id, ts.day
                    ORDER BY ts.slot_id
                ) AS prev_slot_id
            FROM timetables tt
            JOIN subjects   sub ON sub.subject_id = tt.subject_id
            JOIN time_slots ts  ON ts.slot_id     = tt.slot_id
            WHERE tt.semester_id = :sid
              AND sub.is_lab = TRUE
        )
        SELECT
            section_id,
            subject_id,
            subject_name,
            day,
            slot_id,
            prev_slot_id
        FROM lab_slots
        WHERE prev_slot_id IS NOT NULL
          AND slot_id != prev_slot_id + 1
        ORDER BY section_id, subject_id
    """), {"sid": semester_id}).fetchall()

    checks.append(CheckResult(
        check      = "Lab slots are consecutive",
        passed     = len(rows) == 0,
        violations = len(rows),
        details    = [
            {
                "section_id":   r.section_id,
                "subject_id":   r.subject_id,
                "subject_name": r.subject_name,
                "day":          r.day,
                "slot_id":      r.slot_id,
                "prev_slot_id": r.prev_slot_id,
            }
            for r in rows
        ],
    ))

    # ── Check 6: No classes in break slots ────────────────────────────────────
    rows = db.execute(text("""
        SELECT
            tt.section_id,
            tt.subject_id,
            tt.slot_id,
            ts.day,
            CAST(ts.start_time AS TEXT) AS start_time
        FROM timetables tt
        JOIN time_slots ts ON ts.slot_id = tt.slot_id
        WHERE tt.semester_id = :sid
          AND ts.is_break = TRUE
        ORDER BY tt.section_id
    """), {"sid": semester_id}).fetchall()

    checks.append(CheckResult(
        check      = "No classes in break slots",
        passed     = len(rows) == 0,
        violations = len(rows),
        details    = [
            {
                "section_id": r.section_id,
                "subject_id": r.subject_id,
                "day":        r.day,
                "start_time": r.start_time,
            }
            for r in rows
        ],
    ))

    # ── Summary ────────────────────────────────────────────────────────────────
    passed_count = sum(1 for c in checks if c.passed)
    failed_count = len(checks) - passed_count

    return ValidationReport(
        semester_id  = semester_id,
        overall      = "PASS" if failed_count == 0 else "FAIL",
        total_checks = len(checks),
        passed       = passed_count,
        failed       = failed_count,
        checks       = checks,
    )