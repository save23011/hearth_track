import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  // WebRTC Configuration
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ]
      },
      {
        'urls': 'stun:stun.services.mozilla.com'
      },
    ],
  };

  final Map<String, dynamic> _mediaConstraints = {
    'audio': {
      'mandatory': {
        'googEchoCancellation': true,
        'googAutoGainControl': true,
        'googNoiseSuppression': true,
        'googHighpassFilter': true,
      },
      'optional': [],
    },
    'video': {
      'mandatory': {
        'minWidth': '320',
        'minHeight': '240',
        'minFrameRate': '15',
      },
      'facingMode': 'user',
      'optional': [],
    },
  };

  // State management
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  RTCVideoRenderer? _localRenderer;
  MediaStream? _localStream;
  bool _isInitialized = false;
  bool _isInCall = false;

  // Stream controllers for state updates
  final StreamController<Map<String, RTCVideoRenderer>> _remoteRenderersController =
      StreamController<Map<String, RTCVideoRenderer>>.broadcast();
  final StreamController<RTCVideoRenderer?> _localRendererController =
      StreamController<RTCVideoRenderer?>.broadcast();
  final StreamController<bool> _callStateController =
      StreamController<bool>.broadcast();

  // Getters for streams
  Stream<Map<String, RTCVideoRenderer>> get remoteRenderersStream =>
      _remoteRenderersController.stream;
  Stream<RTCVideoRenderer?> get localRendererStream =>
      _localRendererController.stream;
  Stream<bool> get callStateStream => _callStateController.stream;

  // Getters for current state
  Map<String, RTCVideoRenderer> get remoteRenderers => Map.from(_remoteRenderers);
  RTCVideoRenderer? get localRenderer => _localRenderer;
  bool get isInCall => _isInCall;
  bool get isInitialized => _isInitialized;

  // Initialize WebRTC
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      await _requestPermissions();

      // Create local renderer
      _localRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();

      _isInitialized = true;
      debugPrint('WebRTC Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing WebRTC: $e');
      throw Exception('Failed to initialize WebRTC: $e');
    }
  }

  // Request necessary permissions
  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
    ];

    for (final permission in permissions) {
      final status = await permission.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Permission ${permission.toString()} not granted');
      }
    }
  }

  // Start local media stream
  Future<void> startLocalStream({
    bool video = true,
    bool audio = true,
    bool screenShare = false,
  }) async {
    if (!_isInitialized) {
      throw Exception('WebRTC not initialized');
    }

    try {
      // Stop existing stream if any
      await stopLocalStream();

      Map<String, dynamic> mediaConstraints;
      
      if (screenShare) {
        // Screen sharing configuration
        mediaConstraints = {
          'audio': audio,
          'video': {
            'mandatory': {
              'chromeMediaSource': 'desktop',
              'maxWidth': 1920,
              'maxHeight': 1080,
              'maxFrameRate': 30,
            }
          }
        };
      } else {
        // Regular video/audio configuration
        mediaConstraints = {
          'audio': audio ? _mediaConstraints['audio'] : false,
          'video': video ? _mediaConstraints['video'] : false,
        };
      }

      if (screenShare && !kIsWeb) {
        // For mobile platforms, screen sharing needs special handling
        _localStream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      } else {
        _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      }

      if (_localRenderer != null) {
        _localRenderer!.srcObject = _localStream;
        _localRendererController.add(_localRenderer);
      }

      debugPrint('Local stream started successfully');
    } catch (e) {
      debugPrint('Error starting local stream: $e');
      throw Exception('Failed to start local stream: $e');
    }
  }

  // Stop local media stream
  Future<void> stopLocalStream() async {
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        track.stop();
      });
      _localStream!.dispose();
      _localStream = null;
    }

    if (_localRenderer != null) {
      _localRenderer!.srcObject = null;
      _localRendererController.add(_localRenderer);
    }
  }

  // Create peer connection for a remote participant
  Future<RTCPeerConnection> createPeerConnection(String participantId) async {
    if (!_isInitialized) {
      throw Exception('WebRTC not initialized');
    }

    try {
      // Create peer connection using flutter_webrtc 0.10.x API
      // Use the sessionId as identifier and set configuration separately
      final pc = await createPeerConnection(participantId);
      
      // Set configuration after creation
      await pc.setConfiguration(_configuration);

      // Add local stream to peer connection
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          pc.addTrack(track, _localStream!);
        });
      }

      // Handle remote stream
      pc.onAddStream = (stream) {
        _handleRemoteStream(participantId, stream);
      };

      // Handle ICE candidates
      pc.onIceCandidate = (candidate) {
        _handleIceCandidate(participantId, candidate);
      };

      // Handle connection state changes
      pc.onConnectionState = (state) {
        debugPrint('Peer connection state for $participantId: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _removePeerConnection(participantId);
        }
      };

      _peerConnections[participantId] = pc;
      return pc;
    } catch (e) {
      debugPrint('Error creating peer connection: $e');
      throw Exception('Failed to create peer connection: $e');
    }
  }

  // Handle remote stream
  void _handleRemoteStream(String participantId, MediaStream stream) async {
    try {
      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      renderer.srcObject = stream;

      _remoteRenderers[participantId] = renderer;
      _remoteRenderersController.add(Map.from(_remoteRenderers));

      debugPrint('Remote stream added for participant: $participantId');
    } catch (e) {
      debugPrint('Error handling remote stream: $e');
    }
  }

  // Handle ICE candidate (to be implemented with signaling)
  void _handleIceCandidate(String participantId, RTCIceCandidate candidate) {
    // This will be handled by the signaling service
    debugPrint('ICE candidate for $participantId: ${candidate.toMap()}');
  }

  // Create offer
  Future<RTCSessionDescription> createOffer(String participantId) async {
    final pc = _peerConnections[participantId];
    if (pc == null) {
      throw Exception('Peer connection not found for $participantId');
    }

    try {
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      return offer;
    } catch (e) {
      debugPrint('Error creating offer: $e');
      throw Exception('Failed to create offer: $e');
    }
  }

  // Create answer
  Future<RTCSessionDescription> createAnswer(String participantId) async {
    final pc = _peerConnections[participantId];
    if (pc == null) {
      throw Exception('Peer connection not found for $participantId');
    }

    try {
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      return answer;
    } catch (e) {
      debugPrint('Error creating answer: $e');
      throw Exception('Failed to create answer: $e');
    }
  }

  // Set remote description
  Future<void> setRemoteDescription(
    String participantId,
    RTCSessionDescription description,
  ) async {
    final pc = _peerConnections[participantId];
    if (pc == null) {
      throw Exception('Peer connection not found for $participantId');
    }

    try {
      await pc.setRemoteDescription(description);
    } catch (e) {
      debugPrint('Error setting remote description: $e');
      throw Exception('Failed to set remote description: $e');
    }
  }

  // Add ICE candidate
  Future<void> addIceCandidate(
    String participantId,
    RTCIceCandidate candidate,
  ) async {
    final pc = _peerConnections[participantId];
    if (pc == null) {
      debugPrint('Peer connection not found for $participantId');
      return;
    }

    try {
      await pc.addCandidate(candidate);
    } catch (e) {
      debugPrint('Error adding ICE candidate: $e');
    }
  }

  // Toggle video
  Future<void> toggleVideo() async {
    if (_localStream == null) return;

    final videoTracks = _localStream!.getVideoTracks();
    for (final track in videoTracks) {
      track.enabled = !track.enabled;
    }
  }

  // Toggle audio
  Future<void> toggleAudio() async {
    if (_localStream == null) return;

    final audioTracks = _localStream!.getAudioTracks();
    for (final track in audioTracks) {
      track.enabled = !track.enabled;
    }
  }

  // Get video enabled state
  bool get isVideoEnabled {
    if (_localStream == null) return false;
    final videoTracks = _localStream!.getVideoTracks();
    return videoTracks.isNotEmpty && videoTracks.first.enabled;
  }

  // Get audio enabled state
  bool get isAudioEnabled {
    if (_localStream == null) return false;
    final audioTracks = _localStream!.getAudioTracks();
    return audioTracks.isNotEmpty && audioTracks.first.enabled;
  }

  // Remove peer connection
  void _removePeerConnection(String participantId) {
    final pc = _peerConnections.remove(participantId);
    pc?.close();

    final renderer = _remoteRenderers.remove(participantId);
    renderer?.dispose();

    _remoteRenderersController.add(Map.from(_remoteRenderers));
  }

  // End call
  Future<void> endCall() async {
    try {
      // Close all peer connections
      for (final pc in _peerConnections.values) {
        await pc.close();
      }
      _peerConnections.clear();

      // Dispose all remote renderers
      for (final renderer in _remoteRenderers.values) {
        await renderer.dispose();
      }
      _remoteRenderers.clear();

      // Stop local stream
      await stopLocalStream();

      _isInCall = false;
      _callStateController.add(_isInCall);
      _remoteRenderersController.add({});

      debugPrint('Call ended successfully');
    } catch (e) {
      debugPrint('Error ending call: $e');
    }
  }

  // Dispose WebRTC service
  Future<void> dispose() async {
    await endCall();

    if (_localRenderer != null) {
      await _localRenderer!.dispose();
      _localRenderer = null;
    }

    await _remoteRenderersController.close();
    await _localRendererController.close();
    await _callStateController.close();

    _isInitialized = false;
    debugPrint('WebRTC Service disposed');
  }
}
