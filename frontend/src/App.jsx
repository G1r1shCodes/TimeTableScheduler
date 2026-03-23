import { useState, useEffect } from 'react';
import './index.css';
import Login from './components/Login';
import Sidebar from './components/Sidebar';
import Dashboard from './components/Dashboard';
import Timetables from './components/Timetables';
import AdminPanel from './components/AdminPanel';

export default function App() {
  const [user, setUser] = useState(null);
  const [currentView, setCurrentView] = useState('dashboard');

  // Restore session
  useEffect(() => {
    const token    = localStorage.getItem('token');
    const role     = localStorage.getItem('role');
    const username = localStorage.getItem('username');
    if (token && role && username) {
      setUser({ token, role, username });
    }
  }, []);

  const handleLogin = (data) => setUser(data);

  const handleLogout = () => {
    localStorage.clear();
    setUser(null);
    setCurrentView('dashboard');
  };

  if (!user) {
    return <Login onLogin={handleLogin} />;
  }

  return (
    <div className="app-shell">
      <Sidebar 
        user={user} 
        currentView={currentView} 
        onViewChange={setCurrentView} 
        onLogout={handleLogout} 
      />
      <main className="main-content">
        <div className="topbar">
          <h2 style={{ fontSize: '1.05rem', fontWeight: 600 }}>
            {currentView === 'dashboard'  && 'Dashboard Overview'}
            {currentView === 'timetables' && 'Timetable Viewer'}
            {currentView === 'admin'      && 'Admin Control Panel'}
          </h2>
        </div>
        <div className="page-container">
          {currentView === 'dashboard'  && <Dashboard />}
          {currentView === 'timetables' && <Timetables />}
          {currentView === 'admin'      && user.role === 'admin' && <AdminPanel />}
        </div>
      </main>
    </div>
  );
}
