import { useState, useEffect } from 'react';
import { 
  getTeachers, getRooms, getSubjects, getSectionList, getBuildings, getDepartments, getSemesters, getTimeSlots, getConfig, getMappings, getAvailability,
  createTeacher, createRoom, createSubject, createSection, createBuilding, createDepartment, createSemester, createTimeSlot, updateConfig, createMapping, createAvailability,
  deleteTeacher, deleteRoom, deleteSubject, deleteSection, deleteBuilding, deleteDepartment, deleteSemester, deleteTimeSlot, deleteMapping, deleteAvailability
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
    if (activeTab === 'buildings') promise = getBuildings();
    if (activeTab === 'departments') promise = getDepartments();
    if (activeTab === 'semesters') promise = getSemesters();
    if (activeTab === 'timeslots') promise = getTimeSlots();
    if (activeTab === 'config') promise = getConfig();
    if (activeTab === 'mappings') promise = getMappings();
    if (activeTab === 'availability') promise = getAvailability();

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
      if (activeTab === 'buildings') await deleteBuilding(row.building_id);
      if (activeTab === 'departments') await deleteDepartment(row.dept_id);
      if (activeTab === 'semesters') await deleteSemester(row.semester_id);
      if (activeTab === 'timeslots') await deleteTimeSlot(row.slot_id);
      if (activeTab === 'mappings') await deleteMapping(row.mapping_id);
      if (activeTab === 'availability') await deleteAvailability(row.avail_id);
      if (activeTab === 'config') return alert("Cannot delete configuration blocks. Please update it instead.");
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
      if (activeTab === 'buildings') await createBuilding(formData);
      if (activeTab === 'departments') await createDepartment(formData);
      if (activeTab === 'semesters') await createSemester({ ...formData, semester: parseInt(formData.semester), is_active: formData.is_active === 'true' });
      if (activeTab === 'timeslots') await createTimeSlot({ ...formData, is_break: formData.is_break === 'true' });
      if (activeTab === 'mappings') await createMapping(formData);
      if (activeTab === 'availability') await createAvailability({ ...formData, slot_id: parseInt(formData.slot_id), is_blocked: formData.is_blocked !== 'false' });
      if (activeTab === 'config') {
          await updateConfig(formData.config_id || 1, {
             max_continuous_classes: parseInt(formData.max_continuous_classes),
             mandatory_break: formData.mandatory_break === 'true',
             max_hours_per_day: parseInt(formData.max_hours_per_day),
             same_building_pref: formData.same_building_pref === 'true'
          });
      }
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
    if (activeTab === 'buildings') return (
       <>
         <div className="input-group"><label>Building ID</label><input required onChange={e => setFormData({...formData, building_id: e.target.value})} /></div>
         <div className="input-group"><label>Building Name</label><input required onChange={e => setFormData({...formData, building_name: e.target.value})} /></div>
       </>
    );
    if (activeTab === 'departments') return (
       <>
         <div className="input-group"><label>Department ID</label><input required onChange={e => setFormData({...formData, dept_id: e.target.value})} /></div>
         <div className="input-group"><label>Department Name</label><input required onChange={e => setFormData({...formData, dept_name: e.target.value})} /></div>
       </>
    );
    if (activeTab === 'semesters') return (
       <>
         <div className="input-group"><label>Academic Year</label><input required placeholder="2024-25" onChange={e => setFormData({...formData, academic_year: e.target.value})} /></div>
         <div className="input-group"><label>Semester Number</label><input type="number" required onChange={e => setFormData({...formData, semester: e.target.value})} /></div>
         <div className="input-group"><label>Is Active?</label>
             <select required onChange={e => setFormData({...formData, is_active: e.target.value})}>
                 <option value="">Select...</option><option value="true">Yes</option><option value="false">No</option>
             </select>
         </div>
       </>
    );
    if (activeTab === 'timeslots') return (
       <>
         <div className="input-group"><label>Day</label>
             <select required onChange={e => setFormData({...formData, day: e.target.value})}>
                 <option value="">Select...</option><option value="Mon">Mon</option><option value="Tue">Tue</option><option value="Wed">Wed</option><option value="Thu">Thu</option><option value="Fri">Fri</option>
             </select>
         </div>
         <div className="input-group"><label>Start Time (HH:MM)</label><input required onChange={e => setFormData({...formData, start_time: e.target.value})} /></div>
         <div className="input-group"><label>End Time (HH:MM)</label><input required onChange={e => setFormData({...formData, end_time: e.target.value})} /></div>
         <div className="input-group"><label>Is Break</label>
             <select required onChange={e => setFormData({...formData, is_break: e.target.value})}>
                 <option value="">Select...</option><option value="true">Yes</option><option value="false">No</option>
             </select>
         </div>
       </>
    );
    if (activeTab === 'mappings') return (
       <>
         <div className="input-group"><label>Subject ID</label><input required onChange={e => setFormData({...formData, subject_id: e.target.value})} /></div>
         <div className="input-group"><label>Teacher ID</label><input required onChange={e => setFormData({...formData, teacher_id: e.target.value})} /></div>
       </>
    );
    if (activeTab === 'availability') return (
       <>
         <div className="input-group"><label>Teacher ID</label><input required onChange={e => setFormData({...formData, teacher_id: e.target.value})} /></div>
         <div className="input-group"><label>Slot ID</label><input type="number" required onChange={e => setFormData({...formData, slot_id: e.target.value})} /></div>
         <div className="input-group"><label>Reason</label><input required onChange={e => setFormData({...formData, reason: e.target.value})} /></div>
       </>
    );
    if (activeTab === 'config') return (
       <>
         <div className="input-group"><label>Config ID (Usually 1)</label><input type="number" required defaultValue={1} onChange={e => setFormData({...formData, config_id: e.target.value})} /></div>
         <div className="input-group"><label>Max Continuous Classes</label><input type="number" required defaultValue={3} onChange={e => setFormData({...formData, max_continuous_classes: e.target.value})} /></div>
         <div className="input-group"><label>Mandatory Break</label>
             <select required onChange={e => setFormData({...formData, mandatory_break: e.target.value})}>
                 <option value="">Select...</option><option value="true">Yes</option><option value="false">No</option>
             </select>
         </div>
         <div className="input-group"><label>Max Hours / Day</label><input type="number" required defaultValue={6} onChange={e => setFormData({...formData, max_hours_per_day: e.target.value})} /></div>
         <div className="input-group"><label>Same Building Pref</label>
             <select required onChange={e => setFormData({...formData, same_building_pref: e.target.value})}>
                 <option value="">Select...</option><option value="true">Yes</option><option value="false">No</option>
             </select>
         </div>
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
    ],
    buildings: [
      { key: 'building_id', label: 'Building ID' },
      { key: 'building_name', label: 'Name' },
    ],
    departments: [
      { key: 'dept_id', label: 'Dept ID' },
      { key: 'dept_name', label: 'Name' },
    ],
    semesters: [
      { key: 'semester_id', label: 'ID' },
      { key: 'academic_year', label: 'Year' },
      { key: 'semester', label: 'Semester' },
      { label: 'Status', render: r => <span className={`badge badge-${r.is_active ? 'success' : 'danger'}`}>{r.is_active ? 'Active' : 'Inactive'}</span> }
    ],
    timeslots: [
      { key: 'slot_id', label: 'Slot ID' },
      { key: 'day', label: 'Day' },
      { key: 'start_time', label: 'Start Time' },
      { key: 'end_time', label: 'End Time' },
      { label: 'Break?', render: r => r.is_break ? 'Yes' : 'No' }
    ],
    mappings: [
      { key: 'mapping_id', label: 'Mapping ID' },
      { key: 'subject_id', label: 'Subject' },
      { key: 'teacher_id', label: 'Teacher' }
    ],
    availability: [
      { key: 'avail_id', label: 'Avail ID' },
      { key: 'teacher_id', label: 'Teacher' },
      { key: 'slot_id', label: 'Slot ID' },
      { label: 'Blocked?', render: r => r.is_blocked ? 'Yes' : 'No' },
      { key: 'reason', label: 'Reason' }
    ],
    config: [
      { key: 'config_id', label: 'Config ID' },
      { key: 'max_continuous_classes', label: 'Max Classes' },
      { label: 'Mandatory Break', render: r => r.mandatory_break ? 'Yes' : 'No' },
      { key: 'max_hours_per_day', label: 'Max hrs/day' },
      { label: 'Same Building', render: r => r.same_building_pref ? 'Yes' : 'No' }
    ]
  };

  return (
    <div className="flex-col">
      <div className="tabs-header" style={{ flexWrap: 'wrap', gap: '5px' }}>
        <button className={`tab-btn ${activeTab === 'teachers' ? 'active' : ''}`} onClick={() => setActiveTab('teachers')}>Teachers</button>
        <button className={`tab-btn ${activeTab === 'rooms' ? 'active' : ''}`} onClick={() => setActiveTab('rooms')}>Rooms</button>
        <button className={`tab-btn ${activeTab === 'subjects' ? 'active' : ''}`} onClick={() => setActiveTab('subjects')}>Subjects</button>
        <button className={`tab-btn ${activeTab === 'sections' ? 'active' : ''}`} onClick={() => setActiveTab('sections')}>Sections</button>
        <button className={`tab-btn ${activeTab === 'buildings' ? 'active' : ''}`} onClick={() => setActiveTab('buildings')}>Buildings</button>
        <button className={`tab-btn ${activeTab === 'departments' ? 'active' : ''}`} onClick={() => setActiveTab('departments')}>Departments</button>
        <button className={`tab-btn ${activeTab === 'semesters' ? 'active' : ''}`} onClick={() => setActiveTab('semesters')}>Semesters</button>
        <button className={`tab-btn ${activeTab === 'timeslots' ? 'active' : ''}`} onClick={() => setActiveTab('timeslots')}>Time Slots</button>
        <button className={`tab-btn ${activeTab === 'mappings' ? 'active' : ''}`} onClick={() => setActiveTab('mappings')}>Mappings</button>
        <button className={`tab-btn ${activeTab === 'availability' ? 'active' : ''}`} onClick={() => setActiveTab('availability')}>Availability</button>
        <button className={`tab-btn ${activeTab === 'config' ? 'active' : ''}`} onClick={() => setActiveTab('config')}>Config</button>
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
