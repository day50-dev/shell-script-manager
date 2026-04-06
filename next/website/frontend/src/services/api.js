import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || '';

const api = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Auth API
export const authAPI = {
  getStatus: () => api.get('/auth/status'),
  getMe: () => api.get('/auth/me'),
  logout: () => api.post('/auth/logout'),
  githubLogin: () => {
    window.location.href = `${API_BASE_URL}/auth/github`;
  }
};

// Urshies API
export const urshiesAPI = {
  getAll: (params = {}) => api.get('/api/urshies', { params }),
  getById: (id) => api.get(`/api/urshies/${id}`),
  create: (data) => api.post('/api/urshies', data),
  inferAndCreate: (url) => api.post('/api/urshies/infer', { url }),
  update: (id, data) => api.put(`/api/urshies/${id}`, data),
  delete: (id) => api.delete(`/api/urshies/${id}`),
  getTags: () => api.get('/api/urshies/tags')
};

// Submissions API
export const submissionsAPI = {
  getAll: (params = {}) => api.get('/api/submissions', { params }),
  getById: (id) => api.get(`/api/submissions/${id}`),
  create: (data) => api.post('/api/submissions', data),
  updateStatus: (id, data) => api.put(`/api/submissions/${id}/status`, data),
  delete: (id) => api.delete(`/api/submissions/${id}`)
};

// Stats API
export const statsAPI = {
  getStats: () => api.get('/api/stats'),
  search: (query, type = 'all') => api.get('/api/search', { params: { q: query, type } })
};

export default api;
