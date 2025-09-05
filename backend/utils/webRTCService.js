const SimplePeer = require('simple-peer');

class WebRTCService {
  constructor() {
    this.peers = new Map(); // Store peer connections
    this.rooms = new Map(); // Store room participants
  }

  // STUN/TURN servers configuration
  getIceServers() {
    return [
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
      },
      // Add TURN servers for production (requires credentials)
      // {
      //   urls: 'turn:your-turn-server.com:3478',
      //   username: 'your-username',
      //   credential: 'your-password'
      // }
    ];
  }

  // Create a new peer connection
  createPeerConnection(socketId, options = {}) {
    const config = {
      config: {
        iceServers: this.getIceServers()
      },
      initiator: options.initiator || false,
      trickle: true,
      stream: options.stream || null,
      ...options
    };

    const peer = new SimplePeer(config);
    this.peers.set(socketId, peer);

    // Handle peer events
    peer.on('error', (err) => {
      console.error(`Peer error for ${socketId}:`, err);
      this.removePeer(socketId);
    });

    peer.on('close', () => {
      console.log(`Peer connection closed for ${socketId}`);
      this.removePeer(socketId);
    });

    return peer;
  }

  // Get peer connection
  getPeer(socketId) {
    return this.peers.get(socketId);
  }

  // Remove peer connection
  removePeer(socketId) {
    const peer = this.peers.get(socketId);
    if (peer) {
      try {
        peer.destroy();
      } catch (err) {
        console.error('Error destroying peer:', err);
      }
      this.peers.delete(socketId);
    }
  }

  // Add participant to room
  addToRoom(roomId, socketId, userData) {
    if (!this.rooms.has(roomId)) {
      this.rooms.set(roomId, new Map());
    }
    
    const room = this.rooms.get(roomId);
    room.set(socketId, {
      ...userData,
      joinedAt: new Date()
    });

    return room;
  }

  // Remove participant from room
  removeFromRoom(roomId, socketId) {
    const room = this.rooms.get(roomId);
    if (room) {
      room.delete(socketId);
      
      // Remove room if empty
      if (room.size === 0) {
        this.rooms.delete(roomId);
      }
    }

    // Also remove peer connection
    this.removePeer(socketId);
  }

  // Get room participants
  getRoomParticipants(roomId) {
    const room = this.rooms.get(roomId);
    return room ? Array.from(room.entries()) : [];
  }

  // Get room participant count
  getRoomParticipantCount(roomId) {
    const room = this.rooms.get(roomId);
    return room ? room.size : 0;
  }

  // Check if room exists
  roomExists(roomId) {
    return this.rooms.has(roomId);
  }

  // Get all rooms
  getAllRooms() {
    return Array.from(this.rooms.keys());
  }

  // Clean up inactive connections
  cleanup() {
    // Remove peers that are no longer connected
    for (const [socketId, peer] of this.peers.entries()) {
      if (peer.destroyed) {
        this.peers.delete(socketId);
      }
    }

    // Remove empty rooms
    for (const [roomId, room] of this.rooms.entries()) {
      if (room.size === 0) {
        this.rooms.delete(roomId);
      }
    }
  }

  // Get connection statistics
  getStats() {
    return {
      totalPeers: this.peers.size,
      totalRooms: this.rooms.size,
      rooms: Array.from(this.rooms.entries()).map(([roomId, participants]) => ({
        roomId,
        participantCount: participants.size,
        participants: Array.from(participants.keys())
      }))
    };
  }

  // Handle media constraints for different call types
  getMediaConstraints(callType = 'video') {
    const constraints = {
      video: {
        video: {
          width: { min: 320, ideal: 640, max: 1280 },
          height: { min: 240, ideal: 480, max: 720 },
          frameRate: { min: 15, ideal: 24, max: 30 }
        },
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true
        }
      },
      audio: {
        video: false,
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true
        }
      },
      screen: {
        video: {
          mediaSource: 'screen',
          width: { max: 1920 },
          height: { max: 1080 },
          frameRate: { max: 15 }
        },
        audio: false
      }
    };

    return constraints[callType] || constraints.video;
  }

  // Generate unique room ID
  generateRoomId(prefix = 'room') {
    const timestamp = Date.now();
    const randomStr = Math.random().toString(36).substr(2, 9);
    return `${prefix}_${timestamp}_${randomStr}`;
  }

  // Validate peer connection state
  validatePeerConnection(socketId) {
    const peer = this.getPeer(socketId);
    if (!peer) {
      return { valid: false, reason: 'Peer not found' };
    }

    if (peer.destroyed) {
      return { valid: false, reason: 'Peer connection destroyed' };
    }

    return { valid: true };
  }
}

// Create singleton instance
const webRTCService = new WebRTCService();

// Clean up inactive connections periodically
setInterval(() => {
  webRTCService.cleanup();
}, 30000); // Every 30 seconds

module.exports = webRTCService;
