# Video Calling Features Documentation

## Overview

This document describes the video calling functionality implemented in the Hearth Track backend, supporting one-to-one and group video calls using WebRTC technology with STUN servers for NAT traversal.

## Features

### Call Types
- **One-to-One Calls**: Direct video calls between two users
- **Group Calls**: Multi-party video calls supporting up to 8 participants
- **Therapy Sessions**: Integrated video calls within therapy sessions

### Supported Features
- Real-time video and audio communication
- Screen sharing capabilities
- Media controls (mute/unmute audio, enable/disable video)
- Call history and session management
- Connection quality monitoring
- Automatic reconnection handling

## Architecture

### Backend Components

1. **Models**
   - `CallSession.js`: Manages call session data, participants, and metadata

2. **Routes**
   - `videoCall.js`: RESTful API endpoints for call management

3. **Socket Handlers**
   - `videoCallHandlers.js`: Real-time WebRTC signaling and events

4. **Services**
   - `webRTCService.js`: WebRTC peer connection management utility

### Database Schema

```javascript
CallSession {
  sessionId: String (unique),
  sessionType: 'one-to-one' | 'group' | 'therapy',
  initiatorId: ObjectId (User),
  participants: [{
    userId: ObjectId (User),
    socketId: String,
    peerId: String,
    joinedAt: Date,
    leftAt: Date,
    isActive: Boolean,
    hasVideo: Boolean,
    hasAudio: Boolean,
    isScreenSharing: Boolean
  }],
  maxParticipants: Number,
  status: 'waiting' | 'active' | 'ended',
  startTime: Date,
  endTime: Date,
  duration: Number (seconds),
  callSettings: {
    isVideoEnabled: Boolean,
    isAudioEnabled: Boolean,
    isRecordingEnabled: Boolean,
    allowScreenShare: Boolean
  },
  therapySessionId: ObjectId (optional),
  metadata: {
    title: String,
    description: String,
    tags: [String]
  }
}
```

## API Endpoints

### 1. Initiate Call
```
POST /api/video-call/initiate
```

**Request Body:**
```json
{
  "sessionType": "one-to-one | group | therapy",
  "participants": ["userId1", "userId2"],
  "callSettings": {
    "isVideoEnabled": true,
    "isAudioEnabled": true,
    "allowScreenShare": true
  },
  "metadata": {
    "title": "Call Title",
    "description": "Call Description"
  },
  "therapySessionId": "optional-therapy-session-id"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Call session initiated successfully",
  "data": {
    "sessionId": "call_1234567890_abcdef123",
    "iceServers": [...],
    "callSettings": {...}
  }
}
```

### 2. Join Call
```
POST /api/video-call/join/:sessionId
```

**Response:**
```json
{
  "success": true,
  "message": "Ready to join call session",
  "data": {
    "sessionId": "call_1234567890_abcdef123",
    "sessionType": "group",
    "participants": [...],
    "callSettings": {...},
    "iceServers": [...]
  }
}
```

### 3. Get Session Details
```
GET /api/video-call/session/:sessionId
```

### 4. Update Media Settings
```
PUT /api/video-call/session/:sessionId/media
```

**Request Body:**
```json
{
  "hasVideo": true,
  "hasAudio": false,
  "isScreenSharing": false
}
```

### 5. End Call
```
POST /api/video-call/session/:sessionId/end
```

### 6. Get Call History
```
GET /api/video-call/history?page=1&limit=20&status=ended
```

## Socket Events

### Client to Server Events

#### Authentication
```javascript
socket.emit('authenticate', token);
```

#### Join Call Session
```javascript
socket.emit('join_call_session', {
  sessionId: 'call_1234567890_abcdef123',
  peerId: 'peer_unique_id'
});
```

#### Leave Call Session
```javascript
socket.emit('leave_call_session', {
  sessionId: 'call_1234567890_abcdef123'
});
```

#### WebRTC Signaling
```javascript
// Send offer
socket.emit('webrtc_offer', {
  targetSocketId: 'target_socket_id',
  sessionId: 'call_session_id',
  offer: rtcOffer
});

// Send answer
socket.emit('webrtc_answer', {
  targetSocketId: 'target_socket_id',
  sessionId: 'call_session_id',
  answer: rtcAnswer
});

// Send ICE candidate
socket.emit('webrtc_ice_candidate', {
  targetSocketId: 'target_socket_id',
  sessionId: 'call_session_id',
  candidate: iceCandidate
});
```

#### Media State Changes
```javascript
socket.emit('media_state_changed', {
  sessionId: 'call_session_id',
  hasVideo: true,
  hasAudio: false,
  isScreenSharing: false
});
```

### Server to Client Events

#### Call Invitation
```javascript
socket.on('call_invitation', (data) => {
  // Handle incoming call invitation
  console.log(data.initiator, data.sessionType);
});
```

#### Session Joined
```javascript
socket.on('call_session_joined', (data) => {
  // Handle successful session join
  console.log(data.participants);
});
```

#### User Joined/Left
```javascript
socket.on('user_joined_call', (data) => {
  // Handle new participant joining
});

socket.on('user_left_call', (data) => {
  // Handle participant leaving
});
```

#### WebRTC Signaling
```javascript
socket.on('webrtc_offer', (data) => {
  // Handle incoming offer
});

socket.on('webrtc_answer', (data) => {
  // Handle incoming answer
});

socket.on('webrtc_ice_candidate', (data) => {
  // Handle incoming ICE candidate
});
```

## WebRTC Configuration

### STUN Servers
The system uses multiple STUN servers for reliability:
- Google STUN servers (stun.l.google.com:19302)
- Mozilla STUN server (stun.services.mozilla.com)
- STUN Protocol server (stun.stunprotocol.org:3478)

### Media Constraints
```javascript
// Video call constraints
{
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
}

// Screen sharing constraints
{
  video: {
    mediaSource: 'screen',
    width: { max: 1920 },
    height: { max: 1080 },
    frameRate: { max: 15 }
  },
  audio: false
}
```

## Error Handling

### Common Error Scenarios
1. **Authentication Errors**: User not authenticated
2. **Session Not Found**: Call session doesn't exist or has ended
3. **Permission Denied**: User not authorized to join/control session
4. **Session Full**: Maximum participants reached
5. **Connection Issues**: WebRTC connection failures

### Error Response Format
```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message (development only)"
}
```

## Security Considerations

1. **Authentication**: All API endpoints require valid JWT token
2. **Authorization**: Users can only join calls they're invited to
3. **Input Validation**: All inputs are validated using express-validator
4. **Rate Limiting**: API endpoints are rate-limited to prevent abuse
5. **CORS**: Properly configured CORS for frontend integration

## Performance Optimization

1. **Connection Pooling**: Efficient WebSocket connection management
2. **Cleanup**: Automatic cleanup of inactive connections every 30 seconds
3. **Media Optimization**: Adaptive bitrate based on network conditions
4. **Load Balancing**: Ready for horizontal scaling with socket.io-redis

## Monitoring and Analytics

### Call Quality Metrics
- Connection establishment time
- Audio/video quality scores
- Packet loss rates
- Network latency measurements

### Usage Analytics
- Call duration statistics
- Peak usage times
- Feature usage patterns
- Error rate monitoring

## Deployment Considerations

### Environment Variables
```env
# WebRTC Configuration
STUN_SERVERS=stun:stun.l.google.com:19302,stun:stun.services.mozilla.com
TURN_SERVER_URL=turn:your-turn-server.com:3478
TURN_USERNAME=your-username
TURN_PASSWORD=your-password

# Call Settings
MAX_CALL_PARTICIPANTS=8
CALL_TIMEOUT_MINUTES=60
```

### Production Setup
1. **TURN Servers**: Configure TURN servers for corporate networks
2. **Media Servers**: Consider using media servers for large group calls
3. **CDN**: Use CDN for frontend static assets
4. **Monitoring**: Set up call quality monitoring and alerting

## Integration Examples

### Frontend Integration (React/Flutter)

#### Initiating a Call
```javascript
const initiateCall = async (participants, sessionType = 'group') => {
  const response = await fetch('/api/video-call/initiate', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      sessionType,
      participants,
      callSettings: {
        isVideoEnabled: true,
        isAudioEnabled: true,
        allowScreenShare: true
      }
    })
  });
  
  const data = await response.json();
  return data.data.sessionId;
};
```

#### Joining a Call
```javascript
const joinCall = (sessionId, socket) => {
  socket.emit('join_call_session', {
    sessionId,
    peerId: generatePeerId()
  });
};
```

## Future Enhancements

1. **Recording**: Call recording and playback functionality
2. **Breakout Rooms**: Support for breakout rooms in group calls
3. **Chat Integration**: In-call text messaging
4. **AI Features**: Real-time transcription and sentiment analysis
5. **Mobile Optimization**: Enhanced mobile app integration
6. **Bandwidth Adaptation**: Dynamic quality adjustment based on network
