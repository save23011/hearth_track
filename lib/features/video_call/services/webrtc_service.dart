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
      // Add additional public STUN servers for better connectivity
      {
        'urls': 'stun:stun.relay.metered.ca:80'
      },
    ],
    'iceCandidatePoolSize': 10,
  };

  final Map<String, dynamic> _mediaConstraints = {
    'audio': {
      'echoCancellation': true,
      'autoGainControl': true,
      'noiseSuppression': true,
      'sampleRate': 48000,
    },
    'video': {
      'width': {'min': 320, 'ideal': 640, 'max': 1280},
      'height': {'min': 240, 'ideal': 480, 'max': 720},
      'frameRate': {'min': 15, 'ideal': 24, 'max': 30},
      'facingMode': 'user',
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
    if (kIsWeb) {
      // For web, permissions are handled by getUserMedia
      // We'll handle this in startLocalStream instead
      debugPrint('Web platform: Permissions will be requested when accessing media');
      return;
    }
    
    // For mobile platforms
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

  // Test camera access without starting full stream
  Future<bool> testCameraAccess() async {
    try {
      debugPrint('Testing camera access...');
      
      // Try to get a simple video stream
      final testStream = await navigator.mediaDevices.getUserMedia({
        'video': true,
        'audio': false,
      });
      
      // Immediately stop the test stream
      testStream.getTracks().forEach((track) {
        track.stop();
      });
      testStream.dispose();
      
      debugPrint('Camera access test: SUCCESS');
      return true;
    } catch (e) {
      debugPrint('Camera access test: FAILED - $e');
      return false;
    }
  }

  // Get available camera devices
  Future<List<MediaDeviceInfo>> getCameraDevices() async {
    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      final cameras = devices.where((device) => device.kind == 'videoinput').toList();
      
      debugPrint('Found ${cameras.length} camera device(s):');
      for (var camera in cameras) {
        debugPrint('  - ${camera.label.isNotEmpty ? camera.label : 'Camera'} (${camera.deviceId})');
      }
      
      return cameras;
    } catch (e) {
      debugPrint('Error enumerating camera devices: $e');
      return [];
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
        // Regular video/audio configuration - always try to get both initially
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

      // If video is disabled, disable the video tracks but keep the stream
      if (!video && _localStream != null) {
        final videoTracks = _localStream!.getVideoTracks();
        for (final track in videoTracks) {
          track.enabled = false;
          debugPrint('Disabled video track: ${track.id}');
        }
      }

      // If audio is disabled, disable the audio tracks but keep the stream
      if (!audio && _localStream != null) {
        final audioTracks = _localStream!.getAudioTracks();
        for (final track in audioTracks) {
          track.enabled = false;
          debugPrint('Disabled audio track: ${track.id}');
        }
      }

      if (_localRenderer != null) {
        _localRenderer!.srcObject = _localStream;
        _localRendererController.add(_localRenderer);
      }

      debugPrint('Local stream started successfully');
      debugPrint('Video tracks: ${_localStream?.getVideoTracks().length}, Audio tracks: ${_localStream?.getAudioTracks().length}');
    } catch (e) {
      debugPrint('Error starting local stream: $e');
      
      // If we can't get video+audio, try audio only
      if (video && audio) {
        debugPrint('Retrying with audio only...');
        try {
          _localStream = await navigator.mediaDevices.getUserMedia({
            'audio': _mediaConstraints['audio'],
            'video': false,
          });
          
          if (_localRenderer != null) {
            _localRenderer!.srcObject = _localStream;
            _localRendererController.add(_localRenderer);
          }
          
          debugPrint('Local stream started with audio only');
          return;
        } catch (audioError) {
          debugPrint('Failed to get audio-only stream: $audioError');
        }
      }
      
      // Provide more specific error messages for camera issues
      String errorMessage;
      if (e.toString().contains('NotAllowedError') || e.toString().contains('Permission denied')) {
        errorMessage = 'Camera permission denied. Please allow camera access in your browser settings and refresh the page.';
      } else if (e.toString().contains('NotFoundError') || e.toString().contains('Requested device not found')) {
        errorMessage = 'No camera found. Please connect a camera and try again.';
      } else if (e.toString().contains('NotReadableError') || e.toString().contains('Could not start video source')) {
        errorMessage = 'Camera is already in use by another application. Please close other applications using the camera and try again.';
      } else if (e.toString().contains('OverconstrainedError')) {
        errorMessage = 'Camera does not support the requested video settings. Please try with different settings.';
      } else if (e.toString().contains('AbortError')) {
        errorMessage = 'Camera access was aborted. Please try again.';
      } else {
        errorMessage = 'Failed to access camera: $e';
      }
      
      throw Exception(errorMessage);
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
  Future<RTCPeerConnection> createPeerConnectionForParticipant(String participantId) async {
    if (!_isInitialized) {
      throw Exception('WebRTC not initialized');
    }

    try {
      debugPrint('Creating peer connection for participant: $participantId');
      
      // Create peer connection using flutter_webrtc global function  
      final pc = await createPeerConnection(_configuration);

      // Set up event handlers before adding local stream
      
      // Handle remote stream using modern onTrack API
      pc.onTrack = (RTCTrackEvent event) {
        debugPrint('Received track from $participantId');
        debugPrint('Track kind: ${event.track.kind}');
        debugPrint('Track enabled: ${event.track.enabled}');
        debugPrint('Streams count: ${event.streams.length}');
        
        if (event.streams.isNotEmpty) {
          final stream = event.streams.first;
          debugPrint('Stream ID: ${stream.id}');
          debugPrint('Stream has ${stream.getVideoTracks().length} video tracks, ${stream.getAudioTracks().length} audio tracks');
          
          // Validate stream before handling
          if (stream.getVideoTracks().isEmpty && stream.getAudioTracks().isEmpty) {
            debugPrint('WARNING: Received empty stream from $participantId');
            return;
          }
          
          _handleRemoteStream(participantId, stream);
        } else {
          debugPrint('WARNING: Track event has no streams for $participantId');
        }
      };

      // Keep legacy onAddStream for compatibility
      pc.onAddStream = (stream) {
        debugPrint('LEGACY: Received remote stream from $participantId');
        debugPrint('LEGACY: Remote stream has ${stream.getVideoTracks().length} video tracks, ${stream.getAudioTracks().length} audio tracks');
        
        // Validate stream before handling
        if (stream.getVideoTracks().isEmpty && stream.getAudioTracks().isEmpty) {
          debugPrint('WARNING: LEGACY: Received empty stream from $participantId');
          return;
        }
        
        _handleRemoteStream(participantId, stream);
      };

      // Handle ICE candidates
      pc.onIceCandidate = (candidate) {
        debugPrint('Generated ICE candidate for $participantId: ${candidate.candidate}');
        _handleIceCandidate(participantId, candidate);
      };

      // Handle connection state changes
      pc.onConnectionState = (state) {
        debugPrint('Peer connection state for $participantId: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          debugPrint('Peer connection failed for $participantId - but keeping it for potential recovery');
          // Don't immediately remove - let higher level logic handle it
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          debugPrint('Peer connection closed for $participantId');
          // Only remove if explicitly closed
          _removePeerConnection(participantId);
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          debugPrint('✅ Peer connection established successfully for $participantId');
        }
      };

      // Handle ICE connection state changes
      pc.onIceConnectionState = (state) {
        debugPrint('ICE connection state for $participantId: $state');
      };

      // Add local stream to peer connection if available
      if (_localStream != null) {
        debugPrint('Adding local stream tracks to peer connection for $participantId');
        _localStream!.getTracks().forEach((track) {
          debugPrint('Adding track: ${track.kind} (enabled: ${track.enabled})');
          pc.addTrack(track, _localStream!);
        });
      } else {
        debugPrint('Warning: No local stream available, but peer connection will still work for receiving remote streams');
        // Note: Even without local stream, the peer connection can still receive remote streams
      }

      _peerConnections[participantId] = pc;
      debugPrint('Peer connection created successfully for $participantId');
      return pc;
    } catch (e) {
      debugPrint('Error creating peer connection for $participantId: $e');
      throw Exception('Failed to create peer connection: $e');
    }
  }

  // Handle remote stream
  void _handleRemoteStream(String participantId, MediaStream stream) async {
    try {
      debugPrint('Handling remote stream for participant: $participantId');
      debugPrint('Stream ID: ${stream.id}');
      debugPrint('Stream has ${stream.getVideoTracks().length} video tracks and ${stream.getAudioTracks().length} audio tracks');
      
      // Log track details
      stream.getVideoTracks().forEach((track) {
        debugPrint('Video track: ${track.id}, enabled: ${track.enabled}, muted: ${track.muted}');
      });
      
      stream.getAudioTracks().forEach((track) {
        debugPrint('Audio track: ${track.id}, enabled: ${track.enabled}, muted: ${track.muted}');
      });

      // Check if we already have a renderer for this participant
      if (_remoteRenderers.containsKey(participantId)) {
        debugPrint('Disposing existing renderer for $participantId');
        await _remoteRenderers[participantId]!.dispose();
      }
      
      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      
      debugPrint('Setting stream to renderer for $participantId');
      
      // Set the stream to the renderer
      renderer.srcObject = stream;
      
      // Add a small delay to ensure the renderer is properly initialized
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify the renderer has the stream
      if (renderer.srcObject == null) {
        debugPrint('ERROR: Renderer srcObject is null after setting stream for $participantId');
        return;
      }

      _remoteRenderers[participantId] = renderer;
      
      debugPrint('Remote renderer successfully created for $participantId');
      debugPrint('Renderer video width: ${renderer.videoWidth}, height: ${renderer.videoHeight}');
      
      // Notify listeners about the update with a small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 100));
      _remoteRenderersController.add(Map.from(_remoteRenderers));

      debugPrint('Remote stream successfully added for participant: $participantId');
      debugPrint('Total remote renderers: ${_remoteRenderers.length}');
      debugPrint('Remote renderers keys: ${_remoteRenderers.keys.toList()}');
      
      // Log all current remote streams for debugging
      _remoteRenderers.forEach((key, renderer) {
        debugPrint('Remote renderer [$key]: srcObject=${renderer.srcObject != null}, videoTracks=${renderer.srcObject?.getVideoTracks().length ?? 0}');
      });
      
    } catch (e) {
      debugPrint('Error handling remote stream for $participantId: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  // Handle ICE candidate (integrate with signaling)
  void _handleIceCandidate(String participantId, RTCIceCandidate candidate) {
    // This will be handled by the signaling service
    debugPrint('ICE candidate for $participantId: ${candidate.toMap()}');
    
    // We need to send this to the signaling service
    // This will be called from outside
    _onIceCandidate?.call(participantId, candidate);
  }

  // Callback for ICE candidates
  Function(String, RTCIceCandidate)? _onIceCandidate;
  
  // Set ICE candidate callback
  void setOnIceCandidate(Function(String, RTCIceCandidate) callback) {
    _onIceCandidate = callback;
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

  // Get peer connection info for debugging
  Map<String, dynamic> getPeerConnectionInfo() {
    final info = <String, dynamic>{};
    for (final entry in _peerConnections.entries) {
      final peerId = entry.key;
      final pc = entry.value;
      info[peerId] = {
        'connectionState': pc.connectionState?.toString(),
        'iceConnectionState': pc.iceConnectionState?.toString(),
        'signalingState': pc.signalingState?.toString(),
      };
    }
    return info;
  }

  // Force renegotiation for all peer connections
  Future<void> renegotiateAllConnections() async {
    debugPrint('Renegotiating all peer connections...');
    for (final entry in _peerConnections.entries) {
      final peerId = entry.key;
      final pc = entry.value;
      try {
        debugPrint('Renegotiating connection with $peerId');
        // Create new offer
        final offer = await pc.createOffer();
        await pc.setLocalDescription(offer);
        // Note: The offer would need to be sent via the signaling service
        debugPrint('Created new offer for $peerId');
      } catch (e) {
        debugPrint('Error renegotiating with $peerId: $e');
      }
    }
  }

  // Get peer connections information for debugging
  Map<String, String> get peerConnectionStates {
    final states = <String, String>{};
    _peerConnections.forEach((participantId, pc) {
      states[participantId] = pc.connectionState?.toString() ?? 'Unknown';
    });
    return states;
  }

  // Check if we have a peer connection for a participant
  bool hasPeerConnection(String participantId) {
    return _peerConnections.containsKey(participantId);
  }

  // Remove peer connection for a participant (public method)
  Future<void> removePeerConnection(String participantId) async {
    debugPrint('Removing peer connection for: $participantId');
    await _removePeerConnection(participantId);
  }

  // Remove peer connection (private method)
  Future<void> _removePeerConnection(String participantId) async {
    final pc = _peerConnections.remove(participantId);
    if (pc != null) {
      await pc.close();
    }

    final renderer = _remoteRenderers.remove(participantId);
    if (renderer != null) {
      await renderer.dispose();
    }

    _remoteRenderersController.add(Map.from(_remoteRenderers));
    debugPrint('Peer connection removed for: $participantId');
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
