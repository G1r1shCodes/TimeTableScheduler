import { useState } from 'react';

export default function Sidebar({ user, currentView, onViewChange, onLogout }) {
  const navItems = [
    { id: 'dashboard', label: 'Dashboard', icon: '📊' },
    { id: 'timetables', label: 'Timetables', icon: '🗓️' },
    { id: 'admin', label: 'Admin Panel', icon: '⚙️', adminOnly: true }
  ];

  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <span>📅</span> IILM Scheduler
      </div>
      
      <nav className="sidebar-nav">
        {navItems.map(item => {
          if (item.adminOnly && user?.role !== 'admin') return null;
          return (
            <button
              key={item.id}
              className={`nav-item ${currentView === item.id ? 'active' : ''}`}
              onClick={() => onViewChange(item.id)}
            >
              <span style={{ fontSize: '1.1rem' }}>{item.icon}</span>
              {item.label}
            </button>
          );
        })}
      </nav>

      <div className="sidebar-footer">
        <div className="user-profile">
          <div style={{ 
            width: '28px', height: '28px', 
            borderRadius: '4px', background: 'var(--bg-surface)', 
            border: '1px solid var(--border-light)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: '0.8rem'
          }}>
            👤
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
            <span style={{ color: 'var(--text-main)', fontWeight: 600, fontSize: '0.85rem' }}>{user?.username}</span>
            <span style={{ fontSize: '0.7rem', color: 'var(--text-dim)', textTransform: 'uppercase' }}>{user?.role}</span>
          </div>
        </div>
        <button 
          className="btn btn-outline" 
          onClick={onLogout}
          style={{ width: '100%', marginTop: '0.5rem' }}
        >
          Sign out
        </button>
      </div>
    </aside>
  );
}
