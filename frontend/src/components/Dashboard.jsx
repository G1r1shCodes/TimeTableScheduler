import { useState } from 'react';
import { generateSchedule } from '../api';

function Toast({ msg, type, onClose }) {
  // Simple auto-dismiss handled by parent or just click to close
  return (
    <div className={`toast toast-${type}`} onClick={onClose} style={{cursor: 'pointer'}}>
      {type === 'success' ? '✅ ' : '❌ '}{msg}
    </div>
  );
}

export default function Dashboard() {
  const [semesterId, setSemesterId]   = useState('1');
  const [deptId, setDeptId]           = useState('');
  const [dryRun, setDryRun]           = useState(false);
  const [maxRetries, setMaxRetries]   = useState(3);
  const [generating, setGenerating]   = useState(false);
  const [lastResult, setLastResult]   = useState(null);
  const [toast, setToast]             = useState(null);

  const showToast = (msg, type = 'success') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 4000);
  };

  const handleGenerate = async (e) => {
    e.preventDefault();
    setGenerating(true);
    setLastResult(null);
    try {
      const res = await generateSchedule(
        parseInt(semesterId), deptId || null, dryRun, maxRetries
      );
      const result = res.data;
      setLastResult(result);
      if (result.status !== 'error') {
        showToast(
          result.status === 'partial'
            ? 'Partial schedule generated (fallback mode)'
            : 'Schedule generated successfully! 🎉',
          result.status === 'partial' ? 'warning' : 'success'
        );
      } else {
        showToast(result.message || 'Generation failed', 'error');
      }
    } catch (err) {
      const msg = err.response?.data?.detail || 'Unexpected error';
      showToast(msg, 'error');
    } finally {
      setGenerating(false);
    }
  };

  return (
    <div className="flex-col">
      {toast && <Toast msg={toast.msg} type={toast.type} onClose={() => setToast(null)} />}

      {/* ── Stats row ── */}
      {lastResult && (
        <div className="grid-3 mb-2">
          <div className="card stat-card">
            <div className="value">{lastResult.entries_saved ?? '—'}</div>
            <div className="label">Slots Saved</div>
          </div>
          <div className="card stat-card">
            <div className="value">{lastResult.departments?.length ?? '—'}</div>
            <div className="label">Departments</div>
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
      <div className="card" style={{ maxWidth: '600px' }}>
        <div className="section-title">⚡ Generate Schedule Engine</div>
        <form onSubmit={handleGenerate} className="flex-col">
          <div className="grid-2">
            <div className="input-group">
              <label>Semester ID</label>
              <input
                type="number" min="1"
                value={semesterId}
                onChange={e => setSemesterId(e.target.value)}
                required
              />
            </div>
            <div className="input-group">
              <label>Department (leave blank for all)</label>
              <input
                type="text"
                placeholder="e.g. CSE"
                value={deptId}
                onChange={e => setDeptId(e.target.value)}
              />
            </div>
          </div>
          <div className="input-group">
            <label>Max Retries</label>
            <select value={maxRetries} onChange={e => setMaxRetries(+e.target.value)}>
              {[1,2,3,5,10].map(n => <option key={n} value={n}>{n}</option>)}
            </select>
          </div>
          <label className="flex-row mt-1" style={{ gap: '0.5rem', cursor: 'pointer', userSelect: 'none' }}>
            <input
              type="checkbox"
              style={{ width: 'auto' }}
              checked={dryRun}
              onChange={e => setDryRun(e.target.checked)}
            />
            <span style={{ fontSize: '0.88rem', color: 'var(--text-muted)' }}>Dry run (validate, don't save)</span>
          </label>
          <button className="btn btn-primary mt-1" type="submit" disabled={generating}>
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
              {lastResult.warnings.slice(0, 5).map((w, i) => <li key={i}>• {w}</li>)}
              {lastResult.warnings.length > 5 && (
                <li>… and {lastResult.warnings.length - 5} more</li>
              )}
            </ul>
          </div>
        )}
      </div>
    </div>
  );
}
