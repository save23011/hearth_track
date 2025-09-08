const jwt = require('jsonwebtoken');
const User = require('../models/User');
const videoCallHandlers = require('./videoCallHandlers');

const socketHandlers = (socket, io) => {
  console.log('New socket connection:', socket.id);

  // Initialize video call handlers
  videoCallHandlers(socket, io);

  // Authenticate socket connection
  socket.on('authenticate', async (token) => {
    try {
      console.log('Authentication attempt:', { socketId: socket.id, token: token ? token.substring(0, 20) + '...' : 'null' });
      
      // Handle demo tokens for testing
      if (token && token.startsWith('demo_token_')) {
        const timestamp = token.split('_')[2];
        const demoUser = {
          _id: `demo_user_${timestamp}`,
          firstName: 'Demo',
          lastName: 'User',
          profilePicture: null
        };
        
        socket.userId = demoUser._id;
        socket.user = demoUser;
        socket.join(`user_${demoUser._id}`);
        
        console.log(`Demo user authenticated on socket ${socket.id}:`, demoUser);
        
        socket.emit('authenticated', {
          success: true,
          user: {
            id: demoUser._id,
            firstName: demoUser.firstName,
            lastName: demoUser.lastName
          }
        });
        return;
      }
      
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.id);
      
      if (user) {
        socket.userId = user._id.toString();
        socket.user = user;
        socket.join(`user_${user._id}`);
        
        console.log(`User ${user.firstName} ${user.lastName} authenticated on socket ${socket.id}`);
        
        socket.emit('authenticated', {
          success: true,
          user: {
            id: user._id,
            firstName: user.firstName,
            lastName: user.lastName
          }
        });
      } else {
        socket.emit('authentication_error', { message: 'User not found' });
      }
    } catch (error) {
      console.error('Socket authentication error:', error);
      socket.emit('authentication_error', { message: 'Invalid token' });
    }
  });

  // Join therapy session room
  socket.on('join_session', (sessionId) => {
    if (!socket.userId) {
      socket.emit('error', { message: 'Not authenticated' });
      return;
    }
    
    socket.join(`session_${sessionId}`);
    socket.sessionId = sessionId;
    
    console.log(`User ${socket.userId} joined session ${sessionId}`);
    
    // Notify other participants
    socket.to(`session_${sessionId}`).emit('user_joined', {
      userId: socket.userId,
      user: {
        id: socket.user._id,
        firstName: socket.user.firstName,
        lastName: socket.user.lastName,
        avatar: socket.user.avatar
      }
    });
  });

  // Leave therapy session room
  socket.on('leave_session', (sessionId) => {
    socket.leave(`session_${sessionId}`);
    
    console.log(`User ${socket.userId} left session ${sessionId}`);
    
    // Notify other participants
    socket.to(`session_${sessionId}`).emit('user_left', {
      userId: socket.userId
    });
  });

  // Handle video call signaling
  socket.on('video_offer', (data) => {
    socket.to(`session_${socket.sessionId}`).emit('video_offer', {
      offer: data.offer,
      from: socket.userId
    });
  });

  socket.on('video_answer', (data) => {
    socket.to(`session_${socket.sessionId}`).emit('video_answer', {
      answer: data.answer,
      from: socket.userId
    });
  });

  socket.on('ice_candidate', (data) => {
    socket.to(`session_${socket.sessionId}`).emit('ice_candidate', {
      candidate: data.candidate,
      from: socket.userId
    });
  });

  // Handle screen sharing
  socket.on('start_screen_share', () => {
    socket.to(`session_${socket.sessionId}`).emit('screen_share_started', {
      from: socket.userId
    });
  });

  socket.on('stop_screen_share', () => {
    socket.to(`session_${socket.sessionId}`).emit('screen_share_stopped', {
      from: socket.userId
    });
  });

  // Handle chat messages in real-time
  socket.on('chat_message', (data) => {
    if (!socket.sessionId) {
      socket.emit('error', { message: 'Not in a session' });
      return;
    }
    
    const messageData = {
      ...data,
      from: socket.userId,
      user: {
        id: socket.user._id,
        firstName: socket.user.firstName,
        lastName: socket.user.lastName,
        avatar: socket.user.avatar
      },
      timestamp: new Date()
    };
    
    // Broadcast to all users in the session
    io.to(`session_${socket.sessionId}`).emit('chat_message', messageData);
  });

  // Handle typing indicators
  socket.on('typing_start', () => {
    if (socket.sessionId) {
      socket.to(`session_${socket.sessionId}`).emit('user_typing', {
        userId: socket.userId,
        user: socket.user
      });
    }
  });

  socket.on('typing_stop', () => {
    if (socket.sessionId) {
      socket.to(`session_${socket.sessionId}`).emit('user_stopped_typing', {
        userId: socket.userId
      });
    }
  });

  // Handle AI concept mapping collaboration
  socket.on('join_concept_map', (mapId) => {
    if (!socket.userId) {
      socket.emit('error', { message: 'Not authenticated' });
      return;
    }
    
    socket.join(`concept_map_${mapId}`);
    
    socket.to(`concept_map_${mapId}`).emit('user_joined_map', {
      userId: socket.userId,
      user: socket.user
    });
  });

  socket.on('concept_map_update', (data) => {
    const { mapId, update } = data;
    
    socket.to(`concept_map_${mapId}`).emit('concept_map_updated', {
      update,
      from: socket.userId,
      timestamp: new Date()
    });
  });

  // Handle push notifications
  socket.on('register_push_token', (data) => {
    if (!socket.userId) {
      socket.emit('error', { message: 'Not authenticated' });
      return;
    }
    
    // Store push token for user
    // This would typically update the user's device record
    console.log(`Push token registered for user ${socket.userId}:`, data.token);
  });

  // Handle exercise session participation
  socket.on('start_exercise', (exerciseId) => {
    if (!socket.userId) {
      socket.emit('error', { message: 'Not authenticated' });
      return;
    }
    
    socket.join(`exercise_${exerciseId}`);
    
    socket.emit('exercise_started', {
      exerciseId,
      startTime: new Date()
    });
  });

  socket.on('exercise_progress', (data) => {
    const { exerciseId, progress } = data;
    
    // Optionally broadcast progress to therapists or group sessions
    socket.to(`exercise_${exerciseId}_observers`).emit('user_exercise_progress', {
      userId: socket.userId,
      progress,
      timestamp: new Date()
    });
  });

  // Handle general notifications
  socket.on('mark_notification_read', (notificationId) => {
    if (!socket.userId) return;
    
    // Update notification status
    // This would typically update the notification in the database
    console.log(`Notification ${notificationId} marked as read by user ${socket.userId}`);
  });

  // Handle connection errors
  socket.on('error', (error) => {
    console.error('Socket error:', error);
  });

  // Handle disconnection
  socket.on('disconnect', (reason) => {
    console.log(`Socket ${socket.id} disconnected:`, reason);
    
    if (socket.sessionId) {
      socket.to(`session_${socket.sessionId}`).emit('user_left', {
        userId: socket.userId,
        reason: 'disconnected'
      });
    }
  });
};

module.exports = socketHandlers;
