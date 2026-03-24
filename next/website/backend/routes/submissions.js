const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { isAuthenticated } = require('../middleware/auth');
const { handleValidationErrors } = require('../middleware/validation');
const { body } = require('express-validator');

/**
 * Validation rules for submission
 */
const submissionRules = [
  body('scriptUrl')
    .trim()
    .notEmpty()
    .withMessage('Script URL is required')
    .isURL()
    .withMessage('Script URL must be a valid URL')
    .matches(/^https:\/\//)
    .withMessage('Script URL must use HTTPS'),
  
  body('homepageUrl')
    .trim()
    .optional({ checkFalsy: true })
    .isURL()
    .withMessage('Homepage URL must be a valid URL')
    .matches(/^https:\/\//)
    .withMessage('Homepage URL must use HTTPS'),
  
  body('notes')
    .trim()
    .optional({ checkFalsy: true })
    .isLength({ max: 1000 })
    .withMessage('Notes must be less than 1000 characters')
];

/**
 * POST /api/submissions
 * Submit a new urshie instance (requires authentication)
 */
router.post('/', isAuthenticated, submissionRules, handleValidationErrors, (req, res) => {
  try {
    const { scriptUrl, homepageUrl, notes, urshieId } = req.body;
    
    // Check if this script URL already exists for this urshie
    const existing = db.prepare(`
      SELECT id FROM submissions 
      WHERE script_url = ? AND urshie_id = ?
    `).get(scriptUrl, urshieId);
    
    if (existing) {
      return res.status(409).json({ 
        error: 'Duplicate submission',
        message: 'This script URL has already been submitted for this urshie'
      });
    }
    
    // Verify urshie exists
    const urshie = db.prepare('SELECT id FROM urshies WHERE id = ?').get(urshieId);
    if (!urshie) {
      return res.status(404).json({ error: 'Urshie not found' });
    }
    
    // Check for domain mismatch (flag for review)
    let status = 'pending';
    let needsReview = false;
    
    try {
      const scriptUrlObj = new URL(scriptUrl);
      const homepageUrlObj = homepageUrl ? new URL(homepageUrl) : null;
      
      // Extract domain and path components
      const scriptDomain = scriptUrlObj.hostname;
      const scriptPath = scriptUrlObj.pathname;
      
      if (homepageUrlObj) {
        const homepageDomain = homepageUrlObj.hostname;
        const homepagePath = homepageUrlObj.pathname;
        
        // Check if domains match
        if (scriptDomain !== homepageDomain) {
          needsReview = true;
          status = 'needs_review';
        } else {
          // Check if paths suggest same project
          const scriptUser = scriptPath.split('/')[1];
          const homepageUser = homepagePath.split('/')[1];
          
          if (scriptUser && homepageUser && scriptUser !== homepageUser) {
            needsReview = true;
            status = 'needs_review';
          }
        }
      }
    } catch (e) {
      // URL parsing failed, flag for review
      needsReview = true;
      status = 'needs_review';
    }
    
    // Insert submission
    const insert = db.prepare(`
      INSERT INTO submissions (urshie_id, user_id, script_url, homepage_url, notes, status, needs_review, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
    `);
    
    const result = insert.run(urshieId, req.user.id, scriptUrl, homepageUrl || null, notes || null, status, needsReview ? 1 : 0);
    
    res.status(201).json({
      id: result.lastInsertRowid,
      urshieId,
      scriptUrl,
      homepageUrl,
      status,
      needsReview,
      message: 'Submission created successfully' + (needsReview ? ' - flagged for review due to domain mismatch' : '')
    });
  } catch (error) {
    console.error('Error creating submission:', error);
    res.status(500).json({ error: 'Failed to create submission' });
  }
});

/**
 * GET /api/submissions
 * Get submissions with filtering (admin only or user's own)
 */
router.get('/', isAuthenticated, (req, res) => {
  try {
    const status = req.query.status || '';
    const needsReview = req.query.needsReview;
    
    let query = `
      SELECT s.*, u.name as urshie_name, ur.username as submitted_by_username
      FROM submissions s
      JOIN urshies u ON s.urshie_id = u.id
      JOIN users ur ON s.user_id = ur.id
      WHERE 1=1
    `;
    
    const params = [];
    
    // Regular users can only see their own submissions
    if (!req.user.isAdmin) {
      query += ` AND s.user_id = ?`;
      params.push(req.user.id);
    }
    
    if (status) {
      query += ` AND s.status = ?`;
      params.push(status);
    }
    
    if (needsReview !== undefined) {
      query += ` AND s.needs_review = ?`;
      params.push(needsReview === 'true' ? 1 : 0);
    }
    
    query += ` ORDER BY s.created_at DESC LIMIT 50`;
    
    const submissions = db.prepare(query).all(...params);
    
    res.json(submissions.map(s => ({
      id: s.id,
      urshieId: s.urshie_id,
      urshieName: s.urshie_name,
      scriptUrl: s.script_url,
      homepageUrl: s.homepage_url,
      notes: s.notes,
      status: s.status,
      needsReview: s.needs_review === 1,
      submittedBy: s.submitted_by_username,
      createdAt: s.created_at
    })));
  } catch (error) {
    console.error('Error fetching submissions:', error);
    res.status(500).json({ error: 'Failed to fetch submissions' });
  }
});

/**
 * GET /api/submissions/:id
 * Get a single submission
 */
router.get('/:id', isAuthenticated, (req, res) => {
  try {
    const submission = db.prepare(`
      SELECT s.*, u.name as urshie_name, ur.username as submitted_by_username
      FROM submissions s
      JOIN urshies u ON s.urshie_id = u.id
      JOIN users ur ON s.user_id = ur.id
      WHERE s.id = ?
    `).get(req.params.id);
    
    if (!submission) {
      return res.status(404).json({ error: 'Submission not found' });
    }
    
    // Check access
    if (!req.user.isAdmin && submission.user_id !== req.user.id) {
      return res.status(403).json({ error: 'Not authorized to view this submission' });
    }
    
    res.json({
      id: submission.id,
      urshieId: submission.urshie_id,
      urshieName: submission.urshie_name,
      scriptUrl: submission.script_url,
      homepageUrl: submission.homepage_url,
      notes: submission.notes,
      status: submission.status,
      needsReview: submission.needs_review === 1,
      submittedBy: submission.submitted_by_username,
      createdAt: submission.created_at
    });
  } catch (error) {
    console.error('Error fetching submission:', error);
    res.status(500).json({ error: 'Failed to fetch submission' });
  }
});

/**
 * PUT /api/submissions/:id/status
 * Update submission status (admin only)
 */
router.put('/:id/status', isAuthenticated, (req, res) => {
  try {
    // In a real app, check for admin here
    const { status, reviewNotes } = req.body;
    
    const validStatuses = ['pending', 'approved', 'rejected', 'needs_review'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }
    
    const update = db.prepare(`
      UPDATE submissions 
      SET status = ?, review_notes = ?, updated_at = datetime('now')
      WHERE id = ?
    `);
    
    update.run(status, reviewNotes || null, req.params.id);
    
    res.json({ message: 'Submission status updated' });
  } catch (error) {
    console.error('Error updating submission:', error);
    res.status(500).json({ error: 'Failed to update submission' });
  }
});

/**
 * DELETE /api/submissions/:id
 * Delete a submission
 */
router.delete('/:id', isAuthenticated, (req, res) => {
  try {
    const submission = db.prepare('SELECT * FROM submissions WHERE id = ?').get(req.params.id);
    
    if (!submission) {
      return res.status(404).json({ error: 'Submission not found' });
    }
    
    // Check ownership or admin
    if (!req.user.isAdmin && submission.user_id !== req.user.id) {
      return res.status(403).json({ error: 'Not authorized to delete this submission' });
    }
    
    db.prepare('DELETE FROM submissions WHERE id = ?').run(req.params.id);
    
    res.json({ message: 'Submission deleted successfully' });
  } catch (error) {
    console.error('Error deleting submission:', error);
    res.status(500).json({ error: 'Failed to delete submission' });
  }
});

module.exports = router;
