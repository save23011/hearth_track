import 'dart:async';
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
  final webrtcService = ref.watch(webrtcServiceProvider);
  final signalingService = ref.watch(signalingServiceProvider);
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
  
  StreamSubscription? _callSessionSubscription;
  StreamSubscription? _participantJoinedSubscription;
  StreamSubscription? _participantLeftSubscription;
  StreamSubscription? _remoteRenderersSubscription;
  StreamSubscription? _localRendererSubscription;
  StreamSubscription? _errorSubscription;

  VideoCallNotifier(this._webrtcService, this._signalingService)
      : super(const VideoCallState()) {
    _initializeSubscriptions();
  }

  void _initializeSubscriptions() {
    // Listen to signaling service events
    _callSessionSubscription = _signalingService.callSessionStream.listen(
      (session) => _handleCallSession(session),
    );

    _participantJoinedSubscription = _signalingService.participantJoinedStream.listen(
      (participant) => _handleParticipantJoined(participant),
    );

    _participantLeftSubscription = _signalingService.participantLeftStream.listen(
      (userId) => _handleParticipantLeft(userId),
    );

    _errorSubscription = _signalingService.errorStream.listen(
      (error) => _handleError(error),
    );

    // Listen to WebRTC service events
    _remoteRenderersSubscription = _webrtcService.remoteRenderersStream.listen(
      (renderers) => _updateRemoteRenderers(renderers),
    );

    _localRendererSubscription = _webrtcService.localRendererStream.listen(
      (renderer) => _updateLocalRenderer(renderer),
    );
  }

  // Initialize services
  Future<void> initialize(String serverUrl, String userId, String token) async {
    try {
      state = state.copyWith(isConnecting: true, clearError: true);

      // Initialize WebRTC service
      await _webrtcService.initialize();

      // Initialize signaling service
      await _signalingService.initialize(serverUrl, userId, token);

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

      // Start local media stream
      await _webrtcService.startLocalStream(video: video, audio: audio);

      // Generate peer ID (you might want to use a proper UUID library)
      final peerId = _generatePeerId();

      // Join call session via signaling
      await _signalingService.joinCallSession(sessionId, peerId);

      state = state.copyWith(
        isConnecting: false,
        isInCall: true,
        isVideoEnabled: video,
        isAudioEnabled: audio,
      );
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
  void _handleCallSession(CallSession session) {
    final participants = session.participants.map((p) {
      // Mark local participant
      if (p.userId == session.initiatorId) {
        return p.copyWith(isLocal: true);
      }
      return p;
    }).toList();

    state = state.copyWith(
      currentSession: session,
      participants: participants,
    );
  }

  // Handle participant joined
  void _handleParticipantJoined(CallParticipant participant) {
    final updatedParticipants = List<CallParticipant>.from(state.participants);
    
    // Check if participant already exists
    final existingIndex = updatedParticipants.indexWhere(
      (p) => p.userId == participant.userId,
    );

    if (existingIndex != -1) {
      updatedParticipants[existingIndex] = participant;
    } else {
      updatedParticipants.add(participant);
    }

    state = state.copyWith(participants: updatedParticipants);
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
    state = state.copyWith(remoteRenderers: renderers);
  }

  // Update local renderer
  void _updateLocalRenderer(RTCVideoRenderer? renderer) {
    state = state.copyWith(localRenderer: renderer);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
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
