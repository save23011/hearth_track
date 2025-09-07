import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/basic_video_call_provider.dart';
import '../widgets/video_call_controls.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String serverUrl;
  final String userId;
  final String token;

  const VideoCallScreen({
    super.key,
    required this.sessionId,
    required this.serverUrl,
    required this.userId,
    required this.token,
  });

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Delay initialization to after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCall();
    });
  }

  Future<void> _initializeCall() async {
    try {
      final controller = ref.read(basicVideoCallControllerProvider);
      
      // Initialize services
      await controller.initialize(widget.serverUrl, widget.userId, widget.token);
      
      // Join the call
      await controller.joinCall(widget.sessionId);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to join call: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoCallState = ref.watch(basicVideoCallStateProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Stack(
            children: [
              // Video grid - simplified for basic provider
              if (_isInitialized && videoCallState.isInCall)
                Container(
                  child: const Center(
                    child: Text(
                      'Video Call Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                _buildLoadingOrWaitingView(videoCallState),

              // Top bar with call info
              _buildTopBar(videoCallState),

              // Bottom controls
              if (_isInitialized && videoCallState.isInCall)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoCallControls(
                    isVideoEnabled: videoCallState.isVideoEnabled,
                    isAudioEnabled: videoCallState.isAudioEnabled,
                    isScreenSharing: false, // Basic provider doesn't support screen sharing
                    onToggleVideo: () => ref.read(basicVideoCallControllerProvider).toggleVideo(),
                    onToggleAudio: () => ref.read(basicVideoCallControllerProvider).toggleAudio(),
                    onToggleScreenShare: _toggleScreenShare,
                    onEndCall: _endCall,
                    onSwitchCamera: _switchCamera,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOrWaitingView(BasicVideoCallState state) {
    String message;
    if (state.isConnecting) {
      message = 'Connecting to call...';
    } else if (!_isInitialized) {
      message = 'Initializing...';
    } else {
      message = 'Waiting for participants...';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (state.sessionId != null) ...[
            const SizedBox(height: 16),
            Text(
              'Session ID: ${state.sessionId}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopBar(BasicVideoCallState state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Back button
            IconButton(
              onPressed: _showLeaveCallDialog,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            
            const SizedBox(width: 8),
            
            // Call info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.sessionId ?? 'Video Call',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Video Call Session',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Connection status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: state.isInCall ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                state.isInCall ? 'Connected' : 'Connecting',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleScreenShare() {
    // Screen sharing not implemented in basic provider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Screen sharing not implemented')),
    );
  }

  void _switchCamera() {
    // This would need to be implemented in the WebRTC service
    // For now, we'll show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera switching not implemented yet')),
    );
  }

  void _endCall() {
    _showLeaveCallDialog();
  }

  void _showLeaveCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Call'),
        content: const Text('Are you sure you want to leave this call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(basicVideoCallControllerProvider).leaveCall();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    // Clear the error first to prevent repeated dialogs
    Future.microtask(() => ref.read(basicVideoCallControllerProvider).clearError());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Also pop the call screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up resources
    ref.read(basicVideoCallControllerProvider).leaveCall();
    super.dispose();
  }
}
