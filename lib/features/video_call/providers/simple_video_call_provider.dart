import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call_session.dart';
import '../models/call_participant.dart';

// Simple Video Call State
class SimpleVideoCallState {
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

  const SimpleVideoCallState({
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

  SimpleVideoCallState copyWith({
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
    return SimpleVideoCallState(
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

// Simple Video Call Notifier
class SimpleVideoCallNotifier extends StateNotifier<SimpleVideoCallState> {
  SimpleVideoCallNotifier() : super(const SimpleVideoCallState());

  bool _isMounted = true;

  void _safeUpdateState(SimpleVideoCallState newState) {
    if (_isMounted && mounted) {
      state = newState;
    }
  }

  // Initialize services
  Future<void> initialize(String serverUrl, String userId, String token) async {
    try {
      _safeUpdateState(state.copyWith(isConnecting: true, clearError: true));
      
      // Simulate initialization - replace with actual implementation
      await Future.delayed(const Duration(milliseconds: 500));
      
      _safeUpdateState(state.copyWith(isConnecting: false));
    } catch (e) {
      _safeUpdateState(state.copyWith(
        isConnecting: false,
        errorMessage: 'Failed to initialize video call: $e',
      ));
      rethrow;
    }
  }

  // Join a call session
  Future<void> joinCall(String sessionId, {
    bool video = true,
    bool audio = true,
  }) async {
    try {
      _safeUpdateState(state.copyWith(isConnecting: true, clearError: true));

      // Simulate joining call - replace with actual implementation
      await Future.delayed(const Duration(milliseconds: 1000));

      _safeUpdateState(state.copyWith(
        isConnecting: false,
        isInCall: true,
        isVideoEnabled: video,
        isAudioEnabled: audio,
      ));
    } catch (e) {
      _safeUpdateState(state.copyWith(
        isConnecting: false,
        errorMessage: 'Failed to join call: $e',
      ));
      rethrow;
    }
  }

  // Leave current call
  Future<void> leaveCall() async {
    try {
      _safeUpdateState(state.copyWith(
        isInCall: false,
        currentSession: null,
        participants: [],
        remoteRenderers: {},
        localRenderer: null,
        clearError: true,
      ));
    } catch (e) {
      _safeUpdateState(state.copyWith(
        errorMessage: 'Failed to leave call: $e',
      ));
    }
  }

  // Toggle video
  Future<void> toggleVideo() async {
    try {
      _safeUpdateState(state.copyWith(
        isVideoEnabled: !state.isVideoEnabled,
      ));
    } catch (e) {
      _safeUpdateState(state.copyWith(
        errorMessage: 'Failed to toggle video: $e',
      ));
    }
  }

  // Toggle audio
  Future<void> toggleAudio() async {
    try {
      _safeUpdateState(state.copyWith(
        isAudioEnabled: !state.isAudioEnabled,
      ));
    } catch (e) {
      _safeUpdateState(state.copyWith(
        errorMessage: 'Failed to toggle audio: $e',
      ));
    }
  }

  // Clear error
  void clearError() {
    _safeUpdateState(state.copyWith(clearError: true));
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }
}

// Simple provider
final simpleVideoCallProvider = StateNotifierProvider<SimpleVideoCallNotifier, SimpleVideoCallState>((ref) {
  return SimpleVideoCallNotifier();
});
