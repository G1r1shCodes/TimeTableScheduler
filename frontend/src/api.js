import axios from 'axios';

const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

const api = axios.create({ baseURL: BASE_URL });

// Attach JWT token to every request if present
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// ── Auth ──────────────────────────────────────────────────────────────────────
export const login = (username, password) => {
  const form = new URLSearchParams();
  form.append('username', username);
  form.append('password', password);
  return api.post('/auth/login', form, {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  });
};

export const getMe = () => api.get('/auth/me');

// ── Scheduler ─────────────────────────────────────────────────────────────────
export const generateSchedule = (semesterId, deptId, dryRun, maxRetries) =>
  api.post('/schedule/generate', {
    semester_id: semesterId,
    dept_id: deptId || null,
    dry_run: dryRun,
    max_retries: maxRetries,
  });

// ── Timetable view ────────────────────────────────────────────────────────────
export const getSectionList = () => api.get('/admin/sections').catch(() => ({ data: [] }));

export const getSectionTimetable = (semesterId, sectionId) =>
  api.get(`/timetable/section/${sectionId}`, { params: { semester_id: semesterId } });

export const getTeacherTimetable = (semesterId, teacherId) =>
  api.get(`/timetable/teacher/${teacherId}`, { params: { semester_id: semesterId } });

export const getRoomTimetable = (semesterId, roomId) =>
  api.get(`/timetable/room/${roomId}`, { params: { semester_id: semesterId } });

// Dashboard summary stats
export const getTimetableSummary = (semesterId) =>
  api.get(`/timetable/summary/${semesterId}`).catch(() => ({ data: {} }));

// ── Admin Builders ────────────────────────────────────────────────────────────
export const getTeachers = () => api.get('/admin/teachers');
export const getRooms = () => api.get('/admin/rooms');
export const getSubjects = () => api.get('/admin/subjects');
export const getMappings = () => api.get('/admin/mappings');

export const getBuildings = () => api.get('/admin/buildings');
export const getDepartments = () => api.get('/admin/departments');
export const getSemesters = () => api.get('/admin/semesters');
export const getTimeSlots = () => api.get('/admin/timeslots');
export const getConfig = () => api.get('/admin/config');
export const getAvailability = () => api.get('/admin/availability');

export const createTeacher = (data) => api.post('/admin/teachers', data);
export const createRoom = (data) => api.post('/admin/rooms', data);
export const createSubject = (data) => api.post('/admin/subjects', data);
export const createSection = (data) => api.post('/admin/sections', data);
export const createMapping = (data) => api.post('/admin/mappings', data);

export const createBuilding = (data) => api.post('/admin/buildings', data);
export const createDepartment = (data) => api.post('/admin/departments', data);
export const createSemester = (data) => api.post('/admin/semesters', data);
export const createTimeSlot = (data) => api.post('/admin/timeslots', data);
export const createAvailability = (data) => api.post('/admin/availability', data);
export const updateConfig = (id, data) => api.put(`/admin/config/${id}`, data);

export const deleteTeacher = (id) => api.delete(`/admin/teachers/${id}`);
export const deleteRoom = (id) => api.delete(`/admin/rooms/${id}`);
export const deleteSubject = (id) => api.delete(`/admin/subjects/${id}`);
export const deleteSection = (id) => api.delete(`/admin/sections/${id}`);
export const deleteMapping = (id) => api.delete(`/admin/mappings/${id}`);

export const deleteBuilding = (id) => api.delete(`/admin/buildings/${id}`);
export const deleteDepartment = (id) => api.delete(`/admin/departments/${id}`);
export const deleteSemester = (id) => api.delete(`/admin/semesters/${id}`);
export const deleteTimeSlot = (id) => api.delete(`/admin/timeslots/${id}`);
export const deleteAvailability = (id) => api.delete(`/admin/availability/${id}`);

// ── Validation ────────────────────────────────────────────────────────────────
export const validateTimetable = (semesterId) =>
  api.get(`/validate/${semesterId}`);
