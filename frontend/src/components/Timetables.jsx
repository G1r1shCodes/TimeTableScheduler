import { useState, useEffect, useCallback } from 'react';
import { 
  getSectionList, getTeachers, getRooms,
  getSectionTimetable, getTeacherTimetable, getRoomTimetable 
} from '../api';

const DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

// Reusable Grid Component
function TimetableGrid({ entries, viewType }) {
  if (!entries || entries.length === 0) {
    return (
      <div style={{ textAlign: 'center', padding: '3rem 1rem', color: 'var(--text-muted)' }}>
        <div style={{ fontSize: '2rem', marginBottom: '1rem' }}>📭</div>
        <p>No schedule generated for this selection.</p>
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
          {allTimes.map(time => {
            return (
              <tr key={time}>
                <td style={{ color: 'var(--text-dim)', textAlign: 'center' }}>{time}</td>
                {DAYS.map(day => {
                  const cells = byDayTime[`${day}__${time}`] || [];
                  if (cells.length === 0) return <td key={day}></td>;
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
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

export default function Timetables() {
  const [activeTab, setActiveTab] = useState('section'); // section, teacher, room
  const [semesterId, setSemesterId] = useState('1');
  
  // Lists
  const [sections, setSections] = useState([]);
  const [teachers, setTeachers] = useState([]);
  const [rooms, setRooms] = useState([]);
  
  // Selections
  const [selectedId, setSelectedId] = useState(null);
  
  // Timetable State
  const [ttEntries, setTtEntries] = useState([]);
  const [loading, setLoading] = useState(false);

  // Load Lists
  useEffect(() => {
    getSectionList().then(res => setSections(res.data));
    getTeachers().then(res => setTeachers(res.data));
    getRooms().then(res => setRooms(res.data));
  }, []);

  // Set default selection when tab changes
  useEffect(() => {
    setTtEntries([]);
    setSelectedId(null);
    if (activeTab === 'section' && sections.length > 0) setSelectedId(sections[0].section_id);
    if (activeTab === 'teacher' && teachers.length > 0) setSelectedId(teachers[0].teacher_id);
    if (activeTab === 'room' && rooms.length > 0)       setSelectedId(rooms[0].room_id);
  }, [activeTab, sections, teachers, rooms]);

  // Fetch Timetable
  useEffect(() => {
    if (!selectedId || !semesterId) {
      setTtEntries([]);
      return;
    }
    setLoading(true);
    let fetchFn;
    if (activeTab === 'section') fetchFn = getSectionTimetable;
    if (activeTab === 'teacher') fetchFn = getTeacherTimetable;
    if (activeTab === 'room')    fetchFn = getRoomTimetable;

    fetchFn(semesterId, selectedId)
      .then(res => {
        const data = res.data.schedule || res.data || [];
        setTtEntries(data);
      })
      .catch(() => setTtEntries([]))
      .finally(() => setLoading(false));
  }, [activeTab, selectedId, semesterId]);

  return (
    <div className="flex-col">
      <div className="card mb-2" style={{ padding: '1rem 1.5rem', display: 'flex', gap: '1.5rem', alignItems: 'center' }}>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <button className={`tab-btn ${activeTab === 'section' ? 'active' : ''}`} onClick={() => setActiveTab('section')}>Sections</button>
          <button className={`tab-btn ${activeTab === 'teacher' ? 'active' : ''}`} onClick={() => setActiveTab('teacher')}>Teachers</button>
          <button className={`tab-btn ${activeTab === 'room'    ? 'active' : ''}`} onClick={() => setActiveTab('room')}>Rooms</button>
        </div>
        
        <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div className="input-group flex-row" style={{ alignItems: 'center' }}>
            <label style={{ margin: 0 }}>Semester</label>
            <input 
              type="number" 
              value={semesterId} 
              onChange={e => setSemesterId(e.target.value)} 
              style={{ width: '80px', padding: '0.4rem 0.6rem' }} 
            />
          </div>
          
          <select 
            value={selectedId || ''} 
            onChange={e => setSelectedId(e.target.value)}
            style={{ minWidth: '200px', padding: '0.4rem 0.6rem' }}
          >
            <option value="" disabled>Select {activeTab}...</option>
            {activeTab === 'section' && sections.map(s => <option key={s.section_id} value={s.section_id}>{s.section_id}</option>)}
            {activeTab === 'teacher' && teachers.map(t => <option key={t.teacher_id} value={t.teacher_id}>{t.teacher_name} ({t.teacher_id})</option>)}
            {activeTab === 'room'    && rooms.map(r => <option key={r.room_id} value={r.room_id}>{r.room_id} - {r.room_type}</option>)}
          </select>
        </div>
      </div>

      <div className="card">
        <div className="section-title flex-row" style={{ justifyContent: 'space-between' }}>
          <span>🗓 Weekly Schedule</span>
          {selectedId && <span className="badge badge-accent">{selectedId}</span>}
        </div>
        
        {loading ? (
          <div style={{ textAlign: 'center', padding: '3rem' }}>
            <span className="spinner" />
          </div>
        ) : (
          <TimetableGrid entries={ttEntries} viewType={activeTab} />
        )}
      </div>
    </div>
  );
}
