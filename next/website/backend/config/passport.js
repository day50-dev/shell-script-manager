const passport = require('passport');

module.exports = function(passport) {
  passport.serializeUser((user, done) => {
    done(null, user);
  });

  passport.deserializeUser((user, done) => {
    done(null, user);
  });

  // GitHub OAuth Strategy (only if credentials are provided)
  const clientID = process.env.GITHUB_CLIENT_ID;
  const clientSecret = process.env.GITHUB_CLIENT_SECRET;
  
  if (clientID && clientSecret && clientID !== 'your_github_client_id_here') {
    const GitHubStrategy = require('passport-github2').Strategy;
    passport.use(new GitHubStrategy({
      clientID: clientID,
      clientSecret: clientSecret,
      callbackURL: process.env.GITHUB_CALLBACK_URL || 'http://localhost:3001/auth/github/callback',
      scope: ['user:email']
    },
    (accessToken, refreshToken, profile, done) => {
      // Get primary email
      const email = profile.emails && profile.emails[0] ? profile.emails[0].value : null;

      const user = {
        id: profile.id,
        username: profile.username,
        displayName: profile.displayName || profile.username,
        email: email,
        avatar: profile.photos && profile.photos[0] ? profile.photos[0].value : null,
        profileUrl: profile.profileUrl,
        accessToken: accessToken
      };

      return done(null, user);
    }));
    console.log('✅ GitHub OAuth strategy loaded');
  } else {
    console.log('⚠️  GitHub OAuth not configured (anonymous mode only)');
  }
};
