import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call_session.dart';
import '../models/call_participant.dart';
import 'webrtc_service.dart';

class SignalingService {
  static final SignalingService _instance = SignalingService._internal();
  factory SignalingService() => _instance;
  SignalingService._internal();

  io.Socket? _socket;
  final WebRTCService _webrtcService = WebRTCService();
  
  // State management
  String? _currentSessionId;
  bool _isConnected = false;

  // Stream controllers
  final StreamController<CallSession> _callSessionController =
      StreamController<CallSession>.broadcast();
  final StreamController<CallParticipant> _participantJoinedController =
      StreamController<CallParticipant>.broadcast();
  final StreamController<String> _participantLeftController =
      StreamController<String>.broadcast();
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Getters for streams
  Stream<CallSession> get callSessionStream => _callSessionController.stream;
  Stream<CallParticipant> get participantJoinedStream => _participantJoinedController.stream;
  Stream<String> get participantLeftStream => _participantLeftController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // Getters for state
  bool get isConnected => _isConnected;
  String? get currentSessionId => _currentSessionId;

  // Initialize signaling service
  Future<void> initialize(String serverUrl, String userId, String token) async {
    try {
      // Set up ICE candidate callback
      _webrtcService.setOnIceCandidate((participantId, candidate) {
        sendIceCandidate(participantId, candidate);
      });

      // Configure socket with improved settings
      _socket = io.io(serverUrl, <String, dynamic>{
        'transports': ['websocket'],
        'auth': {
          'token': token,
          'userId': userId,
        },
        'autoConnect': false,
        'timeout': 20000, // 20 second timeout
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
      });

      _setupSocketListeners();
      
      // Set up connection timeout
      Timer? connectionTimeout;
      
      // Create a completer to handle connection
      final completer = Completer<void>();
      
      // Listen for successful connection
      _socket!.on('connect', (_) {
        debugPrint('Socket connected to server');
        connectionTimeout?.cancel();
        if (!completer.isCompleted) {
          _isConnected = true;
          _connectionStateController.add(_isConnected);
          // Authenticate immediately after connection
          _socket!.emit('authenticate', token);
        }
      });
      
      // Listen for authentication success (if server implements it)
      _socket!.on('authenticated', (data) {
        debugPrint('Socket authenticated successfully: $data');
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      
      // Listen for authentication error
      _socket!.on('authentication_error', (error) {
        debugPrint('Socket authentication failed: $error');
        if (!completer.isCompleted) {
          completer.completeError(Exception('Authentication failed: $error'));
        }
      });
      
      // Handle connection errors
      _socket!.on('connect_error', (error) {
        debugPrint('Socket connection error: $error');
        if (!completer.isCompleted) {
          completer.completeError(Exception('Connection failed: $error'));
        }
      });
      
      // Set connection timeout (increased to 20 seconds)
      connectionTimeout = Timer(const Duration(seconds: 20), () {
        if (!completer.isCompleted) {
          _socket?.disconnect();
          completer.completeError(Exception('Connection timeout - please check your internet connection and server status'));
        }
      });
      
      _socket!.connect();
      
      // Wait for authentication to complete
      await completer.future;
      
      debugPrint('Signaling service initialized and authenticated');
    } catch (e) {
      debugPrint('Error initializing signaling service: $e');
      _errorController.add('Failed to initialize signaling: $e');
      throw Exception('Failed to initialize signaling service: $e');
    }
  }

  // Setup socket event listeners
  void _setupSocketListeners() {
    _socket!.on('connect', (_) {
      _isConnected = true;
      _connectionStateController.add(_isConnected);
      debugPrint('Connected to signaling server');
    });

    _socket!.on('disconnect', (_) {
      _isConnected = false;
      _connectionStateController.add(_isConnected);
      debugPrint('Disconnected from signaling server');
    });

    _socket!.on('connect_error', (error) {
      debugPrint('Connection error: $error');
      _errorController.add('Connection error: $error');
    });

    // Call session events
    _socket!.on('call_session_joined', _handleCallSessionJoined);
    _socket!.on('user_joined_call', _handleUserJoinedCall);
    _socket!.on('user_left_call', _handleUserLeftCall);
    _socket!.on('call_ended', _handleCallEnded);
    _socket!.on('call_error', _handleCallError);

    // WebRTC signaling events
    _socket!.on('webrtc_offer', _handleWebRTCOffer);
    _socket!.on('webrtc_answer', _handleWebRTCAnswer);
    _socket!.on('webrtc_ice_candidate', _handleWebRTCIceCandidate);

    // Media control events
    _socket!.on('participant_toggled_video', _handleParticipantToggledVideo);
    _socket!.on('participant_toggled_audio', _handleParticipantToggledAudio);
    _socket!.on('participant_screen_share', _handleParticipantScreenShare);
    
    // WebRTC initiation event
    _socket!.on('initiate_peer_connection', _handleInitiatePeerConnection);
  }

  // Join a call session
  Future<void> joinCallSession(String sessionId, String peerId) async {
    if (!_isConnected) {
      throw Exception('Not connected to signaling server');
    }

    try {
      _currentSessionId = sessionId;
      
      // Wait for confirmation that we joined the call session
      final completer = Completer<void>();
      
      // Listen for successful join
      void handleCallSessionJoined(dynamic data) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
      
      // Listen for errors
      void handleCallError(dynamic data) {
        if (!completer.isCompleted) {
          final message = data['message'] as String? ?? 'Unknown error';
          completer.completeError(Exception(message));
        }
      }
      
      _socket!.on('call_session_joined', handleCallSessionJoined);
      _socket!.on('call_error', handleCallError);
      
      _socket!.emit('join_call_session', {
        'sessionId': sessionId,
        'peerId': peerId,
      });

      // Wait for confirmation with timeout
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout joining call session'),
      );
      
      // Clean up listeners
      _socket!.off('call_session_joined', handleCallSessionJoined);
      _socket!.off('call_error', handleCallError);

      debugPrint('Successfully joined call session: $sessionId');
    } catch (e) {
      debugPrint('Error joining call session: $e');
      _errorController.add('Failed to join call: $e');
      rethrow;
    }
  }

  // Leave current call session
  Future<void> leaveCallSession() async {
    if (!_isConnected || _currentSessionId == null) return;

    try {
      _socket!.emit('leave_call_session', {
        'sessionId': _currentSessionId,
      });

      _currentSessionId = null;
      debugPrint('Left call session');
    } catch (e) {
      debugPrint('Error leaving call session: $e');
    }
  }

  // Send WebRTC offer
  Future<void> sendOffer(String targetPeerId, RTCSessionDescription offer) async {
    if (!_isConnected) return;

    _socket!.emit('webrtc_offer', {
      'targetPeerId': targetPeerId,
      'sessionId': _currentSessionId,
      'offer': offer.toMap(),
    });

    debugPrint('Sent offer to $targetPeerId');
  }

  // Send WebRTC answer
  Future<void> sendAnswer(String targetPeerId, RTCSessionDescription answer) async {
    if (!_isConnected) return;

    _socket!.emit('webrtc_answer', {
      'targetPeerId': targetPeerId,
      'sessionId': _currentSessionId,
      'answer': answer.toMap(),
    });

    debugPrint('Sent answer to $targetPeerId');
  }

  // Send ICE candidate
  Future<void> sendIceCandidate(String targetPeerId, RTCIceCandidate candidate) async {
    if (!_isConnected) return;

    _socket!.emit('webrtc_ice_candidate', {
      'targetPeerId': targetPeerId,
      'sessionId': _currentSessionId,
      'candidate': candidate.toMap(),
    });

    debugPrint('Sent ICE candidate to $targetPeerId');
  }

  // Toggle video and notify other participants
  Future<void> toggleVideo() async {
    if (!_isConnected || _currentSessionId == null) return;

    await _webrtcService.toggleVideo();
    
    _socket!.emit('toggle_video', {
      'sessionId': _currentSessionId,
      'hasVideo': _webrtcService.isVideoEnabled,
    });
  }

  // Toggle audio and notify other participants
  Future<void> toggleAudio() async {
    if (!_isConnected || _currentSessionId == null) return;

    await _webrtcService.toggleAudio();
    
    _socket!.emit('toggle_audio', {
      'sessionId': _currentSessionId,
      'hasAudio': _webrtcService.isAudioEnabled,
    });
  }

  // Handle call session joined
  void _handleCallSessionJoined(dynamic data) {
    try {
      final callSession = CallSession.fromJson(data);
      _callSessionController.add(callSession);
      debugPrint('Call session joined successfully');
    } catch (e) {
      debugPrint('Error handling call session joined: $e');
      _errorController.add('Error joining call: $e');
    }
  }

  // Handle user joined call
  void _handleUserJoinedCall(dynamic data) {
    try {
      final participant = CallParticipant.fromJson(data['participant']);
      _participantJoinedController.add(participant);
      debugPrint('User joined call: ${participant.fullName}');
      debugPrint('New participant peer ID: ${participant.peerId}');
      
      // Important: When a new user joins, existing users should initiate connection
      // This will be handled by the VideoCallProvider
    } catch (e) {
      debugPrint('Error handling user joined: $e');
    }
  }

  // Handle user left call
  void _handleUserLeftCall(dynamic data) {
    try {
      final userId = data['userId'] as String;
      _participantLeftController.add(userId);
      debugPrint('User left call: $userId');
    } catch (e) {
      debugPrint('Error handling user left: $e');
    }
  }

  // Handle call ended
  void _handleCallEnded(dynamic data) {
    try {
      _currentSessionId = null;
      debugPrint('Call ended');
    } catch (e) {
      debugPrint('Error handling call ended: $e');
    }
  }

  // Handle call error
  void _handleCallError(dynamic data) {
    try {
      final message = data['message'] as String;
      _errorController.add(message);
      debugPrint('Call error: $message');
    } catch (e) {
      debugPrint('Error handling call error: $e');
    }
  }

  // Handle WebRTC offer
  void _handleWebRTCOffer(dynamic data) async {
    try {
      final fromPeerId = data['fromPeerId'] as String;
      final offerData = data['offer'] as Map<String, dynamic>;
      
      debugPrint('Received WebRTC offer from: $fromPeerId');
      debugPrint('Offer SDP length: ${(offerData['sdp'] as String).length}');
      
      final offer = RTCSessionDescription(
        offerData['sdp'] as String,
        offerData['type'] as String,
      );

      // Always create a fresh peer connection for new offers
      debugPrint('Creating new peer connection for offer from: $fromPeerId');
      
      // Remove existing connection if any
      if (_webrtcService.hasPeerConnection(fromPeerId)) {
        debugPrint('Removing existing peer connection for $fromPeerId before creating new one');
        await _webrtcService.removePeerConnection(fromPeerId);
        // Small delay after removal
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      await _webrtcService.createPeerConnectionForParticipant(fromPeerId);
      
      // Small delay to ensure peer connection is ready
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Set remote description
      debugPrint('Setting remote description for: $fromPeerId');
      await _webrtcService.setRemoteDescription(fromPeerId, offer);
      
      // Create and send answer
      debugPrint('Creating answer for: $fromPeerId');
      final answer = await _webrtcService.createAnswer(fromPeerId);
      
      debugPrint('Sending answer to: $fromPeerId');
      await sendAnswer(fromPeerId, answer);

      debugPrint('Successfully handled WebRTC offer from $fromPeerId');
    } catch (e) {
      debugPrint('Error handling WebRTC offer: $e');
      _errorController.add('Error handling call offer: $e');
    }
  }

  // Handle WebRTC answer
  void _handleWebRTCAnswer(dynamic data) async {
    try {
      final fromPeerId = data['fromPeerId'] as String;
      final answerData = data['answer'] as Map<String, dynamic>;
      
      debugPrint('Received WebRTC answer from: $fromPeerId');
      debugPrint('Answer SDP length: ${(answerData['sdp'] as String).length}');
      
      final answer = RTCSessionDescription(
        answerData['sdp'] as String,
        answerData['type'] as String,
      );

      // Set remote description
      debugPrint('Setting remote description (answer) for: $fromPeerId');
      await _webrtcService.setRemoteDescription(fromPeerId, answer);

      debugPrint('Successfully handled WebRTC answer from $fromPeerId');
    } catch (e) {
      debugPrint('Error handling WebRTC answer: $e');
      _errorController.add('Error handling call answer: $e');
    }
  }

  // Handle WebRTC ICE candidate
  void _handleWebRTCIceCandidate(dynamic data) async {
    try {
      final fromPeerId = data['fromPeerId'] as String;
      final candidateData = data['candidate'] as Map<String, dynamic>;
      
      final candidate = RTCIceCandidate(
        candidateData['candidate'] as String,
        candidateData['sdpMid'] as String?,
        candidateData['sdpMLineIndex'] as int?,
      );

      // Add ICE candidate
      await _webrtcService.addIceCandidate(fromPeerId, candidate);

      debugPrint('Handled ICE candidate from $fromPeerId');
    } catch (e) {
      debugPrint('Error handling ICE candidate: $e');
    }
  }

  // Handle participant toggled video
  void _handleParticipantToggledVideo(dynamic data) {
    try {
      final userId = data['userId'] as String;
      final hasVideo = data['hasVideo'] as bool;
      debugPrint('Participant $userId toggled video: $hasVideo');
      // This would be handled by the UI state management
    } catch (e) {
      debugPrint('Error handling participant video toggle: $e');
    }
  }

  // Handle participant toggled audio
  void _handleParticipantToggledAudio(dynamic data) {
    try {
      final userId = data['userId'] as String;
      final hasAudio = data['hasAudio'] as bool;
      debugPrint('Participant $userId toggled audio: $hasAudio');
      // This would be handled by the UI state management
    } catch (e) {
      debugPrint('Error handling participant audio toggle: $e');
    }
  }

  // Handle participant screen share
  void _handleParticipantScreenShare(dynamic data) {
    try {
      final userId = data['userId'] as String;
      final isScreenSharing = data['isScreenSharing'] as bool;
      debugPrint('Participant $userId screen sharing: $isScreenSharing');
      // This would be handled by the UI state management
    } catch (e) {
      debugPrint('Error handling participant screen share: $e');
    }
  }

  // Handle initiate peer connection
  void _handleInitiatePeerConnection(dynamic data) async {
    try {
      final targetPeerId = data['targetPeerId'] as String;
      
      debugPrint('Initiating peer connection with: $targetPeerId');
      
      // Create peer connection for the target participant
      await _webrtcService.createPeerConnectionForParticipant(targetPeerId);
      
      // Create and send offer
      final offer = await _webrtcService.createOffer(targetPeerId);
      await sendOffer(targetPeerId, offer);
      
      debugPrint('Successfully initiated peer connection with $targetPeerId');
    } catch (e) {
      debugPrint('Error initiating peer connection: $e');
      _errorController.add('Error initiating peer connection: $e');
    }
  }

  // Disconnect from signaling server
  Future<void> disconnect() async {
    try {
      if (_currentSessionId != null) {
        await leaveCallSession();
      }

      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      
      _isConnected = false;
      _currentSessionId = null;

      _connectionStateController.add(_isConnected);
      debugPrint('Disconnected from signaling server');
    } catch (e) {
      debugPrint('Error disconnecting from signaling server: $e');
    }
  }

  // Dispose signaling service
  Future<void> dispose() async {
    await disconnect();
    
    await _callSessionController.close();
    await _participantJoinedController.close();
    await _participantLeftController.close();
    await _connectionStateController.close();
    await _errorController.close();

    debugPrint('Signaling service disposed');
  }
}
