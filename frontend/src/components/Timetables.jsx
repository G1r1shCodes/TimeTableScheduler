import { useState, useEffect } from 'react';
import { 
  getSectionList, getTeachers, getRooms, getSemesters,
  getSectionTimetable, getTeacherTimetable, getRoomTimetable 
} from '../api';

const DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

function TimetableGrid({ entries, viewType }) {
  if (!entries || entries.length === 0) {
    return (
      <div style={{ textAlign: 'center', padding: '3rem 1rem', color: 'var(--text-muted)' }}>
        <div style={{ fontSize: '2.5rem', marginBottom: '0.75rem' }}>📭</div>
        <p>No schedule generated for this selection.</p>
        <p style={{ fontSize: '0.78rem', marginTop: '0.25rem' }}>Run the scheduler on the Dashboard to generate a timetable.</p>
      </div>
    );
  }

  const allTimes = [...new Set(entries.map(e => e.start_time))].sort();
  const byDayTime = {};
  entries.forEach(e => {
    const key = `${e.day}__${e.start_time}`;
    if (!byDayTime[key]) byDayTime[key] = [];
    byDayTime[key].push(e);
  });

  return (
    <div className="tt-grid-wrapper">
      <table className="tt-grid">
        <thead>
          <tr>
            <th style={{ width: '80px' }}>Time</th>
            {DAYS.map(d => <th key={d}>{d}</th>)}
          </tr>
        </thead>
        <tbody>
          {allTimes.map(time => (
            <tr key={time}>
              <td style={{ color: 'var(--text-dim)', textAlign: 'center', fontWeight: 600, fontSize: '0.72rem' }}>{time}</td>
              {DAYS.map(day => {
                const cells = byDayTime[`${day}__${time}`] || [];
                if (cells.length === 0) return <td key={day} style={{ background: 'rgba(0,0,0,0.1)' }} />;
                return (
                  <td key={day}>
                    {cells.map((c, i) => (
                      <div key={i} className={`tt-cell ${c.is_lab ? 'lab' : 'theory'}`}>
                        <div className="subj">{c.subject_name}</div>
                        <div className="flex-col" style={{ gap: '0.1rem' }}>
                          {viewType !== 'teacher' && <div className="meta">👨‍🏫 {c.teacher_name}</div>}
                          {viewType !== 'room'    && <div className="meta">🏫 {c.room_id}</div>}
                          {viewType !== 'section' && <div className="meta">👥 {c.section_id}</div>}
                        </div>
                        {c.is_lab && <span className="badge badge-success mt-1">LAB</span>}
                      </div>
                    ))}
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default function Timetables() {
  const [activeTab, setActiveTab] = useState('section');
  const [semesterId, setSemesterId] = useState('');
  const [semesters, setSemesters]   = useState([]);
  
  const [sections, setSections] = useState([]);
  const [teachers, setTeachers] = useState([]);
  const [rooms, setRooms]       = useState([]);
  
  const [selectedId, setSelectedId] = useState(null);
  const [ttEntries, setTtEntries]   = useState([]);
  const [loading, setLoading]       = useState(false);

  useEffect(() => {
    getSemesters().then(r => {
      setSemesters(r.data);
      const active = r.data.find(s => s.is_active) || r.data[0];
      if (active) setSemesterId(String(active.semester_id));
    }).catch(() => {});
    getSectionList().then(res => setSections(res.data)).catch(() => {});
    getTeachers().then(res => setTeachers(res.data)).catch(() => {});
    getRooms().then(res => setRooms(res.data)).catch(() => {});
  }, []);

  // Immediately clear ID when tab changes to prevent stale cross-tab fetches
  const handleTabChange = (tab) => {
    setActiveTab(tab);
    setSelectedId(null);
    setTtEntries([]);
  };

  // Auto-select first item when list loads or tab changes (only if nothing selected yet)
  useEffect(() => {
    if (selectedId !== null) return;
    if (activeTab === 'section' && sections.length > 0) setSelectedId(sections[0].section_id);
    if (activeTab === 'teacher' && teachers.length > 0) setSelectedId(teachers[0].teacher_id);
    if (activeTab === 'room'    && rooms.length > 0)    setSelectedId(rooms[0].room_id);
  }, [activeTab, sections, teachers, rooms]);

  useEffect(() => {
    if (!selectedId || !semesterId) { setTtEntries([]); return; }
    setLoading(true);
    const fn = { section: getSectionTimetable, teacher: getTeacherTimetable, room: getRoomTimetable }[activeTab];
    fn(semesterId, selectedId)
      .then(res => setTtEntries(res.data.schedule || res.data || []))
      .catch(() => setTtEntries([]))
      .finally(() => setLoading(false));
  }, [activeTab, selectedId, semesterId]);

  return (
    <div className="flex-col">
      <div className="card mb-2" style={{ padding: '1rem 1.5rem', display: 'flex', gap: '1.5rem', alignItems: 'center', flexWrap: 'wrap' }}>
        <div style={{ display: 'flex', gap: '1rem' }}>
          {[
            { id: 'section', label: '👥 Sections' },
            { id: 'teacher', label: '👨‍🏫 Teachers' },
            { id: 'room',    label: '🏫 Rooms' },
          ].map(t => (
            <button key={t.id} className={`tab-btn ${activeTab === t.id ? 'active' : ''}`} onClick={() => handleTabChange(t.id)}>
              {t.label}
            </button>
          ))}
        </div>

        <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: '1rem', flexWrap: 'wrap' }}>
          <div className="input-group flex-row" style={{ alignItems: 'center', gap: '0.5rem' }}>
            <label style={{ margin: 0, whiteSpace: 'nowrap' }}>Semester</label>
            <select value={semesterId} onChange={e => setSemesterId(e.target.value)} style={{ width: '170px', padding: '0.4rem 0.6rem' }}>
              {semesters.map(s => (
                <option key={s.semester_id} value={s.semester_id}>
                  Sem {s.semester} ({s.academic_year})
                </option>
              ))}
            </select>
          </div>

          <select value={selectedId || ''} onChange={e => setSelectedId(e.target.value)} style={{ minWidth: '240px', padding: '0.4rem 0.6rem' }}>
            <option value="" disabled>Select {activeTab}…</option>
            {activeTab === 'section' && sections.map(s => <option key={s.section_id} value={s.section_id}>{s.section_id} — Year {s.year} ({s.dept_id})</option>)}
            {activeTab === 'teacher' && teachers.map(t => <option key={t.teacher_id} value={t.teacher_id}>{t.teacher_name} ({t.teacher_id})</option>)}
            {activeTab === 'room'    && rooms.map(r =>    <option key={r.room_id}    value={r.room_id}>{r.room_id} — {r.room_type}</option>)}
          </select>
        </div>
      </div>

      <div className="card">
        <div className="section-title flex-row" style={{ justifyContent: 'space-between' }}>
          <span>🗓 Weekly Schedule</span>
          {selectedId && <span className="badge badge-accent">{selectedId}</span>}
        </div>
        {loading
          ? <div style={{ textAlign: 'center', padding: '3rem' }}><span className="spinner" /></div>
          : <TimetableGrid entries={ttEntries} viewType={activeTab} />
        }
      </div>
    </div>
  );
}
