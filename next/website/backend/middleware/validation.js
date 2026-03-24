const { body, validationResult } = require('express-validator');

/**
 * Validation rules for urshie submission
 */
exports.submitUrshieRules = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  
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
  
  body('description')
    .trim()
    .optional({ checkFalsy: true })
    .isLength({ max: 500 })
    .withMessage('Description must be less than 500 characters'),
  
  body('tags')
    .optional({ checkFalsy: true })
    .isArray()
    .withMessage('Tags must be an array'),

  body('tags.*')
    .trim()
    .isLength({ max: 30 })
    .withMessage('Each tag must be less than 30 characters'),

  body('author')
    .trim()
    .optional({ checkFalsy: true })
    .isLength({ max: 50 })
    .withMessage('Author must be less than 50 characters')
];

/**
 * Validation rules for urshie update
 */
exports.updateUrshieRules = [
  body('name')
    .trim()
    .optional({ checkFalsy: true })
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  
  body('scriptUrl')
    .trim()
    .optional({ checkFalsy: true })
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
  
  body('description')
    .trim()
    .optional({ checkFalsy: true })
    .isLength({ max: 500 })
    .withMessage('Description must be less than 500 characters'),
  
  body('tags')
    .optional({ checkFalsy: true })
    .isArray()
    .withMessage('Tags must be an array'),
  
  body('tags.*')
    .trim()
    .isLength({ max: 30 })
    .withMessage('Each tag must be less than 30 characters')
];

/**
 * Middleware to handle validation errors
 */
exports.handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ 
      error: 'Validation failed',
      details: errors.array()
    });
  }
  next();
};
