const express = require('express');
const User = require('../models/User');
const AIModule = require('../models/AIModule');
const { validateProfileUpdate } = require('../middleware/validation');

const router = express.Router();

// @desc    Get user profile
// @route   GET /api/users/profile
// @access  Private
router.get('/profile', async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    
    res.status(200).json({
      success: true,
      user
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Update user profile
// @route   PUT /api/users/profile
// @access  Private
router.put('/profile', validateProfileUpdate, async (req, res, next) => {
  try {
    const allowedFields = [
      'firstName',
      'lastName',
      'dateOfBirth',
      'gender',
      'location',
      'healthProfile'
    ];

    const updateData = {};
    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) {
        updateData[field] = req.body[field];
      }
    });

    const user = await User.findByIdAndUpdate(
      req.user.id,
      updateData,
      {
        new: true,
        runValidators: true
      }
    );

    res.status(200).json({
      success: true,
      user
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Update user settings
// @route   PUT /api/users/settings
// @access  Private
router.put('/settings', async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    
    // Update settings
    if (req.body.notifications) {
      Object.assign(user.settings.notifications, req.body.notifications);
    }
    
    if (req.body.privacy) {
      Object.assign(user.settings.privacy, req.body.privacy);
    }
    
    if (req.body.language) {
      user.settings.language = req.body.language;
    }
    
    if (req.body.theme) {
      user.settings.theme = req.body.theme;
    }

    await user.save();

    res.status(200).json({
      success: true,
      message: 'Settings updated successfully',
      settings: user.settings
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Get user analytics
// @route   GET /api/users/analytics
// @access  Private
router.get('/analytics', async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    
    // Get AI module data
    const aiModule = await AIModule.findOne({ user: req.user.id });
    
    const analytics = {
      account: user.analytics,
      ai: aiModule ? {
        conceptMapsCreated: aiModule.progress.conceptMapsCreated,
        assessmentsCompleted: aiModule.progress.assessmentsCompleted,
        totalEngagementTime: aiModule.progress.totalEngagementTime,
        weeklyProgress: aiModule.progress.weeklyProgress,
        milestones: aiModule.progress.milestones
      } : null
    };

    res.status(200).json({
      success: true,
      analytics
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Add or update device info
// @route   POST /api/users/devices
// @access  Private
router.post('/devices', async (req, res, next) => {
  try {
    const { deviceId, platform, pushToken } = req.body;
    const user = await User.findById(req.user.id);

    // Check if device already exists
    const existingDeviceIndex = user.devices.findIndex(
      device => device.deviceId === deviceId
    );

    if (existingDeviceIndex !== -1) {
      // Update existing device
      user.devices[existingDeviceIndex].pushToken = pushToken;
      user.devices[existingDeviceIndex].lastSeen = new Date();
      user.devices[existingDeviceIndex].isActive = true;
    } else {
      // Add new device
      user.devices.push({
        deviceId,
        platform,
        pushToken,
        lastSeen: new Date(),
        isActive: true
      });
    }

    await user.save();

    res.status(200).json({
      success: true,
      message: 'Device registered successfully'
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Remove device
// @route   DELETE /api/users/devices/:deviceId
// @access  Private
router.delete('/devices/:deviceId', async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    
    user.devices = user.devices.filter(
      device => device.deviceId !== req.params.deviceId
    );

    await user.save();

    res.status(200).json({
      success: true,
      message: 'Device removed successfully'
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Update subscription
// @route   PUT /api/users/subscription
// @access  Private
router.put('/subscription', async (req, res, next) => {
  try {
    const { plan, paymentMethod } = req.body;
    const user = await User.findById(req.user.id);

    // Update subscription
    user.subscription.plan = plan;
    user.subscription.paymentMethod = paymentMethod;
    
    if (plan !== 'free') {
      user.subscription.startDate = new Date();
      user.subscription.endDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days
      user.subscription.autoRenew = true;
    }

    await user.save();

    res.status(200).json({
      success: true,
      message: 'Subscription updated successfully',
      subscription: user.subscription
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Get user dashboard data
// @route   GET /api/users/dashboard
// @access  Private
router.get('/dashboard', async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    const aiModule = await AIModule.findOne({ user: req.user.id });

    // Get recent activity (this would be expanded with actual data)
    const dashboard = {
      user: {
        name: user.fullName,
        avatar: user.avatar,
        subscription: user.subscription
      },
      stats: {
        totalSessions: 0, // Would get from TherapySession model
        exercisesCompleted: 0, // Would get from Exercise completions
        journalEntries: 0, // Would get from Journal model
        currentStreak: 0 // Would calculate from activity
      },
      recentActivity: [],
      upcomingSessions: [],
      recommendations: aiModule ? aiModule.pendingRecommendations : [],
      progress: aiModule ? {
        weeklyGoals: aiModule.progress.weeklyProgress,
        milestones: aiModule.progress.milestones.slice(-5)
      } : null
    };

    res.status(200).json({
      success: true,
      dashboard
    });
  } catch (error) {
    next(error);
  }
});

// @desc    Delete user account
// @route   DELETE /api/users/account
// @access  Private
router.delete('/account', async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    
    // Mark user as inactive instead of deleting (for data retention)
    user.isActive = false;
    user.email = `deleted_${Date.now()}_${user.email}`;
    
    await user.save();

    // TODO: Clean up related data, cancel subscriptions, etc.

    res.status(200).json({
      success: true,
      message: 'Account deactivated successfully'
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
