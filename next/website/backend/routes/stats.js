const express = require('express');
const router = express.Router();
const db = require('../config/database');

/**
 * GET /api/stats
 * Get platform statistics
 */
router.get('/', (req, res) => {
  try {
    const stats = {
      totalUrshies: db.prepare('SELECT COUNT(*) as count FROM urshies').get().count,
      totalSubmissions: db.prepare('SELECT COUNT(*) as count FROM submissions').get().count,
      totalUsers: db.prepare('SELECT COUNT(*) as count FROM users').get().count,
      pendingSubmissions: db.prepare("SELECT COUNT(*) as count FROM submissions WHERE status = 'pending'").get().count,
      needsReview: db.prepare('SELECT COUNT(*) as count FROM submissions WHERE needs_review = 1').get().count,
      topTags: db.prepare(`
        SELECT tag, COUNT(*) as count 
        FROM urshie_tags 
        GROUP BY tag 
        ORDER BY count DESC 
        LIMIT 10
      `).all(),
      recentUrshies: db.prepare(`
        SELECT id, name, description, created_at 
        FROM urshies 
        ORDER BY created_at DESC 
        LIMIT 5
      `).all()
    };
    
    res.json(stats);
  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({ error: 'Failed to fetch statistics' });
  }
});

/**
 * GET /api/search
 * Global search across urshies
 */
router.get('/search', (req, res) => {
  try {
    const { q, type = 'all' } = req.query;
    
    if (!q || q.length < 2) {
      return res.json({ results: [] });
    }
    
    const searchTerm = `%${q}%`;
    let results = [];
    
    if (type === 'all' || type === 'urshies') {
      const urshies = db.prepare(`
        SELECT 'urshie' as type, id, name as title, description as snippet, script_url as url, created_at
        FROM urshies
        WHERE name LIKE ? OR description LIKE ?
        ORDER BY created_at DESC
        LIMIT 10
      `).all(searchTerm, searchTerm);
      results = [...results, ...urshies];
    }
    
    res.json({ results, query: q, type });
  } catch (error) {
    console.error('Error searching:', error);
    res.status(500).json({ error: 'Search failed' });
  }
});

module.exports = router;
