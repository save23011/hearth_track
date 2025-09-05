const express = require('express');
const TherapySession = require('../models/TherapySession');
const { validateTherapySession } = require('../middleware/validation');

const router = express.Router();

// @desc    Get therapy sessions for user
// @route   GET /api/therapy/sessions
// @access  Private
router.get('/sessions', async (req, res, next) => {
  try {
    const { status, page = 1, limit = 10, upcoming = false } = req.query;
    
    const query = {
      $or: [
        { user: req.user.id },
        { therapist: req.user.id },
        { 'participants.user': req.user.id }
      ]
    };

    if (status) {
      query.status = status;
    }

    if (upcoming === 'true') {
      query.scheduledFor = { $gte: new Date() };
      query.status = 'scheduled';
    }

    const sessions = await TherapySession.find(query)
      .populate('user', 'firstName lastName avatar')
      .populate('therapist', 'firstName lastName avatar')
      .populate('participants.user', 'firstName lastName avatar')
      .sort({ scheduledFor: upcoming === 'true' ? 1 : -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await TherapySession.countDocuments(query);

    res.status(200).json({
      success: true,
      count: sessions.length,
      total,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      },
      sessions
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Get single therapy session
// @route   GET /api/therapy/sessions/:id
// @access  Private
router.get('/sessions/:id', async (req, res, next) => {
  try {
    const session = await TherapySession.findById(req.params.id)
      .populate('user', 'firstName lastName avatar')
      .populate('therapist', 'firstName lastName avatar')
      .populate('participants.user', 'firstName lastName avatar');

    if (!session) {
      return res.status(404).json({
        success: false,
        message: 'Therapy session not found'
      });
    }

    // Check if user has access to this session
    const hasAccess = 
      session.user._id.toString() === req.user.id ||
      session.therapist?._id.toString() === req.user.id ||
      session.participants.some(p => p.user._id.toString() === req.user.id);

    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Access denied to this therapy session'
      });
    }

    res.status(200).json({
      success: true,
      session
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Create therapy session
// @route   POST /api/therapy/sessions
// @access  Private
router.post('/sessions', validateTherapySession, async (req, res, next) => {
  try {
    const sessionData = {
      ...req.body,
      user: req.user.id,
      sessionId: `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      joinLink: `${process.env.FRONTEND_URL}/therapy/join/${req.body.sessionId || 'temp'}`
    };

    const session = await TherapySession.create(sessionData);

    // Update join link with actual session ID
    session.joinLink = `${process.env.FRONTEND_URL}/therapy/join/${session._id}`;
    await session.save();

    res.status(201).json({
      success: true,
      session
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Update therapy session
// @route   PUT /api/therapy/sessions/:id
// @access  Private
router.put('/sessions/:id', async (req, res, next) => {
  try {
    let session = await TherapySession.findById(req.params.id);

    if (!session) {
      return res.status(404).json({
        success: false,
        message: 'Therapy session not found'
      });
    }

    // Check if user can update this session
    const canUpdate = 
      session.user.toString() === req.user.id ||
      session.therapist?.toString() === req.user.id;

    if (!canUpdate) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this session'
      });
    }

    session = await TherapySession.findByIdAndUpdate(
      req.params.id,
      req.body,
      {
        new: true,
        runValidators: true
      }
    );

    res.status(200).json({
      success: true,
      session
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Start therapy session
// @route   POST /api/therapy/sessions/:id/start
// @access  Private
router.post('/sessions/:id/start', async (req, res, next) => {
  try {
    const session = await TherapySession.findById(req.params.id);

    if (!session) {
      return res.status(404).json({
        success: false,
        message: 'Therapy session not found'
      });
    }

    // Check if user can start this session
    const canStart = 
      session.user.toString() === req.user.id ||
      session.therapist?.toString() === req.user.id;

    if (!canStart) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to start this session'
      });
    }

    if (session.status !== 'scheduled') {
      return res.status(400).json({
        success: false,
        message: 'Session cannot be started in current status'
      });
    }

    await session.startSession();

    // Notify other participants via Socket.IO
    if (req.io) {
      req.io.to(`session_${session._id}`).emit('sessionStarted', {
        sessionId: session._id,
        startTime: session.actualStartTime
      });
    }

    res.status(200).json({
      success: true,
      message: 'Session started successfully',
      session
    });
  } catch (error) {
    next(error);
  }
});

// @desc    End therapy session
// @route   POST /api/therapy/sessions/:id/end
// @access  Private
router.post('/sessions/:id/end', async (req, res, next) => {
  try {
    const session = await TherapySession.findById(req.params.id);

    if (!session) {
      return res.status(404).json({
        success: false,
        message: 'Therapy session not found'
      });
    }

    // Check if user can end this session
    const canEnd = 
      session.user.toString() === req.user.id ||
      session.therapist?.toString() === req.user.id;

    if (!canEnd) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to end this session'
      });
    }

    if (session.status !== 'in-progress') {
      return res.status(400).json({
        success: false,
        message: 'Session is not in progress'
      });
    }

    await session.endSession();

    // Add session notes if provided
    if (req.body.sessionNotes) {
      Object.assign(session.sessionNotes, req.body.sessionNotes);
      await session.save();
    }

    // Notify participants via Socket.IO
    if (req.io) {
      req.io.to(`session_${session._id}`).emit('sessionEnded', {
        sessionId: session._id,
        endTime: session.actualEndTime,
        duration: session.sessionDuration
      });
    }

    res.status(200).json({
      success: true,
      message: 'Session ended successfully',
      session
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Join therapy session
// @route   POST /api/therapy/sessions/:id/join
// @access  Private
router.post('/sessions/:id/join', async (req, res, next) => {
  try {
    const session = await TherapySession.findById(req.params.id);

    if (!session) {
      return res.status(404).json({
        success: false,
        message: 'Therapy session not found'
      });
    }

    // Check if user has access to join this session
    const hasAccess = 
      session.user.toString() === req.user.id ||
      session.therapist?.toString() === req.user.id ||
      session.participants.some(p => p.user.toString() === req.user.id);

    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Access denied to this therapy session'
      });
    }

    // Add device info to technical details
    if (req.body.deviceInfo) {
      const existingDeviceIndex = session.technical.deviceInfo.findIndex(
        d => d.user.toString() === req.user.id
      );

      if (existingDeviceIndex !== -1) {
        session.technical.deviceInfo[existingDeviceIndex] = {
          user: req.user.id,
          ...req.body.deviceInfo
        };
      } else {
        session.technical.deviceInfo.push({
          user: req.user.id,
          ...req.body.deviceInfo
        });
      }

      await session.save();
    }

    res.status(200).json({
      success: true,
      message: 'Joined session successfully',
      sessionDetails: {
        id: session._id,
        title: session.title,
        status: session.status,
        media: session.media,
        joinLink: session.joinLink
      }
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Add chat message to session
// @route   POST /api/therapy/sessions/:id/chat
// @access  Private
router.post('/sessions/:id/chat', async (req, res, next) => {
  try {
    const { message, type = 'text' } = req.body;
    const session = await TherapySession.findById(req.params.id);

    if (!session) {
      return res.status(404).json({
        success: false,
        message: 'Therapy session not found'
      });
    }

    // Check if user has access to this session
    const hasAccess = 
      session.user.toString() === req.user.id ||
      session.therapist?.toString() === req.user.id ||
      session.participants.some(p => p.user.toString() === req.user.id);

    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Access denied to this therapy session'
      });
    }

    await session.addChatMessage(req.user.id, message, type);

    // Broadcast message via Socket.IO
    if (req.io) {
      req.io.to(`session_${session._id}`).emit('newChatMessage', {
        sender: req.user.id,
        message,
        type,
        timestamp: new Date()
      });
    }

    res.status(200).json({
      success: true,
      message: 'Message sent successfully'
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Submit session assessment
// @route   POST /api/therapy/sessions/:id/assessment
// @access  Private
router.post('/sessions/:id/assessment', async (req, res, next) => {
  try {
    const { type, assessment } = req.body; // type: 'pre' or 'post'
    const session = await TherapySession.findById(req.params.id);

    if (!session) {
      return res.status(404).json({
        success: false,
        message: 'Therapy session not found'
      });
    }

    // Check if user is the session participant
    if (session.user.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Only session participant can submit assessments'
      });
    }

    if (type === 'pre') {
      Object.assign(session.preSessionAssessment, assessment);
    } else if (type === 'post') {
      Object.assign(session.postSessionAssessment, assessment);
    } else {
      return res.status(400).json({
        success: false,
        message: 'Invalid assessment type'
      });
    }

    await session.save();

    res.status(200).json({
      success: true,
      message: `${type}-session assessment submitted successfully`
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Get session analytics
// @route   GET /api/therapy/analytics
// @access  Private
router.get('/analytics', async (req, res, next) => {
  try {
    const { timeframe = '30d' } = req.query;
    
    let dateFilter = {};
    const now = new Date();
    
    switch (timeframe) {
      case '7d':
        dateFilter = { $gte: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000) };
        break;
      case '30d':
        dateFilter = { $gte: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000) };
        break;
      case '90d':
        dateFilter = { $gte: new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000) };
        break;
    }

    const userSessions = await TherapySession.find({
      user: req.user.id,
      createdAt: dateFilter
    });

    const analytics = {
      totalSessions: userSessions.length,
      completedSessions: userSessions.filter(s => s.status === 'completed').length,
      totalTime: userSessions.reduce((sum, s) => sum + (s.actualDuration || 0), 0),
      averageRating: 0,
      sessionTypes: userSessions.reduce((acc, s) => {
        acc[s.type] = (acc[s.type] || 0) + 1;
        return acc;
      }, {}),
      weeklyProgress: [] // Would calculate weekly session counts
    };

    // Calculate average rating from post-session assessments
    const ratingsFromSessions = userSessions
      .filter(s => s.postSessionAssessment && s.postSessionAssessment.satisfaction)
      .map(s => s.postSessionAssessment.satisfaction);
    
    if (ratingsFromSessions.length > 0) {
      analytics.averageRating = ratingsFromSessions.reduce((sum, rating) => sum + rating, 0) / ratingsFromSessions.length;
    }

    res.status(200).json({
      success: true,
      analytics
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
