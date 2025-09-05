const express = require('express');
const Questionnaire = require('../models/Questionnaire');
const QuestionnaireResponse = require('../models/QuestionnaireResponse');
const { validateQuestionnaire } = require('../middleware/validation');
const { authorize } = require('../middleware/auth');

const router = express.Router();

// @desc    Get all questionnaires
// @route   GET /api/questionnaires
// @access  Private
router.get('/', async (req, res, next) => {
  try {
    const {
      category,
      type,
      status = 'active',
      page = 1,
      limit = 10,
      search
    } = req.query;

    const query = {
      status: status,
      $or: [
        { 'access.public': true },
        { createdBy: req.user.id }
      ]
    };

    if (category) {
      query.category = category;
    }

    if (type) {
      query.type = type;
    }

    if (search) {
      query.$text = { $search: search };
    }

    const questionnaires = await Questionnaire.find(query)
      .populate('createdBy', 'firstName lastName')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    // Filter questionnaires based on user access
    const accessibleQuestionnaires = questionnaires.filter(q => 
      q.canUserAccess(req.user)
    );

    const total = await Questionnaire.countDocuments(query);

    res.status(200).json({
      success: true,
      count: accessibleQuestionnaires.length,
      total,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      },
      questionnaires: accessibleQuestionnaires
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Get single questionnaire
// @route   GET /api/questionnaires/:id
// @access  Private
router.get('/:id', async (req, res, next) => {
  try {
    const questionnaire = await Questionnaire.findById(req.params.id)
      .populate('createdBy', 'firstName lastName');

    if (!questionnaire) {
      return res.status(404).json({
        success: false,
        message: 'Questionnaire not found'
      });
    }

    // Check if user can access this questionnaire
    if (!questionnaire.canUserAccess(req.user)) {
      return res.status(403).json({
        success: false,
        message: 'Access denied to this questionnaire'
      });
    }

    res.status(200).json({
      success: true,
      questionnaire
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Create questionnaire
// @route   POST /api/questionnaires
// @access  Private (Admin only for now)
router.post('/', authorize('admin', 'therapist'), validateQuestionnaire, async (req, res, next) => {
  try {
    const questionnaireData = {
      ...req.body,
      createdBy: req.user.id
    };

    const questionnaire = await Questionnaire.create(questionnaireData);

    res.status(201).json({
      success: true,
      questionnaire
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Update questionnaire
// @route   PUT /api/questionnaires/:id
// @access  Private (Creator or Admin only)
router.put('/:id', async (req, res, next) => {
  try {
    let questionnaire = await Questionnaire.findById(req.params.id);

    if (!questionnaire) {
      return res.status(404).json({
        success: false,
        message: 'Questionnaire not found'
      });
    }

    // Check if user can edit this questionnaire
    if (questionnaire.createdBy.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this questionnaire'
      });
    }

    // Create version backup before updating
    questionnaire.previousVersions.push({
      version: questionnaire.version,
      data: questionnaire.toObject(),
      createdAt: questionnaire.updatedAt,
      createdBy: questionnaire.lastModifiedBy || questionnaire.createdBy
    });

    // Update questionnaire
    questionnaire = await Questionnaire.findByIdAndUpdate(
      req.params.id,
      {
        ...req.body,
        version: questionnaire.version + 1,
        lastModifiedBy: req.user.id
      },
      {
        new: true,
        runValidators: true
      }
    );

    res.status(200).json({
      success: true,
      questionnaire
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Delete questionnaire
// @route   DELETE /api/questionnaires/:id
// @access  Private (Creator or Admin only)
router.delete('/:id', async (req, res, next) => {
  try {
    const questionnaire = await Questionnaire.findById(req.params.id);

    if (!questionnaire) {
      return res.status(404).json({
        success: false,
        message: 'Questionnaire not found'
      });
    }

    // Check if user can delete this questionnaire
    if (questionnaire.createdBy.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this questionnaire'
      });
    }

    // Soft delete by changing status
    questionnaire.status = 'archived';
    await questionnaire.save();

    res.status(200).json({
      success: true,
      message: 'Questionnaire archived successfully'
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Start questionnaire response
// @route   POST /api/questionnaires/:id/start
// @access  Private
router.post('/:id/start', async (req, res, next) => {
  try {
    const questionnaire = await Questionnaire.findById(req.params.id);

    if (!questionnaire || questionnaire.status !== 'active') {
      return res.status(404).json({
        success: false,
        message: 'Questionnaire not found or inactive'
      });
    }

    // Check if user can access this questionnaire
    if (!questionnaire.canUserAccess(req.user)) {
      return res.status(403).json({
        success: false,
        message: 'Access denied to this questionnaire'
      });
    }

    // Check if user already has an in-progress response
    const existingResponse = await QuestionnaireResponse.findOne({
      questionnaire: questionnaire._id,
      user: req.user.id,
      status: 'in-progress'
    });

    if (existingResponse) {
      return res.status(200).json({
        success: true,
        message: 'Questionnaire already in progress',
        responseId: existingResponse._id,
        currentQuestion: existingResponse.progress.currentQuestionId || questionnaire.questions[0]?.id
      });
    }

    // Create new response
    const response = await QuestionnaireResponse.create({
      questionnaire: questionnaire._id,
      user: req.user.id,
      progress: {
        currentQuestionId: questionnaire.questions[0]?.id,
        totalQuestions: questionnaire.questions.length
      }
    });

    res.status(201).json({
      success: true,
      message: 'Questionnaire started successfully',
      responseId: response._id,
      firstQuestion: questionnaire.questions[0]
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Submit answer to questionnaire
// @route   POST /api/questionnaires/:id/answer
// @access  Private
router.post('/:id/answer', async (req, res, next) => {
  try {
    const { responseId, questionId, answer } = req.body;

    const response = await QuestionnaireResponse.findOne({
      _id: responseId,
      user: req.user.id,
      questionnaire: req.params.id
    });

    if (!response) {
      return res.status(404).json({
        success: false,
        message: 'Questionnaire response not found'
      });
    }

    if (response.status !== 'in-progress') {
      return res.status(400).json({
        success: false,
        message: 'Questionnaire is not in progress'
      });
    }

    const questionnaire = await Questionnaire.findById(req.params.id);

    // Save answer
    response.responses.set(questionId, answer);

    // Update progress
    response.updateProgress(questionnaire.questions.length);

    // Get next question based on dynamic logic
    let nextQuestion = null;
    if (questionnaire.type === 'dynamic') {
      nextQuestion = questionnaire.getNextQuestion(questionId, Object.fromEntries(response.responses));
    } else {
      const currentIndex = questionnaire.questions.findIndex(q => q.id === questionId);
      nextQuestion = questionnaire.questions[currentIndex + 1] || null;
    }

    if (nextQuestion) {
      response.progress.currentQuestionId = nextQuestion.id;
    } else {
      // No more questions, mark as completed
      response.markCompleted();
      
      // Calculate scoring if enabled
      if (questionnaire.scoring.enabled) {
        let totalScore = 0;
        for (let [qId, answer] of response.responses) {
          const question = questionnaire.questions.find(q => q.id === qId);
          if (question && question.options) {
            const option = question.options.find(opt => opt.value === answer);
            if (option && option.score !== undefined) {
              totalScore += option.score;
            }
          }
        }
        response.scoring.totalScore = totalScore;
        
        // Find interpretation range
        const range = questionnaire.scoring.ranges.find(r => 
          totalScore >= r.min && totalScore <= r.max
        );
        if (range) {
          response.scoring.interpretation = {
            level: range.label,
            description: range.description,
            recommendations: range.recommendations
          };
        }
      }

      // Update questionnaire analytics
      questionnaire.analytics.totalResponses += 1;
      questionnaire.analytics.lastResponseAt = new Date();
      await questionnaire.save();
    }

    await response.save();

    res.status(200).json({
      success: true,
      nextQuestion,
      progress: response.progress,
      isCompleted: response.status === 'completed',
      scoring: response.status === 'completed' ? response.scoring : null
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Get questionnaire response
// @route   GET /api/questionnaires/:id/responses/:responseId
// @access  Private
router.get('/:id/responses/:responseId', async (req, res, next) => {
  try {
    const response = await QuestionnaireResponse.findOne({
      _id: req.params.responseId,
      user: req.user.id,
      questionnaire: req.params.id
    }).populate('questionnaire', 'title description');

    if (!response) {
      return res.status(404).json({
        success: false,
        message: 'Questionnaire response not found'
      });
    }

    res.status(200).json({
      success: true,
      response
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Get user's questionnaire responses
// @route   GET /api/questionnaires/responses/my
// @access  Private
router.get('/responses/my', async (req, res, next) => {
  try {
    const { status, page = 1, limit = 10 } = req.query;
    
    const query = { user: req.user.id };
    if (status) {
      query.status = status;
    }

    const responses = await QuestionnaireResponse.find(query)
      .populate('questionnaire', 'title description category')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await QuestionnaireResponse.countDocuments(query);

    res.status(200).json({
      success: true,
      count: responses.length,
      total,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      },
      responses
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Get questionnaire analytics
// @route   GET /api/questionnaires/:id/analytics
// @access  Private (Creator or Admin only)
router.get('/:id/analytics', async (req, res, next) => {
  try {
    const questionnaire = await Questionnaire.findById(req.params.id);

    if (!questionnaire) {
      return res.status(404).json({
        success: false,
        message: 'Questionnaire not found'
      });
    }

    // Check if user can view analytics
    if (questionnaire.createdBy.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to view analytics'
      });
    }

    // Get detailed analytics
    const responses = await QuestionnaireResponse.find({
      questionnaire: questionnaire._id,
      status: 'completed'
    });

    const analytics = {
      ...questionnaire.analytics.toObject(),
      responseDetails: {
        byStatus: await QuestionnaireResponse.aggregate([
          { $match: { questionnaire: questionnaire._id } },
          { $group: { _id: '$status', count: { $sum: 1 } } }
        ]),
        averageCompletionTime: responses.reduce((sum, r) => sum + (r.responseTime || 0), 0) / responses.length,
        scoreDistribution: responses
          .filter(r => r.scoring && r.scoring.totalScore !== undefined)
          .map(r => r.scoring.totalScore)
      }
    };

    res.status(200).json({
      success: true,
      analytics
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
