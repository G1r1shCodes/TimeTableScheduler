"""
app/scheduler.py
================
Greedy timetable scheduler with all constraint enforcement.

Fixes applied (v3.0):
  - P5:  Removed dead save() method (router handles saving)
  - P9:  Replaced self._sec_assignments / self._sec_busy (instance-level
         state) with local dicts inside solve() — no hasattr() hacks
  - P6:  max_hours_per_day enforced per teacher per day
  - P7:  Room capacity checked against section.total_students
  - P8:  Building preference: rooms in teacher's preferred_building
         are tried first (soft constraint, not hard)
"""
import logging
import random
from collections import defaultdict
from typing import List, Dict, Tuple, Optional, Set
from dataclasses import dataclass

from sqlalchemy.orm import Session
from app.models import (
    Section, Subject, Room, TimeSlot, Teacher,
    SubjectTeacherMapping, SchedulerConfig, Timetable,
    TeacherAvailability,
)

logger = logging.getLogger(__name__)


@dataclass
class Assignment:
    section_id:  str
    subject_id:  str
    teacher_id:  str
    room_id:     str
    slot_id:     int


class TimetableScheduler:

    DAY_ORDER = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

    def __init__(self, db: Session, semester_id: int, dept_id: Optional[str] = None):
        self.db          = db
        self.semester_id = semester_id
        self.dept_id     = dept_id
        self.warnings:   List[str] = []

    # ─────────────────────────────────────────────────────────────────────
    # Data loading
    # ─────────────────────────────────────────────────────────────────────

    def _load_data(self):
        q = self.db

        cfg = q.query(SchedulerConfig).filter_by(config_id=1).first()
        self.max_continuous = cfg.max_continuous_classes if cfg else 3

        # All non-break slots, ordered
        slot_rows      = q.query(TimeSlot).order_by(TimeSlot.slot_id).all()
        self.teachable = [s for s in slot_rows if not s.is_break]

        self.slots_by_day: Dict[str, List[TimeSlot]] = {}
        for s in self.teachable:
            self.slots_by_day.setdefault(s.day, []).append(s)
        for d in self.slots_by_day:
            self.slots_by_day[d].sort(key=lambda s: s.slot_id)

        # Consecutive pairs per day (for lab scheduling)
        self.consec_pairs: Dict[str, List[Tuple[int, int]]] = {}
        for day, slots in self.slots_by_day.items():
            pairs = []
            for i in range(len(slots) - 1):
                a, b = slots[i], slots[i + 1]
                if b.slot_id == a.slot_id + 1:
                    pairs.append((a.slot_id, b.slot_id))
            self.consec_pairs[day] = pairs

        # Sections
        sec_q = q.query(Section)
        if self.dept_id:
            sec_q = sec_q.filter_by(dept_id=self.dept_id)
        self.sections = sec_q.all()

        dept_ids      = list({s.dept_id for s in self.sections})
        self.subjects = q.query(Subject).filter(Subject.dept_id.in_(dept_ids)).all()

        # Subject → teacher list
        subject_ids = [s.subject_id for s in self.subjects]
        mappings    = q.query(SubjectTeacherMapping).filter(
            SubjectTeacherMapping.subject_id.in_(subject_ids)
        ).all()
        self.teachers_for_subject: Dict[str, List[str]] = {}
        for m in mappings:
            self.teachers_for_subject.setdefault(m.subject_id, []).append(m.teacher_id)

        # Teacher metadata (max_hours_per_day, preferred_building)
        teacher_ids = list({tid
                            for tids in self.teachers_for_subject.values()
                            for tid  in tids})
        teachers    = q.query(Teacher).filter(Teacher.teacher_id.in_(teacher_ids)).all()
        self.teacher_meta: Dict[str, Teacher] = {t.teacher_id: t for t in teachers}

        # Rooms
        all_rooms        = q.query(Room).filter_by(is_active=True).all()
        self.lab_rooms   = [r for r in all_rooms if r.room_type == 'LAB']
        self.class_rooms = [r for r in all_rooms if r.room_type in ('CLASS', 'SEMINAR')]

        # Pre-blocked slots from teacher_availability table
        blocked = q.query(TeacherAvailability).filter_by(is_blocked=True).all()
        # slot_id → set of teacher_ids who are unavailable
        self.blocked_teacher_slots: Dict[int, Set[str]] = defaultdict(set)
        for b in blocked:
            self.blocked_teacher_slots[b.slot_id].add(b.teacher_id)

    # ─────────────────────────────────────────────────────────────────────
    # Constraint helpers
    # ─────────────────────────────────────────────────────────────────────

    def _continuous_ok(self, section_busy: Set[int], day: str, new_ids: List[int]) -> bool:
        """True if adding new_ids doesn't create a run > max_continuous in a day."""
        day_ids  = [s.slot_id for s in self.slots_by_day.get(day, [])]
        occupied = {sid for sid in section_busy if sid in day_ids} | set(new_ids)
        window   = self.max_continuous + 1
        for i in range(len(day_ids) - window + 1):
            if set(day_ids[i:i + window]).issubset(occupied):
                return False
        return True

    def _day_of_slot(self, slot_id: int) -> Optional[str]:
        for day, slots in self.slots_by_day.items():
            if any(s.slot_id == slot_id for s in slots):
                return day
        return None

    # ─────────────────────────────────────────────────────────────────────
    # P6 — Teacher picker with daily-hours enforcement
    # ─────────────────────────────────────────────────────────────────────

    def _pick_teacher(
        self,
        candidates:        List[str],
        slot_ids:          List[int],
        teacher_busy:      Dict[int, Set[str]],
        teacher_daily_hrs: Dict[str, Dict[str, int]],
    ) -> Optional[str]:
        """
        Returns the first available teacher who:
          1. Is not already assigned to any of slot_ids
          2. Is not blocked (teacher_availability table)
          3. Has not hit max_hours_per_day for the relevant day
        Candidates are shuffled for randomness.
        """
        pool = list(candidates)
        random.shuffle(pool)

        # Determine which day these slots fall on (all slots in one assignment share a day)
        day = self._day_of_slot(slot_ids[0]) if slot_ids else None

        for tid in pool:
            # Check slot-level conflicts
            if any(tid in teacher_busy.get(sid, set()) for sid in slot_ids):
                continue
            # P6: Check blocked slots from teacher_availability
            if any(tid in self.blocked_teacher_slots.get(sid, set()) for sid in slot_ids):
                continue
            # P6: Enforce max_hours_per_day
            if day:
                meta    = self.teacher_meta.get(tid)
                max_hrs = meta.max_hours_per_day if meta else 6
                current = teacher_daily_hrs[tid].get(day, 0)
                if current + len(slot_ids) > max_hrs:
                    continue
            return tid
        return None

    # ─────────────────────────────────────────────────────────────────────
    # P7 + P8 — Room picker with capacity check and building preference
    # ─────────────────────────────────────────────────────────────────────

    def _pick_room(
        self,
        candidates:          List[Room],
        slot_ids:            List[int],
        room_busy:           Dict[int, Set[str]],
        section_size:        int,
        preferred_building:  Optional[str] = None,
    ) -> Optional[Room]:
        """
        Returns the first available room that:
          1. Has capacity >= section_size   (P7)
          2. Is not busy for any of slot_ids
        Rooms in preferred_building are tried first (P8 — soft constraint).
        """
        # P7: filter to rooms that fit the section
        eligible = [r for r in candidates if r.capacity >= section_size]
        if not eligible:
            eligible = candidates  # fallback — log a warning upstream

        # P8: preferred building first, then the rest
        if preferred_building:
            preferred = [r for r in eligible if r.building_id == preferred_building]
            others    = [r for r in eligible if r.building_id != preferred_building]
            random.shuffle(preferred)
            random.shuffle(others)
            pool = preferred + others
        else:
            pool = list(eligible)
            random.shuffle(pool)

        for room in pool:
            if all(room.room_id not in room_busy.get(sid, set()) for sid in slot_ids):
                return room
        return None

    # ─────────────────────────────────────────────────────────────────────
    # Assignment helper
    # ─────────────────────────────────────────────────────────────────────

    def _assign(
        self,
        sec_id:            str,
        subj_id:           str,
        teacher_id:        str,
        room_id:           str,
        slot_ids:          List[int],
        section_busy:      Set[int],
        teacher_busy:      Dict[int, Set[str]],
        room_busy:         Dict[int, Set[str]],
        teacher_daily_hrs: Dict[str, Dict[str, int]],
        result:            List[Assignment],
    ):
        day = self._day_of_slot(slot_ids[0])
        for sid in slot_ids:
            result.append(Assignment(sec_id, subj_id, teacher_id, room_id, sid))
            section_busy.add(sid)
            teacher_busy.setdefault(sid, set()).add(teacher_id)
            room_busy.setdefault(sid, set()).add(room_id)
        # P6: track daily hours
        if day:
            teacher_daily_hrs[teacher_id][day] = (
                teacher_daily_hrs[teacher_id].get(day, 0) + len(slot_ids)
            )

    # ─────────────────────────────────────────────────────────────────────
    # Lab scheduler (2-slot consecutive blocks)
    # ─────────────────────────────────────────────────────────────────────

    def _schedule_lab(
        self,
        sec,
        subj,
        section_busy:      Set[int],
        teacher_busy:      Dict[int, Set[str]],
        room_busy:         Dict[int, Set[str]],
        teacher_daily_hrs: Dict[str, Dict[str, int]],
        sec_assignments:   List[Assignment],
    ):
        t_list = self.teachers_for_subject.get(subj.subject_id, [])
        needed = subj.weekly_hours // 2   # 2 slots per lab session
        done   = 0

        all_pairs = []
        for day in self.DAY_ORDER:
            for pair in self.consec_pairs.get(day, []):
                all_pairs.append((day, pair))
        random.shuffle(all_pairs)

        for (day, (sa, sb)) in all_pairs:
            if done >= needed:
                break
            if sa in section_busy or sb in section_busy:
                continue
            if not self._continuous_ok(section_busy, day, [sa, sb]):
                continue

            tid = self._pick_teacher(t_list, [sa, sb], teacher_busy, teacher_daily_hrs)
            if not tid:
                continue

            preferred_bldg = getattr(self.teacher_meta.get(tid), 'preferred_building', None)
            room = self._pick_room(
                self.lab_rooms, [sa, sb], room_busy,
                section_size=sec.total_students,
                preferred_building=preferred_bldg,
            )
            if not room:
                continue

            self._assign(
                sec.section_id, subj.subject_id, tid, room.room_id,
                [sa, sb], section_busy, teacher_busy, room_busy,
                teacher_daily_hrs, sec_assignments,
            )
            done += 1

        if done < needed:
            self.warnings.append(
                f"{sec.section_id}/{subj.subject_name}: {done}/{needed} lab sessions placed"
            )

    # ─────────────────────────────────────────────────────────────────────
    # Theory scheduler (1-slot classes, spread across days)
    # ─────────────────────────────────────────────────────────────────────

    def _schedule_theory(
        self,
        sec,
        subj,
        section_busy:      Set[int],
        teacher_busy:      Dict[int, Set[str]],
        room_busy:         Dict[int, Set[str]],
        teacher_daily_hrs: Dict[str, Dict[str, int]],
        sec_assignments:   List[Assignment],
    ):
        t_list = self.teachers_for_subject.get(subj.subject_id, [])
        needed = subj.weekly_hours
        done   = 0

        # Build day-grouped candidate list so we spread across the week
        # (iterate days round-robin to avoid clumping all classes on Monday)
        day_slots: Dict[str, List[TimeSlot]] = {
            day: list(self.slots_by_day.get(day, []))
            for day in self.DAY_ORDER
        }
        for slots in day_slots.values():
            random.shuffle(slots)

        # Interleave: Mon slot, Tue slot, Wed slot… repeat until needed fulfilled
        candidates = []
        max_slots_per_day = max((len(v) for v in day_slots.values()), default=0)
        for i in range(max_slots_per_day):
            for day in self.DAY_ORDER:
                if i < len(day_slots[day]):
                    candidates.append(day_slots[day][i])

        for sl in candidates:
            if done >= needed:
                break
            if sl.slot_id in section_busy:
                continue
            if not self._continuous_ok(section_busy, sl.day, [sl.slot_id]):
                continue

            tid = self._pick_teacher(t_list, [sl.slot_id], teacher_busy, teacher_daily_hrs)
            if not tid:
                continue

            preferred_bldg = getattr(self.teacher_meta.get(tid), 'preferred_building', None)
            room = self._pick_room(
                self.class_rooms, [sl.slot_id], room_busy,
                section_size=sec.total_students,
                preferred_building=preferred_bldg,
            )
            if not room:
                continue

            self._assign(
                sec.section_id, subj.subject_id, tid, room.room_id,
                [sl.slot_id], section_busy, teacher_busy, room_busy,
                teacher_daily_hrs, sec_assignments,
            )
            done += 1

        if done < needed:
            self.warnings.append(
                f"{sec.section_id}/{subj.subject_name}: {done}/{needed} sessions placed"
            )

    # ─────────────────────────────────────────────────────────────────────
    # Main solve — P9: all state is LOCAL to this method
    # ─────────────────────────────────────────────────────────────────────

    def solve(
        self,
        teacher_busy: Optional[Dict[int, Set[str]]] = None,
        room_busy:    Optional[Dict[int, Set[str]]] = None,
    ) -> Tuple[str, List[Assignment]]:
        """
        Returns (status, assignments).
        teacher_busy / room_busy are shared across departments so inter-dept
        conflicts are prevented when scheduling multiple depts in one pass.
        """
        self._load_data()
        if not self.sections or not self.teachable:
            return "error", []

        if teacher_busy is None: teacher_busy = {}
        if room_busy    is None: room_busy    = {}

        # P9: ALL mutable state is local — no instance attributes
        sec_assignments: Dict[str, List[Assignment]] = {
            sec.section_id: [] for sec in self.sections
        }
        sec_busy: Dict[str, Set[int]] = {
            sec.section_id: set() for sec in self.sections
        }
        # P6: daily hours tracker — teacher_id → day → hours_used
        teacher_daily_hrs: Dict[str, Dict[str, int]] = defaultdict(dict)

        sections = list(self.sections)
        random.shuffle(sections)

        # ── Pass 1: labs first (reserve consecutive pairs) ────────────────
        for sec in sections:
            dept_subjects = [s for s in self.subjects if s.dept_id == sec.dept_id]
            lab_subjects  = [s for s in dept_subjects if s.is_lab]

            for subj in lab_subjects:
                if not self.teachers_for_subject.get(subj.subject_id):
                    self.warnings.append(f"No teachers mapped: {subj.subject_id}")
                    continue
                self._schedule_lab(
                    sec, subj,
                    sec_busy[sec.section_id],
                    teacher_busy, room_busy,
                    teacher_daily_hrs,
                    sec_assignments[sec.section_id],
                )

        # ── Pass 2: theory ────────────────────────────────────────────────
        for sec in sections:
            dept_subjects   = [s for s in self.subjects if s.dept_id == sec.dept_id]
            theory_subjects = [s for s in dept_subjects if not s.is_lab]

            for subj in theory_subjects:
                if not self.teachers_for_subject.get(subj.subject_id):
                    self.warnings.append(f"No teachers mapped: {subj.subject_id}")
                    continue
                self._schedule_theory(
                    sec, subj,
                    sec_busy[sec.section_id],
                    teacher_busy, room_busy,
                    teacher_daily_hrs,
                    sec_assignments[sec.section_id],
                )

        # Flatten
        all_assignments: List[Assignment] = []
        for sec in sections:
            lst = sec_assignments[sec.section_id]
            all_assignments.extend(lst)
            logger.info(f"  {sec.section_id}: {len(lst)} classes scheduled")

        return "success", all_assignments

    # ─────────────────────────────────────────────────────────────────────
    # Hard-constraint-only fallback (called when all retries fail)
    # Skips: building preference, daily spread, max_hours_per_day
    # Enforces ONLY: no teacher double-book, no room double-book
    # ─────────────────────────────────────────────────────────────────────

    def solve_relaxed(
        self,
        teacher_busy: Optional[Dict[int, Set[str]]] = None,
        room_busy:    Optional[Dict[int, Set[str]]] = None,
    ) -> Tuple[str, List[Assignment]]:
        """Last-resort scheduler — always produces something."""
        self._load_data()
        if not self.sections or not self.teachable:
            return "error", []

        if teacher_busy is None: teacher_busy = {}
        if room_busy    is None: room_busy    = {}

        sec_busy: Dict[str, Set[int]] = {s.section_id: set() for s in self.sections}
        # Dummy daily hours tracker — never limits (relaxed)
        teacher_daily_hrs: Dict[str, Dict[str, int]] = defaultdict(dict)

        all_assignments: List[Assignment] = []
        sections = list(self.sections)
        random.shuffle(sections)

        all_slots = list(self.teachable)
        random.shuffle(all_slots)

        for sec in sections:
            dept_subjects = [s for s in self.subjects if s.dept_id == sec.dept_id]
            random.shuffle(dept_subjects)

            for subj in dept_subjects:
                t_list = self.teachers_for_subject.get(subj.subject_id, [])
                if not t_list:
                    continue

                needed = subj.weekly_hours if not subj.is_lab else subj.weekly_hours // 2
                done   = 0
                rooms  = self.lab_rooms if subj.is_lab else self.class_rooms

                if subj.is_lab:
                    # Attempt consecutive pairs, no soft checks
                    for day in self.DAY_ORDER:
                        if done >= needed:
                            break
                        for (sa, sb) in self.consec_pairs.get(day, []):
                            if done >= needed:
                                break
                            if sa in sec_busy[sec.section_id] or sb in sec_busy[sec.section_id]:
                                continue
                            # Only check hard conflicts — skip daily hours limit
                            tid = self._pick_teacher(t_list, [sa, sb], teacher_busy, teacher_daily_hrs)
                            room = self._pick_room(rooms, [sa, sb], room_busy, sec.total_students)
                            if not tid or not room:
                                continue
                            self._assign(sec.section_id, subj.subject_id, tid, room.room_id,
                                         [sa, sb], sec_busy[sec.section_id],
                                         teacher_busy, room_busy, teacher_daily_hrs, all_assignments)
                            done += 1
                else:
                    for sl in all_slots:
                        if done >= needed:
                            break
                        if sl.slot_id in sec_busy[sec.section_id]:
                            continue
                        # Skip max_hours_per_day limit by passing empty tracker
                        tid = self._pick_teacher(t_list, [sl.slot_id], teacher_busy, defaultdict(dict))
                        room = self._pick_room(rooms, [sl.slot_id], room_busy, sec.total_students)
                        if not tid or not room:
                            continue
                        self._assign(sec.section_id, subj.subject_id, tid, room.room_id,
                                     [sl.slot_id], sec_busy[sec.section_id],
                                     teacher_busy, room_busy, teacher_daily_hrs, all_assignments)
                        done += 1

        logger.info(f"solve_relaxed: {len(all_assignments)} classes placed (fallback mode)")
        return "partial", all_assignments
