const express = require('express');
const passport = require('passport');
const router = express.Router();

// Check if GitHub OAuth is configured
const isOAuthConfigured = !!(
  process.env.GITHUB_CLIENT_ID && 
  process.env.GITHUB_CLIENT_SECRET && 
  process.env.GITHUB_CLIENT_ID !== 'your_github_client_id_here'
);

/**
 * GET /auth/github
 * Initiate GitHub OAuth flow
 */
router.get('/github', (req, res) => {
  if (!isOAuthConfigured) {
    return res.status(503).json({
      error: 'OAuth not configured',
      message: 'GitHub OAuth credentials are not configured. Anonymous mode only.'
    });
  }
  passport.authenticate('github', { scope: ['user:email'] })(req, res);
});

/**
 * GET /auth/github/callback
 * GitHub OAuth callback
 */
router.get('/github/callback', (req, res, next) => {
  if (!isOAuthConfigured) {
    return res.status(503).json({
      error: 'OAuth not configured',
      message: 'GitHub OAuth credentials are not configured.'
    });
  }
  passport.authenticate('github', {
    failureRedirect: process.env.FRONTEND_URL || 'http://localhost:3000/login',
    failureMessage: true
  })(req, res, next);
},
(req, res) => {
  // Successful authentication, redirect to frontend
  const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
  res.redirect(`${frontendUrl}/dashboard?authenticated=true`);
});

/**
 * GET /auth/me
 * Get current authenticated user
 */
router.get('/me', (req, res) => {
  if (req.isAuthenticated()) {
    res.json({
      authenticated: true,
      user: {
        id: req.user.id,
        username: req.user.username,
        displayName: req.user.displayName,
        email: req.user.email,
        avatar: req.user.avatar
      }
    });
  } else {
    res.json({
      authenticated: false,
      user: null
    });
  }
});

/**
 * POST /auth/logout
 * Log out current user
 */
router.post('/logout', (req, res, next) => {
  req.logout((err) => {
    if (err) {
      return next(err);
    }
    res.json({ success: true, message: 'Logged out successfully' });
  });
});

/**
 * GET /auth/status
 * Check authentication status
 */
router.get('/status', (req, res) => {
  res.json({
    authenticated: req.isAuthenticated(),
    user: req.isAuthenticated() ? {
      id: req.user.id,
      username: req.user.username,
      displayName: req.user.displayName,
      avatar: req.user.avatar
    } : null
  });
});

module.exports = router;
