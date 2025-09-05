const express = require('express');
const AIModule = require('../models/AIModule');
const Questionnaire = require('../models/Questionnaire');
const QuestionnaireResponse = require('../models/QuestionnaireResponse');

const router = express.Router();

// @desc    Get user's AI module data
// @route   GET /api/ai/module
// @access  Private
router.get('/module', async (req, res, next) => {
  try {
    let aiModule = await AIModule.findOne({ user: req.user.id });
    
    if (!aiModule) {
      // Create new AI module for user
      aiModule = await AIModule.create({
        user: req.user.id,
        learningProfile: {
          style: { visual: 25, auditory: 25, kinesthetic: 25, reading: 25 },
          preferences: {
            sessionDuration: 30,
            difficulty: 'beginner',
            topics: [],
            goals: []
          }
        }
      });
    }

    res.status(200).json({
      success: true,
      aiModule
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Create concept map
// @route   POST /api/ai/concept-maps
// @access  Private
router.post('/concept-maps', async (req, res, next) => {
  try {
    const { title, topic, description, nodes, edges } = req.body;
    
    let aiModule = await AIModule.findOne({ user: req.user.id });
    if (!aiModule) {
      aiModule = await AIModule.create({ user: req.user.id });
    }

    const conceptMapData = {
      title,
      topic,
      description,
      nodes: nodes || [],
      edges: edges || []
    };

    const mapId = aiModule.addConceptMap(conceptMapData);
    await aiModule.save();

    res.status(201).json({
      success: true,
      message: 'Concept map created successfully',
      conceptMapId: mapId
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Update concept map
// @route   PUT /api/ai/concept-maps/:mapId
// @access  Private
router.put('/concept-maps/:mapId', async (req, res, next) => {
  try {
    const { mapId } = req.params;
    const updateData = req.body;
    
    const aiModule = await AIModule.findOne({ user: req.user.id });
    if (!aiModule) {
      return res.status(404).json({
        success: false,
        message: 'AI module not found'
      });
    }

    const updated = aiModule.updateConceptMap(mapId, updateData);
    
    if (!updated) {
      return res.status(404).json({
        success: false,
        message: 'Concept map not found'
      });
    }

    await aiModule.save();

    res.status(200).json({
      success: true,
      message: 'Concept map updated successfully'
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Get concept maps
// @route   GET /api/ai/concept-maps
// @access  Private
router.get('/concept-maps', async (req, res, next) => {
  try {
    const aiModule = await AIModule.findOne({ user: req.user.id });
    
    if (!aiModule) {
      return res.status(200).json({
        success: true,
        conceptMaps: []
      });
    }

    res.status(200).json({
      success: true,
      conceptMaps: aiModule.activeConceptMaps
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Analyze concept map
// @route   POST /api/ai/concept-maps/:mapId/analyze
// @access  Private
router.post('/concept-maps/:mapId/analyze', async (req, res, next) => {
  try {
    const { mapId } = req.params;
    const aiModule = await AIModule.findOne({ user: req.user.id });
    
    if (!aiModule) {
      return res.status(404).json({
        success: false,
        message: 'AI module not found'
      });
    }

    const conceptMap = aiModule.conceptMaps.id(mapId);
    if (!conceptMap) {
      return res.status(404).json({
        success: false,
        message: 'Concept map not found'
      });
    }

    // Perform analysis (this would integrate with actual AI service)
    const analysis = {
      complexity: conceptMap.nodes.length > 10 ? 'high' : conceptMap.nodes.length > 5 ? 'medium' : 'low',
      density: conceptMap.edges.length / Math.max(conceptMap.nodes.length, 1),
      centralNodes: conceptMap.nodes.slice(0, 3).map(node => node.id),
      clusters: [
        {
          id: 'cluster1',
          nodes: conceptMap.nodes.slice(0, Math.ceil(conceptMap.nodes.length / 2)).map(n => n.id),
          theme: 'Core concepts'
        }
      ],
      recommendations: [
        'Consider adding more connections between related concepts',
        'Explore sub-concepts for better understanding'
      ],
      gaps: ['Missing practical applications', 'Need more examples']
    };

    conceptMap.analysis = analysis;
    await aiModule.save();

    res.status(200).json({
      success: true,
      analysis
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Get AI recommendations
// @route   GET /api/ai/recommendations
// @access  Private
router.get('/recommendations', async (req, res, next) => {
  try {
    const aiModule = await AIModule.findOne({ user: req.user.id });
    
    if (!aiModule) {
      return res.status(200).json({
        success: true,
        recommendations: []
      });
    }

    res.status(200).json({
      success: true,
      recommendations: aiModule.pendingRecommendations
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Generate new recommendations
// @route   POST /api/ai/recommendations/generate
// @access  Private
router.post('/recommendations/generate', async (req, res, next) => {
  try {
    let aiModule = await AIModule.findOne({ user: req.user.id });
    
    if (!aiModule) {
      aiModule = await AIModule.create({ user: req.user.id });
    }

    const recommendations = await aiModule.generateRecommendations();
    await aiModule.save();

    res.status(200).json({
      success: true,
      recommendations
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Respond to recommendation
// @route   PUT /api/ai/recommendations/:recommendationId
// @access  Private
router.put('/recommendations/:recommendationId', async (req, res, next) => {
  try {
    const { recommendationId } = req.params;
    const { status, feedback } = req.body;
    
    const aiModule = await AIModule.findOne({ user: req.user.id });
    
    if (!aiModule) {
      return res.status(404).json({
        success: false,
        message: 'AI module not found'
      });
    }

    const recommendation = aiModule.recommendations.id(recommendationId);
    if (!recommendation) {
      return res.status(404).json({
        success: false,
        message: 'Recommendation not found'
      });
    }

    recommendation.status = status;
    if (feedback) {
      recommendation.feedback = feedback;
    }

    await aiModule.save();

    res.status(200).json({
      success: true,
      message: 'Recommendation updated successfully'
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Update learning profile
// @route   PUT /api/ai/learning-profile
// @access  Private
router.put('/learning-profile', async (req, res, next) => {
  try {
    const { style, preferences, cognitiveLoad } = req.body;
    
    let aiModule = await AIModule.findOne({ user: req.user.id });
    if (!aiModule) {
      aiModule = await AIModule.create({ user: req.user.id });
    }

    if (style) {
      Object.assign(aiModule.learningProfile.style, style);
    }
    
    if (preferences) {
      Object.assign(aiModule.learningProfile.preferences, preferences);
    }
    
    if (cognitiveLoad) {
      Object.assign(aiModule.learningProfile.cognitiveLoad, cognitiveLoad);
    }

    await aiModule.save();

    res.status(200).json({
      success: true,
      message: 'Learning profile updated successfully',
      learningProfile: aiModule.learningProfile
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Process questionnaire for AI insights
// @route   POST /api/ai/process-questionnaire
// @access  Private
router.post('/process-questionnaire', async (req, res, next) => {
  try {
    const { questionnaireResponseId } = req.body;
    
    const response = await QuestionnaireResponse.findById(questionnaireResponseId)
      .populate('questionnaire');
    
    if (!response || response.user.toString() !== req.user.id) {
      return res.status(404).json({
        success: false,
        message: 'Questionnaire response not found'
      });
    }

    let aiModule = await AIModule.findOne({ user: req.user.id });
    if (!aiModule) {
      aiModule = await AIModule.create({ user: req.user.id });
    }

    // Process questionnaire responses for AI insights
    const insights = [
      'Based on your responses, you show strong resilience patterns',
      'Consider focusing on stress management techniques',
      'Your social support network appears strong'
    ];

    // Add to AI module integrations
    aiModule.integrations.questionnaires.push({
      questionnaireId: response.questionnaire._id,
      responses: response._id,
      insights,
      updatedConceptMaps: []
    });

    // Update progress
    aiModule.updateProgress('assessment', { responseId: questionnaireResponseId });

    await aiModule.save();

    res.status(200).json({
      success: true,
      insights,
      message: 'Questionnaire processed successfully'
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Get AI analysis for user progress
// @route   GET /api/ai/analysis/progress
// @access  Private
router.get('/analysis/progress', async (req, res, next) => {
  try {
    const aiModule = await AIModule.findOne({ user: req.user.id });
    
    if (!aiModule) {
      return res.status(200).json({
        success: true,
        analysis: null
      });
    }

    const analysis = {
      overallProgress: {
        assessmentsCompleted: aiModule.progress.assessmentsCompleted,
        conceptMapsCreated: aiModule.progress.conceptMapsCreated,
        engagementTrend: 'improving', // Would calculate from actual data
        streakDays: 7 // Would calculate from activity
      },
      patterns: aiModule.modelData.patterns || [],
      riskFactors: aiModule.modelData.riskFactors || [],
      strengths: [
        'Consistent engagement with mindfulness exercises',
        'Strong self-reflection skills',
        'Proactive in seeking help'
      ],
      recommendations: aiModule.pendingRecommendations.slice(0, 3)
    };

    res.status(200).json({
      success: true,
      analysis
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
