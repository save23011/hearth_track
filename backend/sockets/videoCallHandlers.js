const CallSession = require('../models/CallSession');

const videoCallHandlers = (socket, io) => {
  console.log('Video call handlers initialized for socket:', socket.id);

  // Join a call session room
  socket.on('join_call_session', async (data) => {
    try {
      const { sessionId, peerId } = data;
      
      console.log('Join call session request:', {
        sessionId,
        peerId,
        socketId: socket.id,
        userId: socket.userId,
        hasUser: !!socket.user
      });
      
      if (!socket.userId) {
        console.log('Authentication check failed - socket.userId not set');
        socket.emit('call_error', { message: 'User not authenticated' });
        return;
      }

      // Try to find existing call session or create new one
      let callSession = await CallSession.findActiveSession(sessionId);
      
      if (!callSession) {
        // Create new call session if it doesn't exist
        callSession = await CallSession.create({
          sessionId,
          initiatorId: socket.userId,
          status: 'active',
          participants: [],
          callSettings: {
            maxParticipants: 10,
            allowScreenShare: true,
            allowRecording: false
          },
          startTime: new Date()
        });
        
        console.log(`Created new call session: ${sessionId}`);
      }

      // Check if user is allowed to join
      const isInitiator = callSession.initiatorId.toString() === socket.userId;
      const existingParticipant = callSession.participants.find(p => 
        p.userId.toString() === socket.userId && p.isActive
      );

      if (!isInitiator && !existingParticipant && callSession.participants.length > 0) {
        // For now, allow anyone to join for demo purposes
        // In production, you'd want proper invitation/permission checks
      }

      // Add participant to call session
      await callSession.addParticipant(socket.userId, socket.id, peerId);
      
      // Join socket room for this call
      socket.join(`call_${sessionId}`);
      socket.callSessionId = sessionId;
      socket.peerId = peerId;

      // Get current participants
      const updatedSession = await CallSession.findActiveSession(sessionId)
        .populate('participants.userId', 'firstName lastName profilePicture');

      const activeParticipants = updatedSession.participants
        .filter(p => p.isActive)
        .map(p => ({
          userId: p.userId._id,
          peerId: p.peerId,
          socketId: p.socketId,
          firstName: p.userId.firstName,
          lastName: p.userId.lastName,
          profilePicture: p.userId.profilePicture,
          hasVideo: p.hasVideo,
          hasAudio: p.hasAudio,
          isScreenSharing: p.isScreenSharing
        }));

      // Notify user of successful join
      socket.emit('call_session_joined', {
        sessionId,
        participants: activeParticipants,
        callSettings: callSession.callSettings
      });

      // Notify other participants that someone joined
      socket.to(`call_${sessionId}`).emit('user_joined_call', {
        participant: {
          userId: socket.userId,
          peerId,
          socketId: socket.id,
          firstName: socket.user.firstName,
          lastName: socket.user.lastName,
          profilePicture: socket.user.profilePicture,
          hasVideo: true,
          hasAudio: true,
          isScreenSharing: false
        }
      });

      // If there are existing participants, trigger WebRTC connection establishment
      const existingParticipants = activeParticipants.filter(p => p.peerId !== peerId);
      if (existingParticipants.length > 0) {
        console.log(`Triggering WebRTC connections for new participant ${peerId} with ${existingParticipants.length} existing participants`);
        
        // Tell the new participant about existing participants
        existingParticipants.forEach(participant => {
          socket.emit('initiate_peer_connection', {
            targetPeerId: participant.peerId,
            participant: participant
          });
        });

        // Tell existing participants to initiate connections with the new participant
        existingParticipants.forEach(participant => {
          const targetSocket = Array.from(io.sockets.sockets.values())
            .find(s => s.peerId === participant.peerId && s.callSessionId === sessionId);
          
          if (targetSocket) {
            targetSocket.emit('initiate_peer_connection', {
              targetPeerId: peerId,
              participant: {
                userId: socket.userId,
                peerId,
                socketId: socket.id,
                firstName: socket.user.firstName,
                lastName: socket.user.lastName,
                profilePicture: socket.user.profilePicture,
                hasVideo: true,
                hasAudio: true,
                isScreenSharing: false
              }
            });
          }
        });
      }

      console.log(`User ${socket.userId} joined call session ${sessionId}`);

    } catch (error) {
      console.error('Error joining call session:', error);
      socket.emit('call_error', { message: 'Failed to join call session: ' + error.message });
    }
  });

  // WebRTC signaling handlers
  socket.on('webrtc_offer', (data) => {
    const { targetPeerId, sessionId, offer } = data;
    
    if (!socket.callSessionId || socket.callSessionId !== sessionId) {
      socket.emit('call_error', { message: 'Not in call session' });
      return;
    }

    // Find target socket in the same call session
    const targetSocket = Array.from(io.sockets.sockets.values())
      .find(s => s.peerId === targetPeerId && s.callSessionId === sessionId);
    
    if (targetSocket) {
      targetSocket.emit('webrtc_offer', {
        fromPeerId: socket.peerId,
        sessionId,
        offer
      });
      console.log(`Relayed WebRTC offer from ${socket.peerId} to ${targetPeerId}`);
    } else {
      socket.emit('call_error', { message: 'Target peer not found' });
    }
  });

  socket.on('webrtc_answer', (data) => {
    const { targetPeerId, sessionId, answer } = data;
    
    if (!socket.callSessionId || socket.callSessionId !== sessionId) {
      socket.emit('call_error', { message: 'Not in call session' });
      return;
    }

    // Find target socket in the same call session
    const targetSocket = Array.from(io.sockets.sockets.values())
      .find(s => s.peerId === targetPeerId && s.callSessionId === sessionId);
    
    if (targetSocket) {
      targetSocket.emit('webrtc_answer', {
        fromPeerId: socket.peerId,
        sessionId,
        answer
      });
      console.log(`Relayed WebRTC answer from ${socket.peerId} to ${targetPeerId}`);
    } else {
      socket.emit('call_error', { message: 'Target peer not found' });
    }
  });

  socket.on('webrtc_ice_candidate', (data) => {
    const { targetPeerId, sessionId, candidate } = data;
    
    if (!socket.callSessionId || socket.callSessionId !== sessionId) {
      socket.emit('call_error', { message: 'Not in call session' });
      return;
    }

    // Find target socket in the same call session
    const targetSocket = Array.from(io.sockets.sockets.values())
      .find(s => s.peerId === targetPeerId && s.callSessionId === sessionId);
    
    if (targetSocket) {
      targetSocket.emit('webrtc_ice_candidate', {
        fromPeerId: socket.peerId,
        sessionId,
        candidate
      });
      console.log(`Relayed ICE candidate from ${socket.peerId} to ${targetPeerId}`);
    }
  });

  // Media control handlers
  socket.on('toggle_video', async (data) => {
    try {
      const { sessionId, hasVideo } = data;
      
      if (!socket.userId || !socket.callSessionId || socket.callSessionId !== sessionId) {
        return;
      }

      const callSession = await CallSession.findActiveSession(sessionId);
      if (callSession) {
        await callSession.updateParticipantMedia(socket.userId, { hasVideo });
        
        // Notify other participants
        socket.to(`call_${sessionId}`).emit('participant_toggled_video', {
          userId: socket.userId,
          peerId: socket.peerId,
          hasVideo
        });
      }
    } catch (error) {
      console.error('Error toggling video:', error);
    }
  });

  socket.on('toggle_audio', async (data) => {
    try {
      const { sessionId, hasAudio } = data;
      
      if (!socket.userId || !socket.callSessionId || socket.callSessionId !== sessionId) {
        return;
      }

      const callSession = await CallSession.findActiveSession(sessionId);
      if (callSession) {
        await callSession.updateParticipantMedia(socket.userId, { hasAudio });
        
        // Notify other participants
        socket.to(`call_${sessionId}`).emit('participant_toggled_audio', {
          userId: socket.userId,
          peerId: socket.peerId,
          hasAudio
        });
      }
    } catch (error) {
      console.error('Error toggling audio:', error);
    }
  });

  // Leave a call session
  socket.on('leave_call_session', async (data) => {
    try {
      const { sessionId } = data;
      
      if (!socket.userId || !sessionId) {
        return;
      }

      const callSession = await CallSession.findActiveSession(sessionId);
      if (callSession) {
        await callSession.removeParticipant(socket.userId, socket.id);
        
        // Notify other participants
        socket.to(`call_${sessionId}`).emit('user_left_call', {
          userId: socket.userId,
          socketId: socket.id
        });
      }

      socket.leave(`call_${sessionId}`);
      socket.callSessionId = null;
      socket.peerId = null;

      console.log(`User ${socket.userId} left call session ${sessionId}`);

    } catch (error) {
      console.error('Error leaving call session:', error);
    }
  });

  // WebRTC signaling - offer
  socket.on('webrtc_offer', (data) => {
    const { targetPeerId, targetSocketId, sessionId, offer } = data;
    
    if (!socket.callSessionId || socket.callSessionId !== sessionId) {
      socket.emit('call_error', { message: 'Not in call session' });
      return;
    }

    // Forward offer to target peer
    if (targetSocketId) {
      io.to(targetSocketId).emit('webrtc_offer', {
        fromPeerId: socket.peerId,
        fromSocketId: socket.id,
        fromUserId: socket.userId,
        sessionId,
        offer
      });
    }
  });

  // WebRTC signaling - answer
  socket.on('webrtc_answer', (data) => {
    const { targetPeerId, targetSocketId, sessionId, answer } = data;
    
    if (!socket.callSessionId || socket.callSessionId !== sessionId) {
      socket.emit('call_error', { message: 'Not in call session' });
      return;
    }

    // Forward answer to target peer
    if (targetSocketId) {
      io.to(targetSocketId).emit('webrtc_answer', {
        fromPeerId: socket.peerId,
        fromSocketId: socket.id,
        fromUserId: socket.userId,
        sessionId,
        answer
      });
    }
  });

  // WebRTC signaling - ICE candidate
  socket.on('webrtc_ice_candidate', (data) => {
    const { targetPeerId, targetSocketId, sessionId, candidate } = data;
    
    if (!socket.callSessionId || socket.callSessionId !== sessionId) {
      socket.emit('call_error', { message: 'Not in call session' });
      return;
    }

    // Forward ICE candidate to target peer
    if (targetSocketId) {
      io.to(targetSocketId).emit('webrtc_ice_candidate', {
        fromPeerId: socket.peerId,
        fromSocketId: socket.id,
        fromUserId: socket.userId,
        sessionId,
        candidate
      });
    }
  });

  // Handle media state changes (mute/unmute, video on/off)
  socket.on('media_state_changed', async (data) => {
    try {
      const { sessionId, hasVideo, hasAudio, isScreenSharing } = data;
      
      if (!socket.callSessionId || socket.callSessionId !== sessionId) {
        socket.emit('call_error', { message: 'Not in call session' });
        return;
      }

      const callSession = await CallSession.findActiveSession(sessionId);
      if (callSession) {
        await callSession.updateParticipantMedia(socket.userId, {
          hasVideo,
          hasAudio,
          isScreenSharing
        });

        // Notify other participants about media state change
        socket.to(`call_${sessionId}`).emit('participant_media_changed', {
          userId: socket.userId,
          socketId: socket.id,
          hasVideo,
          hasAudio,
          isScreenSharing
        });
      }

    } catch (error) {
      console.error('Error updating media state:', error);
      socket.emit('call_error', { message: 'Failed to update media state' });
    }
  });

  // Handle screen sharing
  socket.on('screen_share_started', (data) => {
    const { sessionId } = data;
    
    if (!socket.callSessionId || socket.callSessionId !== sessionId) {
      socket.emit('call_error', { message: 'Not in call session' });
      return;
    }

    // Notify other participants about screen sharing
    socket.to(`call_${sessionId}`).emit('participant_screen_share_started', {
      userId: socket.userId,
      socketId: socket.id,
      peerId: socket.peerId
    });
  });

  socket.on('screen_share_stopped', (data) => {
    const { sessionId } = data;
    
    if (!socket.callSessionId || socket.callSessionId !== sessionId) {
      socket.emit('call_error', { message: 'Not in call session' });
      return;
    }

    // Notify other participants about screen sharing stopped
    socket.to(`call_${sessionId}`).emit('participant_screen_share_stopped', {
      userId: socket.userId,
      socketId: socket.id
    });
  });

  // Handle call quality feedback
  socket.on('call_quality_report', async (data) => {
    try {
      const { sessionId, qualityData } = data;
      
      if (!socket.callSessionId || socket.callSessionId !== sessionId) {
        return;
      }

      // Log quality data for monitoring and improvement
      console.log('Call quality report:', {
        sessionId,
        userId: socket.userId,
        timestamp: new Date(),
        qualityData
      });

      // You could store this in a separate collection for analytics
      // await CallQualityReport.create({
      //   sessionId,
      //   userId: socket.userId,
      //   qualityData,
      //   timestamp: new Date()
      // });

    } catch (error) {
      console.error('Error handling call quality report:', error);
    }
  });

  // Handle connection issues
  socket.on('connection_issue', (data) => {
    const { sessionId, issueType, description } = data;
    
    if (!socket.callSessionId || socket.callSessionId !== sessionId) {
      return;
    }

    console.log('Connection issue reported:', {
      sessionId,
      userId: socket.userId,
      issueType,
      description,
      timestamp: new Date()
    });

    // Notify other participants about connection issues
    socket.to(`call_${sessionId}`).emit('participant_connection_issue', {
      userId: socket.userId,
      issueType,
      description
    });
  });

  // Handle disconnect from call when socket disconnects
  socket.on('disconnect', async () => {
    try {
      if (socket.callSessionId && socket.userId) {
        const callSession = await CallSession.findActiveSession(socket.callSessionId);
        if (callSession) {
          await callSession.removeParticipant(socket.userId, socket.id);
          
          // Notify other participants
          socket.to(`call_${socket.callSessionId}`).emit('user_left_call', {
            userId: socket.userId,
            socketId: socket.id,
            reason: 'disconnected'
          });
        }
      }
    } catch (error) {
      console.error('Error handling disconnect from call:', error);
    }
  });
};

module.exports = videoCallHandlers;
