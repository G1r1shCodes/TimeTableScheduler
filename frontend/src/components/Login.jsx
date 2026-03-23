import { useState } from 'react';
import { login } from '../api';

export default function Login({ onLogin }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading]   = useState(false);
  const [error, setError]       = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const res = await login(username, password);
      localStorage.setItem('token', res.data.access_token);
      localStorage.setItem('role', res.data.role);
      localStorage.setItem('username', res.data.username);
      onLogin(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || 'Login failed — check credentials');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-wrapper">
      <div className="card login-card">
        <div style={{ fontSize: '2rem', marginBottom: '1rem' }}>📅</div>
        <h1 style={{ marginBottom: '0.3rem', fontSize: '1.5rem' }}>Welcome to Scheduler</h1>
        <p style={{ marginBottom: '1.8rem', color: 'var(--text-muted)' }}>Sign in to manage your timetables</p>

        <form onSubmit={handleSubmit} className="flex-col">
          <div className="input-group">
            <label>Username</label>
            <input
              type="text"
              placeholder="admin"
              value={username}
              onChange={e => setUsername(e.target.value)}
              autoFocus
              required
            />
          </div>
          <div className="input-group">
            <label>Password</label>
            <input
              type="password"
              placeholder="••••••••"
              value={password}
              onChange={e => setPassword(e.target.value)}
              required
            />
          </div>

          {error && (
            <p style={{ color: 'var(--danger)', fontSize: '0.85rem' }}>{error}</p>
          )}

          <button className="btn btn-primary" type="submit" disabled={loading} style={{ marginTop: '0.5rem' }}>
            {loading ? <><span className="spinner" /> Signing in…</> : 'Sign In'}
          </button>
        </form>

        <p style={{ marginTop: '1.2rem', fontSize: '0.78rem', textAlign: 'center' }}>
          Default: <code style={{ color: 'var(--accent-light)' }}>admin / admin123</code>
        </p>
      </div>
    </div>
  );
}
