import 'package:flutter_riverpod/flutter_riverpod.dart';

// Basic Video Call State
class BasicVideoCallState {
  final String? sessionId;
  final bool isConnecting;
  final bool isInCall;
  final bool isVideoEnabled;
  final bool isAudioEnabled;
  final String? errorMessage;

  const BasicVideoCallState({
    this.sessionId,
    this.isConnecting = false,
    this.isInCall = false,
    this.isVideoEnabled = true,
    this.isAudioEnabled = true,
    this.errorMessage,
  });

  BasicVideoCallState copyWith({
    String? sessionId,
    bool? isConnecting,
    bool? isInCall,
    bool? isVideoEnabled,
    bool? isAudioEnabled,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BasicVideoCallState(
      sessionId: sessionId ?? this.sessionId,
      isConnecting: isConnecting ?? this.isConnecting,
      isInCall: isInCall ?? this.isInCall,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// Use StateProvider instead of StateNotifierProvider
final basicVideoCallStateProvider = StateProvider<BasicVideoCallState>((ref) {
  return const BasicVideoCallState();
});

// Controller class for managing video call operations
class BasicVideoCallController {
  final Ref ref;
  bool _isDisposed = false;

  BasicVideoCallController(this.ref);

  // Safe state update method that checks if provider is still alive
  void _safeUpdateState(BasicVideoCallState newState) {
    if (_isDisposed) return;
    
    try {
      ref.read(basicVideoCallStateProvider.notifier).state = newState;
    } catch (e) {
      // Silently handle state update errors if widget is disposed
      if (e.toString().contains('ElementLifecycle.defunct')) {
        _isDisposed = true;
      }
    }
  }

  void dispose() {
    _isDisposed = true;
  }

  Future<void> initialize(String serverUrl, String userId, String token) async {
    try {
      _safeUpdateState(
          ref.read(basicVideoCallStateProvider).copyWith(isConnecting: true, clearError: true));
      
      // Simulate initialization
      await Future.delayed(const Duration(milliseconds: 500));
      
      _safeUpdateState(
          ref.read(basicVideoCallStateProvider).copyWith(isConnecting: false));
    } catch (e) {
      _safeUpdateState(
          ref.read(basicVideoCallStateProvider).copyWith(
            isConnecting: false,
            errorMessage: 'Failed to initialize video call: $e',
          ));
      rethrow;
    }
  }

  Future<void> joinCall(String sessionId, {bool video = true, bool audio = true}) async {
    try {
      _safeUpdateState(
          ref.read(basicVideoCallStateProvider).copyWith(isConnecting: true, clearError: true));

      // Simulate joining call
      await Future.delayed(const Duration(milliseconds: 1000));

      _safeUpdateState(
          ref.read(basicVideoCallStateProvider).copyWith(
            isConnecting: false,
            isInCall: true,
            sessionId: sessionId,
            isVideoEnabled: video,
            isAudioEnabled: audio,
          ));
    } catch (e) {
      _safeUpdateState(
          ref.read(basicVideoCallStateProvider).copyWith(
            isConnecting: false,
            errorMessage: 'Failed to join call: $e',
          ));
      rethrow;
    }
  }

  Future<void> leaveCall() async {
    try {
      _safeUpdateState(
          ref.read(basicVideoCallStateProvider).copyWith(
            isInCall: false,
            sessionId: null,
            clearError: true,
          ));
    } catch (e) {
      _safeUpdateState(
          ref.read(basicVideoCallStateProvider).copyWith(
            errorMessage: 'Failed to leave call: $e',
          ));
    }
  }

  void toggleVideo() {
    final currentState = ref.read(basicVideoCallStateProvider);
    _safeUpdateState(
        currentState.copyWith(isVideoEnabled: !currentState.isVideoEnabled));
  }

  void toggleAudio() {
    final currentState = ref.read(basicVideoCallStateProvider);
    _safeUpdateState(
        currentState.copyWith(isAudioEnabled: !currentState.isAudioEnabled));
  }

  void clearError() {
    _safeUpdateState(
        ref.read(basicVideoCallStateProvider).copyWith(clearError: true));
  }
}

// Provider for the controller
final basicVideoCallControllerProvider = Provider<BasicVideoCallController>((ref) {
  final controller = BasicVideoCallController(ref);
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});
