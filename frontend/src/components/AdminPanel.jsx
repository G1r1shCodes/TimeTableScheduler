import { useState, useEffect } from 'react';
import { 
  getTeachers, getRooms, getSubjects, getSectionList,
  createTeacher, createRoom, createSubject, createSection,
  deleteTeacher, deleteRoom, deleteSubject, deleteSection
} from '../api';

function DataTable({ columns, data, onDelete }) {
  if (!data || data.length === 0) return <p style={{ color: 'var(--text-muted)' }}>No records found.</p>;
  
  return (
    <div className="table-wrapper">
      <table className="data-table">
        <thead>
          <tr>
            {columns.map(col => <th key={col.key || col.label}>{col.label}</th>)}
            <th style={{ width: '80px', textAlign: 'right' }}>Actions</th>
          </tr>
        </thead>
        <tbody>
          {data.map((row, idx) => (
            <tr key={idx}>
              {columns.map(col => (
                <td key={col.key || col.label}>
                  {col.render ? col.render(row) : row[col.key]}
                </td>
              ))}
              <td style={{ textAlign: 'right' }}>
                <button 
                  className="btn btn-danger-outline" 
                  style={{ padding: '0.25rem 0.5rem', fontSize: '0.75rem' }}
                  onClick={() => onDelete(row)}
                >
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default function AdminPanel() {
  const [activeTab, setActiveTab] = useState('teachers');
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);

  // Form state
  const [formVisible, setFormVisible] = useState(false);
  const [formData, setFormData] = useState({});

  const loadData = () => {
    setLoading(true);
    let promise;
    if (activeTab === 'teachers') promise = getTeachers();
    if (activeTab === 'rooms')    promise = getRooms();
    if (activeTab === 'subjects') promise = getSubjects();
    if (activeTab === 'sections') promise = getSectionList();

    promise.then(res => setData(res.data)).finally(() => setLoading(false));
  };

  useEffect(() => {
    setFormVisible(false);
    setFormData({});
    loadData();
  }, [activeTab]);

  const handleDelete = async (row) => {
    if (!window.confirm('Are you sure you want to delete this record?')) return;
    try {
      if (activeTab === 'teachers') await deleteTeacher(row.teacher_id);
      if (activeTab === 'rooms')    await deleteRoom(row.room_id);
      if (activeTab === 'subjects') await deleteSubject(row.subject_id);
      if (activeTab === 'sections') await deleteSection(row.section_id);
      loadData();
    } catch (err) {
      alert('Failed to delete: ' + (err.response?.data?.detail || err.message));
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (activeTab === 'teachers') await createTeacher(formData);
      if (activeTab === 'rooms')    await createRoom({ ...formData, capacity: parseInt(formData.capacity) });
      if (activeTab === 'subjects') await createSubject({ ...formData, weekly_hours: parseInt(formData.weekly_hours), slot_count: parseInt(formData.slot_count || 1) });
      if (activeTab === 'sections') await createSection({ ...formData, year: parseInt(formData.year), total_students: parseInt(formData.total_students) });
      setFormVisible(false);
      setFormData({});
      loadData();
    } catch (err) {
      alert('Failed to save: ' + (err.response?.data?.detail || err.message));
    }
  };

  const renderForm = () => {
    if (activeTab === 'teachers') return (
      <>
        <div className="input-group"><label>Teacher ID</label><input required onChange={e => setFormData({...formData, teacher_id: e.target.value})} /></div>
        <div className="input-group"><label>Name</label><input required onChange={e => setFormData({...formData, teacher_name: e.target.value})} /></div>
        <div className="input-group"><label>Department ID</label><input required onChange={e => setFormData({...formData, dept_id: e.target.value})} /></div>
      </>
    );
    if (activeTab === 'rooms') return (
      <>
        <div className="input-group"><label>Room ID</label><input required onChange={e => setFormData({...formData, room_id: e.target.value})} /></div>
        <div className="input-group"><label>Building ID</label><input required onChange={e => setFormData({...formData, building_id: e.target.value})} /></div>
        <div className="input-group"><label>Room Type</label>
          <select required onChange={e => setFormData({...formData, room_type: e.target.value})}>
            <option value="">Select...</option><option value="CLASS">CLASS</option><option value="LAB">LAB</option>
          </select>
        </div>
        <div className="input-group"><label>Capacity</label><input type="number" required onChange={e => setFormData({...formData, capacity: e.target.value})} /></div>
      </>
    );
    if (activeTab === 'subjects') return (
      <>
        <div className="input-group"><label>Subject ID</label><input required onChange={e => setFormData({...formData, subject_id: e.target.value})} /></div>
        <div className="input-group"><label>Subject Name</label><input required onChange={e => setFormData({...formData, subject_name: e.target.value})} /></div>
        <div className="input-group"><label>Department ID</label><input required onChange={e => setFormData({...formData, dept_id: e.target.value})} /></div>
        <div className="input-group"><label>Weekly Hrs</label><input type="number" required onChange={e => setFormData({...formData, weekly_hours: e.target.value})} /></div>
      </>
    );
    if (activeTab === 'sections') return (
      <>
        <div className="input-group"><label>Section ID</label><input required onChange={e => setFormData({...formData, section_id: e.target.value})} /></div>
        <div className="input-group"><label>Year</label><input type="number" required onChange={e => setFormData({...formData, year: e.target.value})} /></div>
        <div className="input-group"><label>Dept ID</label><input required onChange={e => setFormData({...formData, dept_id: e.target.value})} /></div>
        <div className="input-group"><label>Students</label><input type="number" required onChange={e => setFormData({...formData, total_students: e.target.value})} /></div>
      </>
    );
  };

  const configs = {
    teachers: [
      { key: 'teacher_id', label: 'ID' },
      { key: 'teacher_name', label: 'Name' },
      { key: 'dept_id', label: 'Dept' },
      { label: 'Status', render: r => <span className={`badge badge-${r.is_active ? 'success' : 'danger'}`}>{r.is_active ? 'Active' : 'Inactive'}</span> }
    ],
    rooms: [
      { key: 'room_id', label: 'Room' },
      { key: 'building_id', label: 'Building' },
      { key: 'room_type', label: 'Type' },
      { key: 'capacity', label: 'Capacity' },
    ],
    subjects: [
      { key: 'subject_id', label: 'Code' },
      { key: 'subject_name', label: 'Subject Name' },
      { key: 'dept_id', label: 'Dept' },
      { key: 'weekly_hours', label: 'Hrs/Wk' }
    ],
    sections: [
      { key: 'section_id', label: 'Section' },
      { key: 'dept_id', label: 'Dept' },
      { key: 'year', label: 'Year' },
      { key: 'total_students', label: 'Students' }
    ]
  };

  return (
    <div className="flex-col">
      <div className="tabs-header">
        <button className={`tab-btn ${activeTab === 'teachers' ? 'active' : ''}`} onClick={() => setActiveTab('teachers')}>Teachers</button>
        <button className={`tab-btn ${activeTab === 'rooms' ? 'active' : ''}`} onClick={() => setActiveTab('rooms')}>Rooms</button>
        <button className={`tab-btn ${activeTab === 'subjects' ? 'active' : ''}`} onClick={() => setActiveTab('subjects')}>Subjects</button>
        <button className={`tab-btn ${activeTab === 'sections' ? 'active' : ''}`} onClick={() => setActiveTab('sections')}>Sections</button>
      </div>

      <div className="card">
        <div className="flex-row" style={{ justifyContent: 'space-between', marginBottom: '1.5rem' }}>
          <h3 style={{ textTransform: 'capitalize' }}>Manage {activeTab}</h3>
          <button className="btn btn-primary" onClick={() => setFormVisible(!formVisible)}>
            {formVisible ? 'Cancel' : '+ Add New'}
          </button>
        </div>

        {formVisible && (
          <form onSubmit={handleSubmit} className="grid-2" style={{ marginBottom: '2rem', padding: '1.5rem', background: 'var(--bg-app)', border: '1px solid var(--border-light)', borderRadius: '6px' }}>
            {renderForm()}
            <div style={{ gridColumn: '1 / -1', display: 'flex', justifyContent: 'flex-end', marginTop: '0.5rem' }}>
              <button className="btn btn-primary" type="submit">Save Record</button>
            </div>
          </form>
        )}

        {loading ? <div style={{ padding: '2rem', textAlign: 'center' }}><span className="spinner" /></div>
                 : <DataTable columns={configs[activeTab]} data={data} onDelete={handleDelete} />}
      </div>
    </div>
  );
}
