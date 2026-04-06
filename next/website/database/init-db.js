#!/usr/bin/env node
/**
 * Database initialization script
 * Creates tables and inserts seed data
 */

const path = require('path');
const fs = require('fs');

// Load better-sqlite3 from backend node_modules
const backendNodeModules = path.join(__dirname, '../backend/node_modules');
const Module = require('module');
const originalRequire = Module.prototype.require;
Module.prototype.require = function(id) {
  if (id === 'better-sqlite3') {
    try {
      return originalRequire.call(this, path.join(backendNodeModules, 'better-sqlite3'));
    } catch (e) {
      // Fallback to normal require
    }
  }
  return originalRequire.apply(this, arguments);
};

const Database = require('better-sqlite3');

const dbPath = process.env.DATABASE_PATH || path.join(__dirname, 'ursh.db');

// Ensure database directory exists
const dbDir = path.dirname(dbPath);
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}

console.log(`📦 Initializing database at: ${dbPath}`);

const db = new Database(dbPath);

// Enable foreign keys
db.pragma('foreign_keys = ON');

// Create tables
const tables = `
-- Users table (populated from GitHub OAuth)
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  github_id TEXT UNIQUE NOT NULL,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  email TEXT,
  avatar_url TEXT,
  profile_url TEXT,
  is_admin INTEGER DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Urshies table (the main registry entries)
CREATE TABLE IF NOT EXISTS urshies (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  script_url TEXT NOT NULL,
  homepage_url TEXT,
  readme_url TEXT,
  license TEXT,
  checksum TEXT,
  created_by TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES users(username)
);

-- Tags for urshies
CREATE TABLE IF NOT EXISTS urshie_tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  urshie_id INTEGER NOT NULL,
  tag TEXT NOT NULL,
  UNIQUE(urshie_id, tag),
  FOREIGN KEY (urshie_id) REFERENCES urshies(id) ON DELETE CASCADE
);

-- Submissions (individual script instances for each urshie)
CREATE TABLE IF NOT EXISTS submissions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  urshie_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  script_url TEXT NOT NULL,
  homepage_url TEXT,
  notes TEXT,
  status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'approved', 'rejected', 'needs_review')),
  needs_review INTEGER DEFAULT 0,
  review_notes TEXT,
  reviewed_by INTEGER,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (urshie_id) REFERENCES urshies(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (reviewed_by) REFERENCES users(id)
);

-- Audit log for tracking changes
CREATE TABLE IF NOT EXISTS audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id INTEGER,
  details TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_urshies_name ON urshies(name);
CREATE INDEX IF NOT EXISTS idx_urshies_created_at ON urshies(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_urshie_tags_tag ON urshie_tags(tag);
CREATE INDEX IF NOT EXISTS idx_submissions_status ON submissions(status);
CREATE INDEX IF NOT EXISTS idx_submissions_urshie_id ON submissions(urshie_id);
CREATE INDEX IF NOT EXISTS idx_users_github_id ON users(github_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_entity ON audit_log(entity_type, entity_id);
`;

db.exec(tables);
console.log('✅ Tables created successfully');

// Insert sample data for testing
const sampleData = `
-- Insert sample users
INSERT OR IGNORE INTO users (github_id, username, display_name, email, avatar_url) VALUES
  ('1', 'ursh-admin', 'Ursh Admin', 'admin@ursh.dev', 'https://avatars.githubusercontent.com/u/1'),
  ('2', 'script-author', 'Script Author', 'author@example.com', 'https://avatars.githubusercontent.com/u/2'),
  ('3', 'community-user', 'Community User', 'user@example.com', 'https://avatars.githubusercontent.com/u/3');

-- Insert sample urshies
INSERT OR IGNORE INTO urshies (name, description, script_url, homepage_url, created_by) VALUES
  ('dev-setup', 'Quick development environment setup script', 'https://raw.githubusercontent.com/day50-dev/ursh/main/examples/hello.sh', 'https://github.com/day50-dev/ursh', 'ursh-admin'),
  ('docker-helper', 'Docker container management utilities', 'https://raw.githubusercontent.com/day50-dev/ursh/main/examples/docker-test.sh', 'https://github.com/day50-dev/ursh', 'ursh-admin'),
  ('color-test', 'Terminal color testing utility', 'https://raw.githubusercontent.com/day50-dev/ursh/main/examples/colors.sh', 'https://github.com/day50-dev/ursh', 'script-author');

-- Insert sample tags
INSERT OR IGNORE INTO urshie_tags (urshie_id, tag) VALUES
  (1, 'development'),
  (1, 'setup'),
  (1, 'productivity'),
  (2, 'docker'),
  (2, 'containers'),
  (2, 'devops'),
  (3, 'testing'),
  (3, 'terminal'),
  (3, 'utilities');

-- Insert sample submissions
INSERT OR IGNORE INTO submissions (urshie_id, user_id, script_url, homepage_url, status, needs_review) VALUES
  (1, 1, 'https://raw.githubusercontent.com/day50-dev/ursh/main/examples/hello.sh', 'https://github.com/day50-dev/ursh', 'approved', 0),
  (2, 1, 'https://raw.githubusercontent.com/day50-dev/ursh/main/examples/docker-test.sh', 'https://github.com/day50-dev/ursh', 'approved', 0),
  (3, 2, 'https://raw.githubusercontent.com/day50-dev/ursh/main/examples/colors.sh', 'https://github.com/day50-dev/ursh', 'approved', 0);
`;

try {
  db.exec(sampleData);
  console.log('✅ Sample data inserted');
} catch (err) {
  console.log('ℹ️  Sample data may already exist');
}

// Verify tables
const tables_result = db.prepare(`
  SELECT name FROM sqlite_master 
  WHERE type='table' 
  ORDER BY name
`).all();

console.log('\n📊 Database tables:');
tables_result.forEach(t => console.log(`   - ${t.name}`));

console.log('\n✨ Database initialization complete!');

db.close();
