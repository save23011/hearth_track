# Video Calling Feature for Hearth Track

This document explains the WebRTC-based video calling feature implemented for the Hearth Track Flutter application.

## Overview

The video calling feature enables secure peer-to-peer video communication between users, particularly designed for virtual therapy sessions and consultations. It uses WebRTC technology for real-time communication and Socket.IO for signaling.

## Architecture

### Backend Components
- **WebRTC Service** (`backend/utils/webRTCService.js`): Manages peer connections and room participants
- **Socket Handlers** (`backend/sockets/videoCallHandlers.js`): Handles real-time signaling events
- **Call Session Model** (`backend/models/CallSession.js`): Database model for call sessions

### Frontend Components

#### Models
- **CallParticipant** (`lib/features/video_call/models/call_participant.dart`): Represents a call participant
- **CallSession** (`lib/features/video_call/models/call_session.dart`): Represents a video call session
- **SignalingMessage** (`lib/features/video_call/models/signaling_message.dart`): WebRTC signaling messages

#### Services
- **WebRTCService** (`lib/features/video_call/services/webrtc_service.dart`): Manages WebRTC connections, media streams, and peer connections
- **SignalingService** (`lib/features/video_call/services/signaling_service.dart`): Handles Socket.IO communication with backend

#### State Management
- **VideoCallProvider** (`lib/features/video_call/providers/video_call_provider.dart`): Riverpod provider for managing video call state

#### UI Components
- **CallInitiationScreen**: Main entry point for starting or joining video calls
- **VideoCallScreen**: The main video calling interface
- **VideoCallGrid**: Displays participant video feeds in a responsive grid
- **VideoCallControls**: Control buttons for video, audio, screen sharing, etc.
- **ParticipantVideoView**: Individual participant video display

## Features

### Core Functionality
- ✅ Join existing call sessions
- ✅ Create new call sessions
- ✅ Real-time video and audio streaming
- ✅ Multiple participant support (up to 10 participants)
- ✅ Responsive grid layout for different participant counts
- ✅ Video/audio toggle controls
- ✅ Screen sharing support
- ✅ Connection state management
- ✅ Error handling and recovery

### UI Features
- ✅ Modern, clean interface
- ✅ Participant avatars when video is disabled
- ✅ Mute/unmute indicators
- ✅ Screen sharing indicators
- ✅ Connection status display
- ✅ Loading states and error messages

### Permissions
- ✅ Camera permission handling
- ✅ Microphone permission handling
- ✅ Runtime permission requests

## Usage

### From Dashboard
1. Navigate to the Dashboard screen
2. Look for the "Video Consultation" section
3. Click "Start Video Call" to access the video calling feature

### Direct Navigation
Navigate to `/video_call` route to access the call initiation screen directly.

### Starting a Call
1. Enter the backend server URL (default: http://localhost:3000)
2. Either:
   - Enter an existing session ID to join a call
   - Click "Create New Call" to generate a new session
3. The app will request camera and microphone permissions
4. Once connected, you'll see the video call interface

### During a Call
- **Toggle Video**: Turn camera on/off
- **Toggle Audio**: Mute/unmute microphone
- **Screen Share**: Share your screen (mobile platforms may have limitations)
- **End Call**: Leave the current call session

## Configuration

### Backend Configuration
Ensure your backend server is running with the video calling endpoints enabled. The default configuration expects the server at `http://localhost:3000`.

### STUN/TURN Servers
The app uses Google's public STUN servers by default. For production, consider adding TURN servers for better connectivity:

```dart
// In webrtc_service.dart
final Map<String, dynamic> _configuration = {
  'iceServers': [
    // STUN servers
    {
      'urls': [
        'stun:stun.l.google.com:19302',
        // ... other STUN servers
      ]
    },
    // TURN servers (add for production)
    {
      'urls': 'turn:your-turn-server.com:3478',
      'username': 'your-username',
      'credential': 'your-password'
    },
  ],
};
```

## Dependencies

### New Dependencies Added
```yaml
# WebRTC & Video Calling
flutter_webrtc: ^0.9.48
socket_io_client: ^2.0.3+1
permission_handler: ^11.0.1
```

## Testing

### Testing the Feature
1. Start the backend server:
   ```bash
   cd backend
   npm run dev
   ```

2. Run the Flutter app:
   ```bash
   flutter run
   ```

3. Create a call session and test with multiple devices/emulators

### Backend Testing
The backend includes test files for video call functionality:
- `backend/test/videoCall.test.js`

## Known Limitations

### Current Limitations
- Camera switching not fully implemented
- Recording functionality not implemented
- Mobile screen sharing has platform limitations
- No background blur/virtual backgrounds
- No chat functionality during calls

### Future Enhancements
- [ ] Camera switching
- [ ] Call recording
- [ ] Virtual backgrounds
- [ ] In-call chat
- [ ] Call statistics/quality indicators
- [ ] Bandwidth adaptation
- [ ] Reconnection handling
- [ ] Multi-language support

## Troubleshooting

### Common Issues

1. **Permissions Denied**
   - Ensure camera and microphone permissions are granted
   - Check device privacy settings

2. **Connection Issues**
   - Verify backend server is running
   - Check network connectivity
   - Ensure WebSocket connections are not blocked

3. **Video Not Showing**
   - Check camera permissions
   - Verify video toggle state
   - Try restarting the call

4. **Audio Issues**
   - Check microphone permissions
   - Verify audio toggle state
   - Check device audio settings

### Debug Mode
The services include extensive logging. Enable debug mode to see detailed logs:
```dart
import 'package:flutter/foundation.dart';

// Logs are automatically shown in debug mode
debugPrint('Your debug message');
```

## Security Considerations

- All WebRTC connections use DTLS encryption by default
- Signaling is authenticated via Socket.IO with token-based auth
- Consider implementing additional encryption for sensitive healthcare data
- Use HTTPS/WSS in production environments
- Implement proper session management and timeout handling

## Support

For issues or questions regarding the video calling feature, check:
1. Flutter WebRTC documentation
2. Socket.IO client documentation
3. The backend video calling documentation in `backend/VIDEO_CALLING_DOCS.md`
