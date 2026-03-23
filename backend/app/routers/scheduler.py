"""
app/routers/scheduler.py
========================
Scheduler router with:
 - max_retries: retry greedy solve with different random seeds
 - Break on first non-empty result (good enough)
 - Fallback to solve_relaxed() if all retries fail (always returns something)
 - Never raises HTTP errors on empty — always returns a response
"""
import logging
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Semester, Department, Timetable
from app.schemas import ScheduleRequest, ScheduleResult
from app.scheduler import TimetableScheduler

router = APIRouter(prefix="/schedule", tags=["Scheduler"])
logger = logging.getLogger(__name__)


@router.post("/generate", response_model=ScheduleResult, summary="Generate timetable")
def generate_timetable(
    body: ScheduleRequest,
    db: Session = Depends(get_db),
):
    semester = db.query(Semester).filter_by(semester_id=body.semester_id).first()
    if not semester:
        # Return a graceful error response instead of raising
        return ScheduleResult(
            status="error",
            message=f"Semester {body.semester_id} not found",
            semester_id=body.semester_id,
            entries_saved=0,
            departments=[],
            warnings=[f"Semester {body.semester_id} not found"],
        )

    dept_ids = ([body.dept_id] if body.dept_id
                else [d.dept_id for d in db.query(Department).all()])

    all_assignments = []
    all_warnings:   list = []
    final_status    = "success"

    # ── Retry loop (each attempt uses fresh random shuffle) ─────────────
    for attempt in range(max(1, body.max_retries)):
        attempt_assignments = []
        attempt_warnings:   list = []

        shared_teacher_busy: dict = {}
        shared_room_busy:    dict = {}

        for dept_id in dept_ids:
            logger.info(f"[attempt {attempt+1}] Scheduling dept: {dept_id}")
            scheduler = TimetableScheduler(
                db=db, semester_id=body.semester_id, dept_id=dept_id
            )
            try:
                status, assignments = scheduler.solve(
                    teacher_busy=shared_teacher_busy,
                    room_busy=shared_room_busy,
                )
            except Exception as e:
                logger.exception(f"Crashed for dept {dept_id}")
                attempt_warnings.append(f"Dept {dept_id} failed: {str(e)}")
                continue

            attempt_assignments.extend(assignments)
            attempt_warnings.extend(scheduler.warnings)

        # Break as soon as we get a non-empty schedule
        if attempt_assignments:
            all_assignments = attempt_assignments
            all_warnings    = attempt_warnings
            logger.info(f"Accepted attempt {attempt+1}: {len(all_assignments)} classes")
            break

        logger.warning(f"Attempt {attempt+1} produced 0 assignments — retrying")

    # ── Hard-constraint fallback if all retries failed ───────────────────
    if not all_assignments:
        logger.warning("All retries failed — running relaxed fallback scheduler")
        final_status = "partial"
        all_warnings.append("Greedy retries failed; using hard-constraint-only fallback")

        fallback_teacher_busy: dict = {}
        fallback_room_busy:    dict = {}

        for dept_id in dept_ids:
            scheduler = TimetableScheduler(
                db=db, semester_id=body.semester_id, dept_id=dept_id
            )
            try:
                _, assignments = scheduler.solve_relaxed(
                    teacher_busy=fallback_teacher_busy,
                    room_busy=fallback_room_busy,
                )
                all_assignments.extend(assignments)
                all_warnings.extend(scheduler.warnings)
            except Exception as e:
                all_warnings.append(f"Fallback crashed for dept {dept_id}: {str(e)}")

    # ── Determine message ────────────────────────────────────────────────
    if not all_assignments:
        # Absolute worst case — data issue (no teachers/rooms/slots in DB)
        message = "No schedule could be generated. Please check your data (teachers, rooms, subjects, mappings)."
        final_status = "error"
    elif final_status == "partial":
        message = "Partial schedule generated (fallback mode — soft constraints relaxed)."
    else:
        message = f"Schedule generated successfully: {len(all_assignments)} classes across {len(dept_ids)} department(s)."

    # ── Save (if not dry run) ────────────────────────────────────────────
    saved = 0
    if not body.dry_run and all_assignments:
        db.query(Timetable).filter_by(semester_id=body.semester_id).delete()
        db.flush()
        rows = [
            Timetable(
                semester_id=body.semester_id,
                section_id=a.section_id,
                subject_id=a.subject_id,
                teacher_id=a.teacher_id,
                room_id=a.room_id,
                slot_id=a.slot_id,
            )
            for a in all_assignments
        ]
        db.bulk_save_objects(rows)
        db.commit()
        saved = len(rows)

    return ScheduleResult(
        status=final_status if not body.dry_run else "dry_run",
        message=message,
        semester_id=body.semester_id,
        entries_saved=saved,
        departments=dept_ids,
        warnings=all_warnings,
    )


@router.delete("/clear/{semester_id}", summary="Clear timetable for a semester")
def clear_timetable(semester_id: int, db: Session = Depends(get_db)):
    deleted = db.query(Timetable).filter_by(semester_id=semester_id).delete()
    db.commit()
    return {"deleted": deleted, "semester_id": semester_id}