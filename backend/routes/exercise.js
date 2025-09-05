const express = require('express');
const Exercise = require('../models/Exercise');
const { validateExercise } = require('../middleware/validation');
const { authorize } = require('../middleware/auth');

const router = express.Router();

// @desc    Get all exercises
// @route   GET /api/exercises
// @access  Private
router.get('/', async (req, res, next) => {
  try {
    const {
      category,
      difficulty,
      duration,
      tags,
      search,
      page = 1,
      limit = 20,
      sort = '-analytics.popularityScore'
    } = req.query;

    const query = { status: 'published' };

    // Apply filters
    if (category) {
      query.category = category;
    }

    if (difficulty) {
      query.difficulty = difficulty;
    }

    if (duration) {
      const [min, max] = duration.split('-').map(Number);
      query['duration.estimated'] = {};
      if (min) query['duration.estimated'].$gte = min;
      if (max) query['duration.estimated'].$lte = max;
    }

    if (tags) {
      const tagArray = tags.split(',');
      query.tags = { $in: tagArray };
    }

    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { tags: { $regex: search, $options: 'i' } }
      ];
    }

    const exercises = await Exercise.find(query)
      .populate('createdBy', 'firstName lastName')
      .sort(sort)
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Exercise.countDocuments(query);

    res.status(200).json({
      success: true,
      count: exercises.length,
      total,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      },
      exercises
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Get single exercise
// @route   GET /api/exercises/:id
// @access  Private
router.get('/:id', async (req, res, next) => {
  try {
    const exercise = await Exercise.findById(req.params.id)
      .populate('createdBy', 'firstName lastName');

    if (!exercise) {
      return res.status(404).json({
        success: false,
        message: 'Exercise not found'
      });
    }

    if (exercise.status !== 'published' && exercise.createdBy._id.toString() !== req.user.id) {
      return res.status(404).json({
        success: false,
        message: 'Exercise not found'
      });
    }

    res.status(200).json({
      success: true,
      exercise
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Get recommended exercises for user
// @route   GET /api/exercises/recommendations
// @access  Private
router.get('/recommendations', async (req, res, next) => {
  try {
    const { limit = 10 } = req.query;
    
    // Get user profile for personalized recommendations
    const user = await User.findById(req.user.id);
    
    const recommendations = await Exercise.getRecommendedForUser(user, parseInt(limit));

    res.status(200).json({
      success: true,
      count: recommendations.length,
      exercises: recommendations
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Get daily exercise recommendations
// @route   GET /api/exercises/daily
// @access  Private
router.get('/daily', async (req, res, next) => {
  try {
    const today = new Date().toDateString();
    
    // This would typically be more sophisticated, considering user's history,
    // preferences, goals, and AI recommendations
    const dailyExercises = await Exercise.find({
      status: 'published',
      category: { $in: ['breathing', 'meditation', 'mindfulness'] }
    })
    .sort({ 'analytics.popularityScore': -1 })
    .limit(3);

    res.status(200).json({
      success: true,
      date: today,
      exercises: dailyExercises
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Create exercise
// @route   POST /api/exercises
// @access  Private (Admin/Therapist only)
router.post('/', authorize('admin', 'therapist'), validateExercise, async (req, res, next) => {
  try {
    const exerciseData = {
      ...req.body,
      createdBy: req.user.id
    };

    const exercise = await Exercise.create(exerciseData);

    res.status(201).json({
      success: true,
      exercise
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Update exercise
// @route   PUT /api/exercises/:id
// @access  Private (Creator or Admin only)
router.put('/:id', async (req, res, next) => {
  try {
    let exercise = await Exercise.findById(req.params.id);

    if (!exercise) {
      return res.status(404).json({
        success: false,
        message: 'Exercise not found'
      });
    }

    // Check if user can edit this exercise
    if (exercise.createdBy.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this exercise'
      });
    }

    exercise = await Exercise.findByIdAndUpdate(
      req.params.id,
      {
        ...req.body,
        lastModifiedBy: req.user.id
      },
      {
        new: true,
        runValidators: true
      }
    );

    res.status(200).json({
      success: true,
      exercise
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Delete exercise
// @route   DELETE /api/exercises/:id
// @access  Private (Creator or Admin only)
router.delete('/:id', async (req, res, next) => {
  try {
    const exercise = await Exercise.findById(req.params.id);

    if (!exercise) {
      return res.status(404).json({
        success: false,
        message: 'Exercise not found'
      });
    }

    // Check if user can delete this exercise
    if (exercise.createdBy.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this exercise'
      });
    }

    // Soft delete by changing status
    exercise.status = 'archived';
    await exercise.save();

    res.status(200).json({
      success: true,
      message: 'Exercise archived successfully'
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Record exercise completion
// @route   POST /api/exercises/:id/complete
// @access  Private
router.post('/:id/complete', async (req, res, next) => {
  try {
    const { rating, completionTime, notes } = req.body;
    
    const exercise = await Exercise.findById(req.params.id);

    if (!exercise) {
      return res.status(404).json({
        success: false,
        message: 'Exercise not found'
      });
    }

    // Update exercise analytics
    await exercise.updateAnalytics(rating, completionTime, true);

    // TODO: Record completion in user's exercise history
    // This would typically create an ExerciseCompletion record

    res.status(200).json({
      success: true,
      message: 'Exercise completion recorded',
      analytics: exercise.analytics
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Rate exercise
// @route   POST /api/exercises/:id/rate
// @access  Private
router.post('/:id/rate', async (req, res, next) => {
  try {
    const { rating, feedback } = req.body;
    
    if (rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5'
      });
    }

    const exercise = await Exercise.findById(req.params.id);

    if (!exercise) {
      return res.status(404).json({
        success: false,
        message: 'Exercise not found'
      });
    }

    // Update exercise analytics
    await exercise.updateAnalytics(rating);

    // TODO: Record user's rating and feedback
    // This would typically check if user already rated and update accordingly

    res.status(200).json({
      success: true,
      message: 'Rating submitted successfully',
      averageRating: exercise.analytics.averageRating
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Get exercise categories
// @route   GET /api/exercises/meta/categories
// @access  Private
router.get('/meta/categories', async (req, res, next) => {
  try {
    const categories = [
      { value: 'breathing', label: 'Breathing Exercises', description: 'Techniques to improve breathing and reduce stress' },
      { value: 'meditation', label: 'Meditation', description: 'Mindfulness and meditation practices' },
      { value: 'mindfulness', label: 'Mindfulness', description: 'Present-moment awareness exercises' },
      { value: 'physical', label: 'Physical', description: 'Movement and physical wellness exercises' },
      { value: 'cognitive', label: 'Cognitive', description: 'Mental exercises and cognitive techniques' },
      { value: 'relaxation', label: 'Relaxation', description: 'Techniques to promote relaxation and calm' },
      { value: 'grounding', label: 'Grounding', description: 'Exercises to feel more present and centered' },
      { value: 'visualization', label: 'Visualization', description: 'Guided imagery and visualization techniques' },
      { value: 'journaling', label: 'Journaling', description: 'Writing and reflection exercises' },
      { value: 'movement', label: 'Movement', description: 'Gentle movement and body awareness' }
    ];

    // Get exercise counts for each category
    const categoryCounts = await Exercise.aggregate([
      { $match: { status: 'published' } },
      { $group: { _id: '$category', count: { $sum: 1 } } }
    ]);

    const categoriesWithCounts = categories.map(cat => {
      const countData = categoryCounts.find(c => c._id === cat.value);
      return {
        ...cat,
        count: countData ? countData.count : 0
      };
    });

    res.status(200).json({
      success: true,
      categories: categoriesWithCounts
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Get exercise analytics
// @route   GET /api/exercises/:id/analytics
// @access  Private (Creator or Admin only)
router.get('/:id/analytics', async (req, res, next) => {
  try {
    const exercise = await Exercise.findById(req.params.id);

    if (!exercise) {
      return res.status(404).json({
        success: false,
        message: 'Exercise not found'
      });
    }

    // Check if user can view analytics
    if (exercise.createdBy.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to view analytics'
      });
    }

    res.status(200).json({
      success: true,
      analytics: exercise.analytics
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
