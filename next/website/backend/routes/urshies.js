const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { isAuthenticated } = require('../middleware/auth');
const {
  submitUrshieRules,
  updateUrshieRules,
  handleValidationErrors
} = require('../middleware/validation');

/**
 * POST /api/urshies/infer
 * Infer metadata from URL and create urshie
 */
router.post('/infer', handleValidationErrors, async (req, res) => {
  try {
    const { url } = req.body;
    
    if (!url) {
      return res.status(400).json({ error: 'URL is required' });
    }
    
    // Call the inference harness (Python service)
    const { inferUrl } = await import('../services/inference.js');
    const inferenceResult = await inferUrl(url);
    
    if (inferenceResult.status === 'failed') {
      return res.status(400).json({
        error: 'Inference failed',
        details: inferenceResult.errors
      });
    }
    
    const manifest = inferenceResult.manifest;
    
    // Check for duplicates
    const existing = db.prepare('SELECT id FROM urshies WHERE name = ? OR script_url = ?').get(
      manifest.name, manifest.url
    );
    if (existing) {
      return res.status(409).json({
        error: 'Urshie already exists',
        message: 'An urshie with this name or script URL already exists'
      });
    }
    
    // Determine status based on confidence
    const needsReview = inferenceResult.confidence < 0.7 || inferenceResult.flags.length > 0;
    const status = needsReview ? 'pending' : 'approved';
    
    // Insert urshie
    const insert = db.prepare(`
      INSERT INTO urshies (name, description, script_url, homepage_url, license, created_by, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    `);
    
    const result = insert.run(
      manifest.name,
      manifest.description || null,
      manifest.url,
      manifest.homepage || null,
      manifest.license || null,
      'inferred'
    );
    const urshieId = result.lastInsertRowid;
    
    // Insert tags if any
    const tags = manifest.tags || [];
    if (tags.length > 0) {
      const tagInsert = db.prepare('INSERT INTO urshie_tags (urshie_id, tag) VALUES (?, ?)');
      for (const tag of tags) {
        tagInsert.run(urshieId, tag);
      }
    }
    
    // Create submission with inference metadata
    const submissionInsert = db.prepare(`
      INSERT INTO submissions (urshie_id, script_url, homepage_url, status, needs_review, review_notes, created_at)
      VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
    `);
    submissionInsert.run(
      urshieId,
      manifest.url,
      manifest.homepage || null,
      status,
      needsReview ? 1 : 0,
      needsReview ? `Auto-flagged: confidence=${inferenceResult.confidence}, flags=${inferenceResult.flags.join(',')}` : null
    );
    
    res.status(201).json({
      id: urshieId,
      manifest,
      confidence: inferenceResult.confidence,
      flags: inferenceResult.flags,
      status: needsReview ? 'needs_review' : 'approved',
      message: needsReview 
        ? 'Urshie created and queued for review' 
        : 'Urshie created successfully'
    });
  } catch (error) {
    console.error('Error inferring urshie:', error);
    res.status(500).json({ 
      error: 'Failed to infer urshie',
      details: error.message 
    });
  }
});

/**
 * GET /api/urshies
 * Get all urshies with optional filtering and pagination
 * Query params: page, limit, search, tag, sort
 */
router.get('/', (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const search = req.query.search || '';
    const tag = req.query.tag || '';
    const sort = req.query.sort || 'created_at';
    const order = req.query.order || 'DESC';
    
    const offset = (page - 1) * limit;
    
    let query = `
      SELECT u.*, 
             COALESCE(s.submission_count, 0) as submission_count,
             COALESCE(s.last_submitted, u.created_at) as last_submitted
      FROM urshies u
      LEFT JOIN (
        SELECT urshie_id, COUNT(*) as submission_count, MAX(created_at) as last_submitted
        FROM submissions
        GROUP BY urshie_id
      ) s ON u.id = s.urshie_id
      WHERE 1=1
    `;
    
    const params = [];
    
    if (search) {
      query += ` AND (u.name LIKE ? OR u.description LIKE ? OR u.script_url LIKE ?)`;
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }
    
    if (tag) {
      query += ` AND u.id IN (SELECT urshie_id FROM urshie_tags WHERE tag = ?)`;
      params.push(tag);
    }
    
    // Validate sort column
    const validSorts = ['name', 'created_at', 'updated_at', 'submission_count'];
    const sortColumn = validSorts.includes(sort) ? sort : 'created_at';
    const sortOrder = order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';
    
    query += ` ORDER BY ${sortColumn} ${sortOrder}`;
    query += ` LIMIT ? OFFSET ?`;
    params.push(limit, offset);
    
    // Get total count
    let countQuery = `SELECT COUNT(*) as total FROM urshies WHERE 1=1`;
    const countParams = [];
    
    if (search) {
      countQuery += ` AND (name LIKE ? OR description LIKE ? OR script_url LIKE ?)`;
      countParams.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }
    
    if (tag) {
      countQuery += ` AND id IN (SELECT urshie_id FROM urshie_tags WHERE tag = ?)`;
      countParams.push(tag);
    }
    
    const urshies = db.prepare(query).all(...params);
    const totalResult = db.prepare(countQuery).get(...countParams);
    const total = totalResult.total;
    
    // Get tags for each urshie
    const urshiesWithTags = urshies.map(urshie => {
      const tags = db.prepare('SELECT tag FROM urshie_tags WHERE urshie_id = ?').all(urshie.id);
      return {
        ...urshie,
        tags: tags.map(t => t.tag)
      };
    });
    
    res.json({
      data: urshiesWithTags,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching urshies:', error);
    res.status(500).json({ error: 'Failed to fetch urshies' });
  }
});

/**
 * GET /api/urshies/tags
 * Get all unique tags
 */
router.get('/tags', (req, res) => {
  try {
    const tags = db.prepare(`
      SELECT tag, COUNT(*) as count
      FROM urshie_tags
      GROUP BY tag
      ORDER BY count DESC
    `).all();

    res.json(tags);
  } catch (error) {
    console.error('Error fetching tags:', error);
    res.status(500).json({ error: 'Failed to fetch tags' });
  }
});

/**
 * GET /api/urshies/:id
 * Get a single urshie by ID
 */
router.get('/:id', (req, res) => {
  try {
    const urshie = db.prepare('SELECT * FROM urshies WHERE id = ?').get(req.params.id);
    
    if (!urshie) {
      return res.status(404).json({ error: 'Urshie not found' });
    }
    
    const tags = db.prepare('SELECT tag FROM urshie_tags WHERE urshie_id = ?').all(urshie.id);
    const submissions = db.prepare(`
      SELECT s.*, u.username as submitted_by_username
      FROM submissions s
      JOIN users u ON s.user_id = u.id
      WHERE s.urshie_id = ?
      ORDER BY s.created_at DESC
    `).all(urshie.id);
    
    res.json({
      ...urshie,
      tags: tags.map(t => t.tag),
      submissions: submissions.map(s => ({
        id: s.id,
        scriptUrl: s.script_url,
        homepageUrl: s.homepage_url,
        submittedBy: s.submitted_by_username,
        submittedAt: s.created_at,
        status: s.status
      }))
    });
  } catch (error) {
    console.error('Error fetching urshie:', error);
    res.status(500).json({ error: 'Failed to fetch urshie' });
  }
});

/**
 * POST /api/urshies
 * Create a new urshie (no auth required - anonymous submissions allowed)
 */
router.post('/', submitUrshieRules, handleValidationErrors, (req, res) => {
  try {
    const { name, description, scriptUrl, homepageUrl, author, tags = [] } = req.body;

    // Check for duplicates
    const existing = db.prepare('SELECT id FROM urshies WHERE name = ? OR script_url = ?').get(name, scriptUrl);
    if (existing) {
      return res.status(409).json({
        error: 'Urshie already exists',
        message: 'An urshie with this name or script URL already exists'
      });
    }

    // Insert urshie - use author or 'anonymous'
    const insert = db.prepare(`
      INSERT INTO urshies (name, description, script_url, homepage_url, created_by, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, datetime('now'), datetime('now'))
    `);

    const createdBy = author || 'anonymous';
    const result = insert.run(name, description || null, scriptUrl, homepageUrl || null, createdBy);
    const urshieId = result.lastInsertRowid;

    // Insert tags
    if (tags.length > 0) {
      const tagInsert = db.prepare('INSERT INTO urshie_tags (urshie_id, tag) VALUES (?, ?)');
      const insertTags = db.transaction((urshieId, tags) => {
        for (const tag of tags) {
          tagInsert.run(urshieId, tag);
        }
      });
      insertTags(urshieId, tags);
    }

    // Create initial submission - mark as needs_review if anonymous
    const needsReview = !author ? 1 : 0;
    const submissionInsert = db.prepare(`
      INSERT INTO submissions (urshie_id, script_url, homepage_url, status, needs_review, created_at)
      VALUES (?, ?, ?, ?, ?, datetime('now'))
    `);
    submissionInsert.run(urshieId, scriptUrl, homepageUrl || null, needsReview ? 'pending' : 'approved', needsReview);

    res.status(201).json({
      id: urshieId,
      name,
      description,
      scriptUrl,
      homepageUrl,
      tags,
      message: 'Urshie created successfully'
    });
  } catch (error) {
    console.error('Error creating urshie:', error);
    res.status(500).json({ error: 'Failed to create urshie' });
  }
});

/**
 * PUT /api/urshies/:id
 * Update an existing urshie (requires authentication and ownership)
 */
router.put('/:id', isAuthenticated, updateUrshieRules, handleValidationErrors, (req, res) => {
  try {
    const urshie = db.prepare('SELECT * FROM urshies WHERE id = ?').get(req.params.id);
    
    if (!urshie) {
      return res.status(404).json({ error: 'Urshie not found' });
    }
    
    // Check ownership (or admin - admin check not implemented yet)
    if (urshie.created_by !== req.user.username) {
      return res.status(403).json({ error: 'Not authorized to update this urshie' });
    }
    
    const { name, description, scriptUrl, homepageUrl, tags } = req.body;
    
    // Update urshie
    const updates = [];
    const params = [];
    
    if (name) {
      updates.push('name = ?');
      params.push(name);
    }
    if (description !== undefined) {
      updates.push('description = ?');
      params.push(description);
    }
    if (scriptUrl) {
      updates.push('script_url = ?');
      params.push(scriptUrl);
    }
    if (homepageUrl !== undefined) {
      updates.push('homepage_url = ?');
      params.push(homepageUrl);
    }
    
    if (updates.length > 0) {
      updates.push('updated_at = datetime("now")');
      params.push(req.params.id);
      
      const updateQuery = `UPDATE urshies SET ${updates.join(', ')} WHERE id = ?`;
      db.prepare(updateQuery).run(...params);
    }
    
    // Update tags if provided
    if (tags) {
      db.prepare('DELETE FROM urshie_tags WHERE urshie_id = ?').run(req.params.id);
      if (tags.length > 0) {
        const tagInsert = db.prepare('INSERT INTO urshie_tags (urshie_id, tag) VALUES (?, ?)');
        for (const tag of tags) {
          tagInsert.run(req.params.id, tag);
        }
      }
    }
    
    res.json({ message: 'Urshie updated successfully' });
  } catch (error) {
    console.error('Error updating urshie:', error);
    res.status(500).json({ error: 'Failed to update urshie' });
  }
});

/**
 * DELETE /api/urshies/:id
 * Delete an urshie (requires authentication and ownership)
 */
router.delete('/:id', isAuthenticated, (req, res) => {
  try {
    const urshie = db.prepare('SELECT * FROM urshies WHERE id = ?').get(req.params.id);
    
    if (!urshie) {
      return res.status(404).json({ error: 'Urshie not found' });
    }
    
    // Check ownership
    if (urshie.created_by !== req.user.username) {
      return res.status(403).json({ error: 'Not authorized to delete this urshie' });
    }
    
    // Delete tags and submissions first (foreign keys should handle this, but being explicit)
    db.prepare('DELETE FROM urshie_tags WHERE urshie_id = ?').run(req.params.id);
    db.prepare('DELETE FROM submissions WHERE urshie_id = ?').run(req.params.id);
    db.prepare('DELETE FROM urshies WHERE id = ?').run(req.params.id);
    
    res.json({ message: 'Urshie deleted successfully' });
  } catch (error) {
    console.error('Error deleting urshie:', error);
    res.status(500).json({ error: 'Failed to delete urshie' });
  }
});

module.exports = router;
