import { useState, useEffect } from 'react';
import { generateSchedule, getSemesters, getDepartments, getTeachers, getRooms, getSectionList, getSubjects } from '../api';

function Toast({ msg, type, onClose }) {
  return (
    <div className={`toast toast-${type}`} onClick={onClose} style={{cursor: 'pointer'}}>
      {type === 'success' ? '✅ ' : type === 'warning' ? '⚠️ ' : '❌ '}{msg}
    </div>
  );
}

function StatCard({ icon, value, label, accent }) {
  return (
    <div className="card stat-card" style={{ borderLeft: `3px solid ${accent || 'var(--accent)'}` }}>
      <div style={{ fontSize: '1.4rem', marginBottom: '0.25rem' }}>{icon}</div>
      <div className="value" style={{ fontSize: '2rem', fontWeight: 700, color: 'var(--text-main)' }}>{value}</div>
      <div className="label" style={{ fontSize: '0.7rem', textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--text-muted)' }}>{label}</div>
    </div>
  );
}

export default function Dashboard() {
  // Live DB stats
  const [stats, setStats]           = useState({ teachers: 0, rooms: 0, sections: 0, subjects: 0 });

  // Scheduler form
  const [semesters, setSemesters]   = useState([]);
  const [departments, setDepartments] = useState([]);
  const [semesterId, setSemesterId] = useState('');
  const [deptId, setDeptId]         = useState('');
  const [dryRun, setDryRun]         = useState(false);
  const [maxRetries, setMaxRetries] = useState(3);
  const [generating, setGenerating] = useState(false);
  const [lastResult, setLastResult] = useState(null);
  const [toast, setToast]           = useState(null);

  const showToast = (msg, type = 'success') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 5000);
  };

  // Load dropdowns + stats on mount
  useEffect(() => {
    getSemesters().then(r => {
      setSemesters(r.data);
      const active = r.data.find(s => s.is_active) || r.data[0];
      if (active) setSemesterId(String(active.semester_id));
    }).catch(() => {});

    getDepartments().then(r => setDepartments(r.data)).catch(() => {});

    Promise.all([getTeachers(), getRooms(), getSectionList(), getSubjects()])
      .then(([t, r, s, sub]) => setStats({
        teachers: t.data.length,
        rooms: r.data.length,
        sections: s.data.length,
        subjects: sub.data.length
      }))
      .catch(() => {});
  }, []);

  const handleGenerate = async (e) => {
    e.preventDefault();
    setGenerating(true);
    setLastResult(null);
    try {
      const res = await generateSchedule(parseInt(semesterId), deptId || null, dryRun, maxRetries);
      const result = res.data;
      setLastResult(result);
      if (result.status !== 'error') {
        showToast(
          result.status === 'partial'
            ? `Partial schedule generated — ${result.entries_saved} slots saved`
            : `Schedule generated successfully! ${result.entries_saved} slots saved 🎉`,
          result.status === 'partial' ? 'warning' : 'success'
        );
      } else {
        showToast(result.message || 'Generation failed', 'error');
      }
    } catch (err) {
      showToast(err.response?.data?.detail || 'Unexpected error', 'error');
    } finally {
      setGenerating(false);
    }
  };

  return (
    <div className="flex-col">
      {toast && <Toast msg={toast.msg} type={toast.type} onClose={() => setToast(null)} />}

      {/* ── DB Overview Stats ── */}
      <div className="grid-4 mb-2">
        <StatCard icon="👨‍🏫" value={stats.teachers}  label="Teachers"  accent="var(--accent)" />
        <StatCard icon="🏫"   value={stats.rooms}     label="Rooms"     accent="#10b981" />
        <StatCard icon="👥"   value={stats.sections}  label="Sections"  accent="#f59e0b" />
        <StatCard icon="📚"   value={stats.subjects}  label="Subjects"  accent="#8b5cf6" />
      </div>

      {/* ── Last run result stats ── */}
      {lastResult && (
        <div className="grid-3 mb-2">
          <div className="card stat-card">
            <div className="value">{lastResult.entries_saved ?? '—'}</div>
            <div className="label">Slots Saved</div>
          </div>
          <div className="card stat-card">
            <div className="value">{lastResult.departments?.length ?? '—'}</div>
            <div className="label">Depts Scheduled</div>
          </div>
          <div className="card stat-card">
            <div className="value">
              <span className={`badge badge-${lastResult.status === 'success' ? 'success' : lastResult.status === 'partial' ? 'warning' : 'danger'}`}>
                {lastResult.status}
              </span>
            </div>
            <div className="label">Status</div>
          </div>
        </div>
      )}

      {/* ── Generate panel ── */}
      <div className="card" style={{ maxWidth: '640px' }}>
        <div className="section-title">⚡ Generate Schedule Engine</div>
        <form onSubmit={handleGenerate} className="flex-col">
          <div className="grid-2">
            {/* Semester dropdown */}
            <div className="input-group">
              <label>Semester</label>
              <select value={semesterId} onChange={e => setSemesterId(e.target.value)} required>
                <option value="" disabled>Select semester…</option>
                {semesters.map(s => (
                  <option key={s.semester_id} value={s.semester_id}>
                    Sem {s.semester} – {s.academic_year}{s.is_active ? ' ✓' : ''}
                  </option>
                ))}
              </select>
            </div>

            {/* Department dropdown */}
            <div className="input-group">
              <label>Department</label>
              <select value={deptId} onChange={e => setDeptId(e.target.value)}>
                <option value="">All Departments</option>
                {departments.map(d => (
                  <option key={d.dept_id} value={d.dept_id}>{d.dept_name} ({d.dept_id})</option>
                ))}
              </select>
            </div>
          </div>

          <div className="grid-2">
            <div className="input-group">
              <label>Max Retries</label>
              <select value={maxRetries} onChange={e => setMaxRetries(+e.target.value)}>
                {[1,2,3,5,10].map(n => <option key={n} value={n}>{n}</option>)}
              </select>
            </div>

            <div className="input-group" style={{ justifyContent: 'flex-end' }}>
              <label style={{ marginBottom: '0.5rem' }}>Mode</label>
              <label className="flex-row" style={{ gap: '0.5rem', cursor: 'pointer', userSelect: 'none', height: '38px', alignItems: 'center' }}>
                <input
                  type="checkbox"
                  style={{ width: 'auto' }}
                  checked={dryRun}
                  onChange={e => setDryRun(e.target.checked)}
                />
                <span style={{ fontSize: '0.88rem', color: 'var(--text-muted)' }}>Dry run (validate only)</span>
              </label>
            </div>
          </div>

          <button className="btn btn-primary mt-1" type="submit" disabled={generating || !semesterId}>
            {generating ? <><span className="spinner" /> Generating…</> : '🚀 Run Scheduler'}
          </button>
        </form>

        {/* Warnings */}
        {lastResult?.warnings?.length > 0 && (
          <div className="mt-2" style={{ background: 'rgba(245,158,11,0.05)', border: '1px solid rgba(245,158,11,0.2)', padding: '1rem', borderRadius: '6px' }}>
            <h3 style={{ color: 'var(--warning)', fontSize: '0.85rem', marginBottom: '0.5rem' }}>
              ⚠ Warnings ({lastResult.warnings.length})
            </h3>
            <ul style={{ listStyle: 'none', fontSize: '0.8rem', color: 'var(--text-muted)', display: 'flex', flexDirection: 'column', gap: '0.3rem' }}>
              {lastResult.warnings.slice(0, 8).map((w, i) => <li key={i}>• {w}</li>)}
              {lastResult.warnings.length > 8 && <li>… and {lastResult.warnings.length - 8} more</li>}
            </ul>
          </div>
        )}
      </div>
    </div>
  );
}
