import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call_session.dart';
import '../models/call_participant.dart';
import '../services/webrtc_service.dart';
import '../services/signaling_service.dart';

// Providers
final webrtcServiceProvider = Provider<WebRTCService>((ref) {
  return WebRTCService();
});

final signalingServiceProvider = Provider<SignalingService>((ref) {
  return SignalingService();
});

final videoCallProvider = StateNotifierProvider<VideoCallNotifier, VideoCallState>((ref) {
  final webrtcService = ref.read(webrtcServiceProvider);
  final signalingService = ref.read(signalingServiceProvider);
  return VideoCallNotifier(webrtcService, signalingService);
});

// Video Call State
class VideoCallState {
  final CallSession? currentSession;
  final Map<String, RTCVideoRenderer> remoteRenderers;
  final RTCVideoRenderer? localRenderer;
  final bool isConnecting;
  final bool isInCall;
  final bool isVideoEnabled;
  final bool isAudioEnabled;
  final bool isScreenSharing;
  final String? errorMessage;
  final List<CallParticipant> participants;

  const VideoCallState({
    this.currentSession,
    this.remoteRenderers = const {},
    this.localRenderer,
    this.isConnecting = false,
    this.isInCall = false,
    this.isVideoEnabled = true,
    this.isAudioEnabled = true,
    this.isScreenSharing = false,
    this.errorMessage,
    this.participants = const [],
  });

  VideoCallState copyWith({
    CallSession? currentSession,
    Map<String, RTCVideoRenderer>? remoteRenderers,
    RTCVideoRenderer? localRenderer,
    bool? isConnecting,
    bool? isInCall,
    bool? isVideoEnabled,
    bool? isAudioEnabled,
    bool? isScreenSharing,
    String? errorMessage,
    List<CallParticipant>? participants,
    bool clearError = false,
  }) {
    return VideoCallState(
      currentSession: currentSession ?? this.currentSession,
      remoteRenderers: remoteRenderers ?? this.remoteRenderers,
      localRenderer: localRenderer ?? this.localRenderer,
      isConnecting: isConnecting ?? this.isConnecting,
      isInCall: isInCall ?? this.isInCall,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      participants: participants ?? this.participants,
    );
  }
}

// Video Call Notifier
class VideoCallNotifier extends StateNotifier<VideoCallState> {
  final WebRTCService _webrtcService;
  final SignalingService _signalingService;
  
  // Store current user info for participant identification
  String? _currentUserId;
  String? _currentPeerId;
  
  StreamSubscription? _callSessionSubscription;
  StreamSubscription? _participantJoinedSubscription;
  StreamSubscription? _participantLeftSubscription;
  StreamSubscription? _remoteRenderersSubscription;
  StreamSubscription? _localRendererSubscription;
  StreamSubscription? _errorSubscription;

  VideoCallNotifier(this._webrtcService, this._signalingService)
      : super(const VideoCallState());

  // Only setup subscriptions when explicitly initialized
  bool _isInitialized = false;

  void _initializeSubscriptions() {
    // Ensure subscriptions are not already set up
    if (_callSessionSubscription != null || _isInitialized) return;
    
    _isInitialized = true;
    // Listen to signaling service events
    _callSessionSubscription = _signalingService.callSessionStream.listen(
      (session) {
        try {
          _handleCallSession(session);
        } catch (e) {
          // Handle error silently to prevent widget tree building issues
          print('Error handling call session: $e');
        }
      },
    );

    _participantJoinedSubscription = _signalingService.participantJoinedStream.listen(
      (participant) {
        try {
          _handleParticipantJoined(participant);
        } catch (e) {
          print('Error handling participant joined: $e');
        }
      },
    );

    _participantLeftSubscription = _signalingService.participantLeftStream.listen(
      (userId) {
        try {
          _handleParticipantLeft(userId);
        } catch (e) {
          print('Error handling participant left: $e');
        }
      },
    );

    _errorSubscription = _signalingService.errorStream.listen(
      (error) {
        try {
          _handleError(error);
        } catch (e) {
          print('Error handling signaling error: $e');
        }
      },
    );

    // Listen to WebRTC service events
    _remoteRenderersSubscription = _webrtcService.remoteRenderersStream.listen(
      (renderers) {
        try {
          _updateRemoteRenderers(renderers);
        } catch (e) {
          print('Error updating remote renderers: $e');
        }
      },
    );

    _localRendererSubscription = _webrtcService.localRendererStream.listen(
      (renderer) {
        try {
          _updateLocalRenderer(renderer);
        } catch (e) {
          print('Error updating local renderer: $e');
        }
      },
    );
  }

  // Initialize services
  Future<void> initialize(String serverUrl, String userId, String token) async {
    try {
      state = state.copyWith(isConnecting: true, clearError: true);

      // Store current user ID for participant identification
      _currentUserId = userId;
      debugPrint('Initializing video call for user: $userId');

      // Initialize WebRTC service
      await _webrtcService.initialize();

      // Initialize signaling service
      await _signalingService.initialize(serverUrl, userId, token);

      // Set up subscriptions after services are initialized
      _initializeSubscriptions();

      state = state.copyWith(isConnecting: false);
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        errorMessage: 'Failed to initialize video call: $e',
      );
      rethrow;
    }
  }

  // Join a call session
  Future<void> joinCall(String sessionId, {
    bool video = true,
    bool audio = true,
  }) async {
    try {
      state = state.copyWith(isConnecting: true, clearError: true);

      // Start local media stream - always try to get both video and audio initially
      // Individual tracks can be disabled later via toggleVideo/toggleAudio
      await _webrtcService.startLocalStream(video: true, audio: true);
      
      // Now disable video/audio tracks if requested
      if (!video) {
        await _webrtcService.toggleVideo();
      }
      if (!audio) {
        await _webrtcService.toggleAudio();
      }

      // Generate peer ID (you might want to use a proper UUID library)
      final peerId = _generatePeerId();
      _currentPeerId = peerId;
      debugPrint('Generated peer ID: $peerId for user: $_currentUserId');

      // Join call session via signaling
      await _signalingService.joinCallSession(sessionId, peerId);

      state = state.copyWith(
        isConnecting: false,
        isInCall: true,
        isVideoEnabled: video,
        isAudioEnabled: audio,
      );
      
      debugPrint('Successfully joined call session. Video: $video, Audio: $audio');
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        errorMessage: 'Failed to join call: $e',
      );
      rethrow;
    }
  }

  // Leave current call
  Future<void> leaveCall() async {
    try {
      // Leave call session via signaling
      await _signalingService.leaveCallSession();

      // End WebRTC call
      await _webrtcService.endCall();

      state = state.copyWith(
        isInCall: false,
        currentSession: null,
        participants: [],
        remoteRenderers: {},
        localRenderer: null,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to leave call: $e',
      );
    }
  }

  // Toggle video
  Future<void> toggleVideo() async {
    try {
      await _signalingService.toggleVideo();
      state = state.copyWith(
        isVideoEnabled: _webrtcService.isVideoEnabled,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to toggle video: $e',
      );
    }
  }

  // Toggle audio
  Future<void> toggleAudio() async {
    try {
      await _signalingService.toggleAudio();
      state = state.copyWith(
        isAudioEnabled: _webrtcService.isAudioEnabled,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to toggle audio: $e',
      );
    }
  }

  // Start screen sharing
  Future<void> startScreenShare() async {
    try {
      await _webrtcService.startLocalStream(screenShare: true);
      state = state.copyWith(isScreenSharing: true);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to start screen sharing: $e',
      );
    }
  }

  // Stop screen sharing
  Future<void> stopScreenShare() async {
    try {
      await _webrtcService.startLocalStream(
        video: state.isVideoEnabled,
        audio: state.isAudioEnabled,
      );
      state = state.copyWith(isScreenSharing: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to stop screen sharing: $e',
      );
    }
  }

  // Handle call session updates
  void _handleCallSession(CallSession session) async {
    debugPrint('=== HANDLING CALL SESSION ===');
    debugPrint('Session ID: ${session.sessionId}');
    debugPrint('Session participants count: ${session.participants.length}');
    debugPrint('Current user ID: $_currentUserId');
    debugPrint('Current peer ID: $_currentPeerId');
    
    final participants = session.participants.map((p) {
      // Mark local participant by matching user ID
      final isLocal = p.userId == _currentUserId;
      debugPrint('Participant: ${p.fullName} (userId: ${p.userId}, peerId: ${p.peerId}) - isLocal: $isLocal');
      return p.copyWith(isLocal: isLocal);
    }).toList();

    debugPrint('Processed participants:');
    for (final p in participants) {
      debugPrint('  - ${p.fullName}: local=${p.isLocal}, userId=${p.userId}, peerId=${p.peerId}');
    }

    // If we're joining and there are existing participants,
    // establish connections with them
    if (state.isInCall) {
      final remoteParticipants = participants.where((p) => !p.isLocal && p.peerId.isNotEmpty).toList();
      debugPrint('Remote participants to connect: ${remoteParticipants.length}');
      
      for (final participant in remoteParticipants) {
        try {
          // Check if we already have a connection
          if (!_webrtcService.hasPeerConnection(participant.peerId)) {
            debugPrint('Establishing connection with existing participant: ${participant.peerId}');
            await _initiateConnectionWithPeer(participant.peerId);
          } else {
            debugPrint('Connection already exists with participant: ${participant.peerId}');
          }
        } catch (e) {
          debugPrint('Error establishing connection with existing participant ${participant.peerId}: $e');
        }
      }
    }

    state = state.copyWith(
      currentSession: session,
      participants: participants,
    );
    
    debugPrint('State updated with ${participants.length} participants');
    debugPrint('=== CALL SESSION HANDLING COMPLETE ===');
  }

  // Handle participant joined
  void _handleParticipantJoined(CallParticipant participant) async {
    debugPrint('=== HANDLING PARTICIPANT JOINED ===');
    debugPrint('New participant: ${participant.fullName}');
    debugPrint('  - User ID: ${participant.userId}');
    debugPrint('  - Peer ID: ${participant.peerId}');
    debugPrint('  - Socket ID: ${participant.socketId}');
    debugPrint('Current user ID: $_currentUserId');
    
    // Mark as local or remote based on user ID
    final isLocal = participant.userId == _currentUserId;
    final updatedParticipant = participant.copyWith(isLocal: isLocal);
    debugPrint('  - Is Local: $isLocal');
    
    final updatedParticipants = List<CallParticipant>.from(state.participants);
    
    // Check if participant already exists
    final existingIndex = updatedParticipants.indexWhere(
      (p) => p.userId == participant.userId,
    );

    if (existingIndex != -1) {
      updatedParticipants[existingIndex] = updatedParticipant;
      debugPrint('Updated existing participant: ${participant.fullName}');
    } else {
      updatedParticipants.add(updatedParticipant);
      debugPrint('Added new participant: ${participant.fullName}');
      
      // If this is a new remote participant and we're already in the call,
      // initiate a peer connection
      if (state.isInCall && !isLocal && participant.peerId.isNotEmpty) {
        try {
          debugPrint('Initiating connection with new remote participant: ${participant.fullName} (${participant.peerId})');
          await _initiateConnectionWithPeer(participant.peerId);
        } catch (e) {
          debugPrint('Error initiating connection with peer ${participant.peerId}: $e');
        }
      }
    }

    state = state.copyWith(participants: updatedParticipants);
    debugPrint('Total participants after update: ${state.participants.length}');
    debugPrint('Remote participants: ${updatedParticipants.where((p) => !p.isLocal).length}');
    debugPrint('=== PARTICIPANT JOINED HANDLING COMPLETE ===');
  }

  // Initiate connection with a new peer
  Future<void> _initiateConnectionWithPeer(String peerId) async {
    try {
      debugPrint('Initiating connection with peer: $peerId');
      
      // Check if we already have a connection
      if (_webrtcService.remoteRenderers.containsKey(peerId)) {
        debugPrint('Connection already exists with peer: $peerId');
        return;
      }
      
      // Create peer connection
      await _webrtcService.createPeerConnectionForParticipant(peerId);
      
      // Small delay to ensure peer connection is ready
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Create and send offer
      debugPrint('Creating offer for peer: $peerId');
      final offer = await _webrtcService.createOffer(peerId);
      
      debugPrint('Sending offer to peer: $peerId');
      await _signalingService.sendOffer(peerId, offer);
      
      debugPrint('Successfully initiated connection with peer: $peerId');
    } catch (e) {
      debugPrint('Error initiating connection with peer $peerId: $e');
      // Don't rethrow to prevent breaking the overall call flow
      state = state.copyWith(
        errorMessage: 'Failed to connect with participant: $e'
      );
    }
  }

  // Handle participant left
  void _handleParticipantLeft(String userId) {
    final updatedParticipants = state.participants
        .where((p) => p.userId != userId)
        .toList();

    state = state.copyWith(participants: updatedParticipants);
  }

  // Handle errors
  void _handleError(String error) {
    state = state.copyWith(errorMessage: error);
  }

  // Update remote renderers
  void _updateRemoteRenderers(Map<String, RTCVideoRenderer> renderers) {
    debugPrint('Updating remote renderers in provider:');
    debugPrint('  - Previous count: ${state.remoteRenderers.length}');
    debugPrint('  - New count: ${renderers.length}');
    debugPrint('  - New renderer IDs: ${renderers.keys.toList()}');
    
    renderers.forEach((participantId, renderer) {
      debugPrint('  - Renderer [$participantId]: hasStream=${renderer.srcObject != null}');
      if (renderer.srcObject != null) {
        debugPrint('    - Video tracks: ${renderer.srcObject!.getVideoTracks().length}');
        debugPrint('    - Audio tracks: ${renderer.srcObject!.getAudioTracks().length}');
      }
    });
    
    // Create a new map that maps both peerId and userId to the same renderer
    // This ensures compatibility regardless of which key is used for lookup
    final mappedRenderers = <String, RTCVideoRenderer>{};
    
    for (final entry in renderers.entries) {
      final rendererId = entry.key;
      final renderer = entry.value;
      
      // Add the original mapping
      mappedRenderers[rendererId] = renderer;
      
      // Try to find a participant with this peerId and also map by userId
      final participant = state.participants.firstWhere(
        (p) => p.peerId == rendererId,
        orElse: () => state.participants.firstWhere(
          (p) => p.userId == rendererId,
          orElse: () => const CallParticipant(
            userId: '',
            peerId: '',
            socketId: '',
            firstName: '',
            lastName: '',
          ),
        ),
      );
      
      if (participant.userId.isNotEmpty) {
        // Map by both peerId and userId for convenience
        if (participant.peerId.isNotEmpty && participant.peerId != rendererId) {
          mappedRenderers[participant.peerId] = renderer;
        }
        if (participant.userId != rendererId) {
          mappedRenderers[participant.userId] = renderer;
        }
        debugPrint('  - Mapped renderer for participant ${participant.fullName}: peerId=${participant.peerId}, userId=${participant.userId}');
      }
    }
    
    state = state.copyWith(remoteRenderers: mappedRenderers);
    debugPrint('Remote renderers updated in state with ${mappedRenderers.length} mappings');
    debugPrint('Final renderer keys: ${mappedRenderers.keys.toList()}');
  }

  // Update local renderer
  void _updateLocalRenderer(RTCVideoRenderer? renderer) {
    state = state.copyWith(localRenderer: renderer);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Refresh connections - force reconnection with all participants
  Future<void> refreshConnections() async {
    try {
      debugPrint('=== REFRESHING CONNECTIONS ===');
      
      // First, sync participants with available renderers
      await _syncParticipantsWithRenderers();
      
      // Get current remote participants
      final remoteParticipants = state.participants.where((p) => !p.isLocal && p.peerId.isNotEmpty).toList();
      
      debugPrint('Remote participants to refresh: ${remoteParticipants.length}');
      for (final participant in remoteParticipants) {
        try {
          debugPrint('Refreshing connection with participant: ${participant.fullName} (${participant.peerId})');
          
          // Re-initiate connection
          await _initiateConnectionWithPeer(participant.peerId);
        } catch (e) {
          debugPrint('Error refreshing connection with ${participant.peerId}: $e');
        }
      }
      
      debugPrint('Connection refresh completed');
    } catch (e) {
      debugPrint('Error during connection refresh: $e');
      state = state.copyWith(errorMessage: 'Failed to refresh connections: $e');
    }
  }

  // Sync participants with available renderers - create missing participants
  Future<void> _syncParticipantsWithRenderers() async {
    debugPrint('=== SYNCING PARTICIPANTS WITH RENDERERS ===');
    
    final availableRenderers = state.remoteRenderers;
    final currentParticipants = state.participants;
    final updatedParticipants = List<CallParticipant>.from(currentParticipants);
    
    debugPrint('Available renderer keys: ${availableRenderers.keys.toList()}');
    debugPrint('Current participants: ${currentParticipants.map((p) => '${p.fullName} (${p.peerId})').toList()}');
    
    // For each renderer, ensure we have a corresponding participant
    for (final rendererKey in availableRenderers.keys) {
      // Check if we already have a participant for this renderer
      final existingParticipant = currentParticipants.firstWhere(
        (p) => p.peerId == rendererKey || p.userId == rendererKey || p.socketId == rendererKey,
        orElse: () => CallParticipant(
          userId: '',
          firstName: '',
          lastName: '',
          profilePicture: null,
          hasVideo: true,
          hasAudio: true,
          isScreenSharing: false,
          peerId: '',
          socketId: '',
          isLocal: false,
        ),
      );
      
      if (existingParticipant.userId.isEmpty) {
        // Create a dummy participant for this renderer
        final dummyParticipant = CallParticipant(
          userId: 'remote_$rendererKey',
          firstName: 'Remote',
          lastName: 'Participant',
          profilePicture: null,
          hasVideo: true,
          hasAudio: true,
          isScreenSharing: false,
          peerId: rendererKey,
          socketId: '',
          isLocal: false,
        );
        
        updatedParticipants.add(dummyParticipant);
        debugPrint('Created dummy participant for renderer: $rendererKey');
      }
    }
    
    if (updatedParticipants.length != currentParticipants.length) {
      state = state.copyWith(participants: updatedParticipants);
      debugPrint('Updated participants list with ${updatedParticipants.length} participants');
    }
    
    debugPrint('=== SYNC COMPLETE ===');
  }

  // Get renderer for participant (tries multiple key strategies)
  RTCVideoRenderer? getRendererForParticipant(CallParticipant participant) {
    // Try peerId first (most likely key)
    if (participant.peerId.isNotEmpty) {
      final renderer = state.remoteRenderers[participant.peerId];
      if (renderer != null) return renderer;
    }
    
    // Try userId as fallback
    final renderer = state.remoteRenderers[participant.userId];
    if (renderer != null) return renderer;
    
    // Try socketId as last resort
    if (participant.socketId.isNotEmpty) {
      return state.remoteRenderers[participant.socketId];
    }
    
    return null;
  }

  // Debug method to check renderer mappings
  Map<String, String> getRendererMappingDebug() {
    final debug = <String, String>{};
    
    for (final participant in state.participants) {
      final renderer = getRendererForParticipant(participant);
      debug[participant.fullName] = renderer != null 
          ? 'Has renderer' 
          : 'No renderer (peerId: ${participant.peerId}, userId: ${participant.userId})';
    }
    
    return debug;
  }

  // Generate peer ID (simple implementation)
  String _generatePeerId() {
    return 'peer_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (9000 * (DateTime.now().millisecond / 1000))).round()}';
  }

  @override
  void dispose() {
    _callSessionSubscription?.cancel();
    _participantJoinedSubscription?.cancel();
    _participantLeftSubscription?.cancel();
    _remoteRenderersSubscription?.cancel();
    _localRendererSubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }
}
