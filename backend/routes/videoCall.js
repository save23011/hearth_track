const express = require('express');
const router = express.Router();
const CallSession = require('../models/CallSession');
const User = require('../models/User');
const { body, validationResult } = require('express-validator');

// WebRTC Configuration with STUN servers
const ICE_SERVERS = [
  {
    urls: [
      'stun:stun.l.google.com:19302',
      'stun:stun1.l.google.com:19302',
      'stun:stun2.l.google.com:19302',
      'stun:stun3.l.google.com:19302',
      'stun:stun4.l.google.com:19302'
    ]
  },
  {
    urls: 'stun:stun.services.mozilla.com'
  },
  {
    urls: 'stun:stun.stunprotocol.org:3478'
  }
];

// @route   POST /api/video-call/initiate
// @desc    Initiate a new video call session
// @access  Private
router.post('/initiate', [
  body('sessionType').isIn(['one-to-one', 'group', 'therapy']).withMessage('Invalid session type'),
  body('participants').isArray({ min: 1 }).withMessage('At least one participant is required'),
  body('callSettings').optional().isObject(),
  body('metadata').optional().isObject()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { sessionType, participants, callSettings, metadata, therapySessionId } = req.body;
    const initiatorId = req.user._id;

    // Validate participants exist
    const participantUsers = await User.find({ _id: { $in: participants } });
    if (participantUsers.length !== participants.length) {
      return res.status(400).json({
        success: false,
        message: 'One or more participants not found'
      });
    }

    // Create call session
    const callSession = await CallSession.createSession({
      sessionType,
      initiatorId,
      maxParticipants: sessionType === 'one-to-one' ? 2 : 8,
      callSettings: {
        isVideoEnabled: true,
        isAudioEnabled: true,
        isRecordingEnabled: false,
        allowScreenShare: true,
        ...callSettings
      },
      metadata,
      therapySessionId
    });

    // Emit call invitation to participants via Socket.IO
    participants.forEach(participantId => {
      if (participantId !== initiatorId.toString()) {
        req.io.to(`user_${participantId}`).emit('call_invitation', {
          sessionId: callSession.sessionId,
          sessionType,
          initiator: {
            id: req.user._id,
            firstName: req.user.firstName,
            lastName: req.user.lastName,
            profilePicture: req.user.profilePicture
          },
          callSettings: callSession.callSettings,
          metadata,
          iceServers: ICE_SERVERS
        });
      }
    });

    res.status(201).json({
      success: true,
      message: 'Call session initiated successfully',
      data: {
        sessionId: callSession.sessionId,
        iceServers: ICE_SERVERS,
        callSettings: callSession.callSettings
      }
    });

  } catch (error) {
    console.error('Error initiating call:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to initiate call',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   POST /api/video-call/join/:sessionId
// @desc    Join an existing video call session
// @access  Private
router.post('/join/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const userId = req.user._id;

    const callSession = await CallSession.findActiveSession(sessionId);
    if (!callSession) {
      return res.status(404).json({
        success: false,
        message: 'Call session not found or has ended'
      });
    }

    // Check if user is already in the session
    const existingParticipant = callSession.participants.find(p => 
      p.userId.toString() === userId.toString() && p.isActive
    );

    if (existingParticipant) {
      return res.status(400).json({
        success: false,
        message: 'User already in the call session'
      });
    }

    // Check if session is full
    if (callSession.activeParticipantsCount >= callSession.maxParticipants) {
      return res.status(400).json({
        success: false,
        message: 'Call session is full'
      });
    }

    // Update session status to active if it's the first join
    if (callSession.status === 'waiting') {
      callSession.status = 'active';
      await callSession.save();
    }

    res.status(200).json({
      success: true,
      message: 'Ready to join call session',
      data: {
        sessionId: callSession.sessionId,
        sessionType: callSession.sessionType,
        participants: callSession.participants.filter(p => p.isActive),
        callSettings: callSession.callSettings,
        iceServers: ICE_SERVERS
      }
    });

  } catch (error) {
    console.error('Error joining call:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to join call',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   GET /api/video-call/session/:sessionId
// @desc    Get call session details
// @access  Private
router.get('/session/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const userId = req.user._id;

    const callSession = await CallSession.findOne({ sessionId })
      .populate('initiatorId', 'firstName lastName profilePicture')
      .populate('participants.userId', 'firstName lastName profilePicture');

    if (!callSession) {
      return res.status(404).json({
        success: false,
        message: 'Call session not found'
      });
    }

    // Check if user is participant or initiator
    const isParticipant = callSession.participants.some(p => 
      p.userId._id.toString() === userId.toString()
    ) || callSession.initiatorId._id.toString() === userId.toString();

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. User is not a participant in this call session'
      });
    }

    res.status(200).json({
      success: true,
      data: callSession
    });

  } catch (error) {
    console.error('Error getting call session:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get call session',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   PUT /api/video-call/session/:sessionId/media
// @desc    Update participant media settings
// @access  Private
router.put('/session/:sessionId/media', [
  body('hasVideo').optional().isBoolean(),
  body('hasAudio').optional().isBoolean(),
  body('isScreenSharing').optional().isBoolean()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { sessionId } = req.params;
    const userId = req.user._id;
    const mediaSettings = req.body;

    const callSession = await CallSession.findActiveSession(sessionId);
    if (!callSession) {
      return res.status(404).json({
        success: false,
        message: 'Call session not found or has ended'
      });
    }

    await callSession.updateParticipantMedia(userId, mediaSettings);

    // Notify other participants about media changes
    req.io.to(`call_${sessionId}`).emit('participant_media_updated', {
      userId,
      mediaSettings
    });

    res.status(200).json({
      success: true,
      message: 'Media settings updated successfully'
    });

  } catch (error) {
    console.error('Error updating media settings:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update media settings',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   POST /api/video-call/session/:sessionId/end
// @desc    End a call session
// @access  Private
router.post('/session/:sessionId/end', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const userId = req.user._id;

    const callSession = await CallSession.findActiveSession(sessionId);
    if (!callSession) {
      return res.status(404).json({
        success: false,
        message: 'Call session not found or has ended'
      });
    }

    // Check if user is initiator or participant
    const isInitiator = callSession.initiatorId.toString() === userId.toString();
    const isParticipant = callSession.participants.some(p => 
      p.userId.toString() === userId.toString() && p.isActive
    );

    if (!isInitiator && !isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. User cannot end this call session'
      });
    }

    // End the session
    callSession.status = 'ended';
    callSession.endTime = new Date();
    callSession.duration = Math.floor((callSession.endTime - callSession.startTime) / 1000);
    
    // Mark all participants as inactive
    callSession.participants.forEach(participant => {
      if (participant.isActive) {
        participant.isActive = false;
        participant.leftAt = new Date();
      }
    });

    await callSession.save();

    // Notify all participants that call has ended
    req.io.to(`call_${sessionId}`).emit('call_ended', {
      sessionId,
      endedBy: {
        id: userId,
        firstName: req.user.firstName,
        lastName: req.user.lastName
      },
      duration: callSession.duration
    });

    res.status(200).json({
      success: true,
      message: 'Call session ended successfully',
      data: {
        duration: callSession.duration,
        durationInMinutes: callSession.durationInMinutes
      }
    });

  } catch (error) {
    console.error('Error ending call:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to end call',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   GET /api/video-call/history
// @desc    Get user's call history
// @access  Private
router.get('/history', async (req, res) => {
  try {
    const userId = req.user._id;
    const { page = 1, limit = 20, status } = req.query;

    const query = {
      $or: [
        { initiatorId: userId },
        { 'participants.userId': userId }
      ]
    };

    if (status) {
      query.status = status;
    }

    const callSessions = await CallSession.find(query)
      .populate('initiatorId', 'firstName lastName profilePicture')
      .populate('participants.userId', 'firstName lastName profilePicture')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await CallSession.countDocuments(query);

    res.status(200).json({
      success: true,
      data: {
        callSessions,
        totalPages: Math.ceil(total / limit),
        currentPage: page,
        total
      }
    });

  } catch (error) {
    console.error('Error getting call history:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get call history',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

module.exports = router;
