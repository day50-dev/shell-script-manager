/**
 * Middleware to check if user is authenticated
 */
exports.isAuthenticated = (req, res, next) => {
  if (req.isAuthenticated()) {
    return next();
  }
  res.status(401).json({ 
    error: 'Authentication required',
    message: 'Please log in to perform this action'
  });
};

/**
 * Middleware to check if user is admin (optional - for future use)
 */
exports.isAdmin = (req, res, next) => {
  if (req.isAuthenticated() && req.user && req.user.isAdmin) {
    return next();
  }
  res.status(403).json({ 
    error: 'Forbidden',
    message: 'Admin access required'
  });
};

/**
 * Middleware to allow anonymous browsing but attach user if logged in
 */
exports.optionalAuth = (req, res, next) => {
  next();
};
