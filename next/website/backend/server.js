require('dotenv').config();
const express = require('express');
const session = require('express-session');
const passport = require('passport');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');

// Import configurations
require('./config/passport')(passport);

// Import routes
const authRoutes = require('./routes/auth');
const urshiesRoutes = require('./routes/urshies');
const submissionsRoutes = require('./routes/submissions');
const statsRoutes = require('./routes/stats');

const app = express();
const PORT = process.env.PORT || 3001;

// Security middleware
app.use(helmet({
  contentSecurityPolicy: false, // Disable for development
  crossOriginEmbedderPolicy: false
}));

// CORS configuration
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Logging
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// Body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Session configuration
const sessionConfig = {
  secret: process.env.SESSION_SECRET || 'ursh-dev-secret-change-in-production',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000 // 24 hours
  }
};

// Use SQLite session store in production
if (process.env.NODE_ENV === 'production') {
  const SQLiteStore = require('connect-sqlite3')(session);
  sessionConfig.store = new SQLiteStore({
    db: 'sessions.db',
    dir: path.join(__dirname, '../database')
  });
}

app.use(session(sessionConfig));

// Passport middleware
app.use(passport.initialize());
app.use(passport.session());

// API Routes
app.use('/auth', authRoutes);
app.use('/api/urshies', urshiesRoutes);
app.use('/api/submissions', submissionsRoutes);
app.use('/api/stats', statsRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API documentation endpoint
app.get('/api', (req, res) => {
  res.json({
    name: 'Ursh Registry API',
    version: '1.0.0',
    endpoints: {
      auth: {
        'GET /auth/github': 'Initiate GitHub OAuth',
        'GET /auth/github/callback': 'OAuth callback',
        'GET /auth/me': 'Get current user',
        'POST /auth/logout': 'Logout',
        'GET /auth/status': 'Check auth status'
      },
      urshies: {
        'GET /api/urshies': 'List all urshies',
        'GET /api/urshies/:id': 'Get urshie by ID',
        'POST /api/urshies': 'Create urshie (auth required)',
        'PUT /api/urshies/:id': 'Update urshie (auth required)',
        'DELETE /api/urshies/:id': 'Delete urshie (auth required)',
        'GET /api/urshies/tags': 'Get all tags'
      },
      submissions: {
        'GET /api/submissions': 'List submissions',
        'GET /api/submissions/:id': 'Get submission by ID',
        'POST /api/submissions': 'Create submission (auth required)',
        'PUT /api/submissions/:id/status': 'Update status (admin)',
        'DELETE /api/submissions/:id': 'Delete submission'
      },
      stats: {
        'GET /api/stats': 'Get platform statistics',
        'GET /api/search': 'Global search'
      }
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'production' ? 'Something went wrong' : err.message
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Ursh Registry API running on port ${PORT}`);
  console.log(`📚 API documentation: http://localhost:${PORT}/api`);
});

module.exports = app;
