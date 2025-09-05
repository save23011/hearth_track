const { check, validationResult } = require('express-validator');

// Generic validation result handler
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map(error => ({
      field: error.param,
      message: error.msg,
      value: error.value
    }));
    
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: formattedErrors
    });
  }
  next();
};

// User registration validation
const validateRegister = [
  check('firstName')
    .notEmpty()
    .withMessage('First name is required')
    .isLength({ min: 2, max: 50 })
    .withMessage('First name must be between 2 and 50 characters')
    .trim(),
  
  check('lastName')
    .notEmpty()
    .withMessage('Last name is required')
    .isLength({ min: 2, max: 50 })
    .withMessage('Last name must be between 2 and 50 characters')
    .trim(),
  
  check('email')
    .isEmail()
    .withMessage('Please provide a valid email')
    .normalizeEmail(),
  
  check('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, and one number'),
  
  check('phone.number')
    .optional()
    .isMobilePhone()
    .withMessage('Please provide a valid phone number'),
  
  handleValidationErrors
];

// User login validation
const validateLogin = [
  check('email')
    .isEmail()
    .withMessage('Please provide a valid email')
    .normalizeEmail(),
  
  check('password')
    .notEmpty()
    .withMessage('Password is required'),
  
  handleValidationErrors
];

// Phone verification validation
const validatePhoneVerification = [
  check('phone')
    .isMobilePhone()
    .withMessage('Please provide a valid phone number'),
  
  check('code')
    .optional()
    .isLength({ min: 4, max: 6 })
    .withMessage('Verification code must be 4-6 digits')
    .isNumeric()
    .withMessage('Verification code must contain only numbers'),
  
  handleValidationErrors
];

// Password reset validation
const validatePasswordReset = [
  check('email')
    .isEmail()
    .withMessage('Please provide a valid email')
    .normalizeEmail(),
  
  handleValidationErrors
];

// New password validation
const validateNewPassword = [
  check('token')
    .notEmpty()
    .withMessage('Reset token is required'),
  
  check('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, and one number'),
  
  handleValidationErrors
];

// User profile update validation
const validateProfileUpdate = [
  check('firstName')
    .optional()
    .isLength({ min: 2, max: 50 })
    .withMessage('First name must be between 2 and 50 characters')
    .trim(),
  
  check('lastName')
    .optional()
    .isLength({ min: 2, max: 50 })
    .withMessage('Last name must be between 2 and 50 characters')
    .trim(),
  
  check('dateOfBirth')
    .optional()
    .isISO8601()
    .withMessage('Please provide a valid date')
    .custom((value) => {
      const birthDate = new Date(value);
      const today = new Date();
      const age = today.getFullYear() - birthDate.getFullYear();
      
      if (age < 13 || age > 120) {
        throw new Error('Age must be between 13 and 120 years');
      }
      return true;
    }),
  
  check('gender')
    .optional()
    .isIn(['male', 'female', 'other', 'prefer-not-to-say'])
    .withMessage('Invalid gender value'),
  
  handleValidationErrors
];

// Questionnaire creation validation
const validateQuestionnaire = [
  check('title')
    .notEmpty()
    .withMessage('Title is required')
    .isLength({ max: 200 })
    .withMessage('Title cannot exceed 200 characters')
    .trim(),
  
  check('description')
    .optional()
    .isLength({ max: 1000 })
    .withMessage('Description cannot exceed 1000 characters')
    .trim(),
  
  check('category')
    .notEmpty()
    .withMessage('Category is required')
    .isIn(['mental-health', 'physical-health', 'lifestyle', 'goals', 'assessment', 'therapy', 'ai-training'])
    .withMessage('Invalid category'),
  
  check('type')
    .notEmpty()
    .withMessage('Type is required')
    .isIn(['dynamic', 'static', 'adaptive'])
    .withMessage('Invalid type'),
  
  check('questions')
    .isArray({ min: 1 })
    .withMessage('At least one question is required'),
  
  check('questions.*.text')
    .notEmpty()
    .withMessage('Question text is required')
    .isLength({ max: 500 })
    .withMessage('Question text cannot exceed 500 characters'),
  
  check('questions.*.type')
    .isIn(['multiple-choice', 'single-choice', 'text', 'number', 'scale', 'boolean', 'date', 'time', 'file-upload', 'voice-recording'])
    .withMessage('Invalid question type'),
  
  handleValidationErrors
];

// Exercise creation validation
const validateExercise = [
  check('title')
    .notEmpty()
    .withMessage('Title is required')
    .isLength({ max: 200 })
    .withMessage('Title cannot exceed 200 characters')
    .trim(),
  
  check('description')
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ max: 2000 })
    .withMessage('Description cannot exceed 2000 characters')
    .trim(),
  
  check('category')
    .notEmpty()
    .withMessage('Category is required')
    .isIn(['breathing', 'meditation', 'mindfulness', 'physical', 'cognitive', 'relaxation', 'grounding', 'visualization', 'journaling', 'movement'])
    .withMessage('Invalid category'),
  
  check('difficulty')
    .notEmpty()
    .withMessage('Difficulty is required')
    .isIn(['beginner', 'intermediate', 'advanced'])
    .withMessage('Invalid difficulty level'),
  
  check('duration.estimated')
    .isInt({ min: 1, max: 300 })
    .withMessage('Estimated duration must be between 1 and 300 minutes'),
  
  handleValidationErrors
];

// Therapy session validation
const validateTherapySession = [
  check('title')
    .notEmpty()
    .withMessage('Title is required')
    .isLength({ max: 200 })
    .withMessage('Title cannot exceed 200 characters')
    .trim(),
  
  check('type')
    .notEmpty()
    .withMessage('Type is required')
    .isIn(['individual', 'group', 'ai-guided', 'self-paced'])
    .withMessage('Invalid session type'),
  
  check('scheduledFor')
    .optional()
    .isISO8601()
    .withMessage('Please provide a valid date')
    .custom((value) => {
      const sessionDate = new Date(value);
      const now = new Date();
      
      if (sessionDate <= now) {
        throw new Error('Session must be scheduled for a future date');
      }
      return true;
    }),
  
  check('duration')
    .optional()
    .isInt({ min: 15, max: 180 })
    .withMessage('Duration must be between 15 and 180 minutes'),
  
  handleValidationErrors
];

// Journal entry validation
const validateJournalEntry = [
  check('title')
    .optional()
    .isLength({ max: 200 })
    .withMessage('Title cannot exceed 200 characters')
    .trim(),
  
  check('content')
    .optional()
    .isLength({ max: 10000 })
    .withMessage('Content cannot exceed 10000 characters'),
  
  check('mood')
    .optional()
    .isInt({ min: 1, max: 10 })
    .withMessage('Mood must be between 1 and 10'),
  
  check('tags')
    .optional()
    .isArray()
    .withMessage('Tags must be an array'),
  
  handleValidationErrors
];

module.exports = {
  validateRegister,
  validateLogin,
  validatePhoneVerification,
  validatePasswordReset,
  validateNewPassword,
  validateProfileUpdate,
  validateQuestionnaire,
  validateExercise,
  validateTherapySession,
  validateJournalEntry,
  handleValidationErrors
};
