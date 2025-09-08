import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../providers/video_call_provider.dart';
import '../widgets/video_call_controls.dart';
import '../widgets/camera_debug_widget.dart';
import '../widgets/stream_debug_widget.dart';
import 'remote_participants_screen.dart';
import 'video_call_debug_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCall();
    });
  }

  Future<void> _initializeCall() async {
    try {
      final notifier = ref.read(videoCallProvider.notifier);
      
      debugPrint('Starting video call initialization...');
      debugPrint('Server URL: ${widget.serverUrl}');
      debugPrint('Session ID: ${widget.sessionId}');
      debugPrint('User ID: ${widget.userId}');
      
      // Initialize services
      debugPrint('Initializing video call services...');
      await notifier.initialize(widget.serverUrl, widget.userId, widget.token);
      
      // Join the call
      debugPrint('Joining call session...');
      await notifier.joinCall(widget.sessionId);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        debugPrint('Video call initialization completed successfully');
      }
    } catch (e) {
      debugPrint('Video call initialization failed: $e');
      if (mounted) {
        _showErrorDialog('Failed to join call: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoCallState = ref.watch(videoCallProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Stack(
            children: [
              // Video display area
              if (_isInitialized && videoCallState.isInCall)
                _buildVideoArea(videoCallState)
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
                    isScreenSharing: videoCallState.isScreenSharing,
                    onToggleVideo: () => ref.read(videoCallProvider.notifier).toggleVideo(),
                    onToggleAudio: () => ref.read(videoCallProvider.notifier).toggleAudio(),
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

  Widget _buildVideoArea(VideoCallState state) {
    final hasRemoteStreams = state.remoteRenderers.isNotEmpty;
    
    return Stack(
      children: [
        // Main video area - always show local video in background
        Positioned.fill(
          child: Container(
            color: Colors.grey[900],
            child: _buildLocalVideoMain(state),
          ),
        ),
        
        // Remote participant videos - prominently displayed
        if (hasRemoteStreams)
          Positioned.fill(
            child: _buildRemoteVideosGrid(state.remoteRenderers),
          ),
        
        // Local video as picture-in-picture when there are remote streams
        if (hasRemoteStreams && state.localRenderer != null)
          Positioned(
            top: 80,
            right: 20,
            child: Container(
              width: 140,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: RTCVideoView(
                  state.localRenderer!,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  mirror: true, // Mirror local video like a selfie camera
                ),
              ),
            ),
          ),
          
        // Participant count indicator
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${state.participants.length + 1} participants',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        
        // Debug info - improved
        if (kDebugMode)
          Positioned(
            bottom: 120,
            left: 16,
            child: StreamDebugWidget(
              remoteRenderers: state.remoteRenderers,
              localRenderer: state.localRenderer,
              participants: state.participants,
            ),
          ),
      ],
    );
  }

  Widget _buildRemoteVideosGrid(Map<String, RTCVideoRenderer> remoteRenderers) {
    if (remoteRenderers.isEmpty) return const SizedBox.shrink();
    
    // For now, show the first remote video prominently
    // Later we can implement a grid for multiple participants
    final firstRemoteRenderer = remoteRenderers.values.first;
    final participantId = remoteRenderers.keys.first;
    
    print('Building remote video for participant: $participantId');
    print('Renderer has stream: ${firstRemoteRenderer.srcObject != null}');
    if (firstRemoteRenderer.srcObject != null) {
      print('Stream video tracks: ${firstRemoteRenderer.srcObject!.getVideoTracks().length}');
      print('Stream audio tracks: ${firstRemoteRenderer.srcObject!.getAudioTracks().length}');
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.blue, width: 3),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Column(
          children: [
            // Participant label
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(9),
                  topRight: Radius.circular(9),
                ),
              ),
              child: Text(
                'Remote Participant ($participantId)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Video area
            Expanded(
              child: firstRemoteRenderer.srcObject != null 
                ? RTCVideoView(
                    firstRemoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    mirror: false, // Don't mirror remote video
                  )
                : Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam_off,
                            size: 48,
                            color: Colors.white54,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No Remote Video',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalVideoMain(VideoCallState state) {
    if (state.localRenderer != null) {
      return RTCVideoView(
        state.localRenderer!,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        mirror: true, // Mirror local video like a selfie camera
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'Camera Starting...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLoadingOrWaitingView(VideoCallState state) {
    String message;
    if (state.isConnecting) {
      message = 'Connecting to call...';
    } else if (!_isInitialized) {
      message = 'Initializing camera...';
    } else if (state.errorMessage != null) {
      message = state.errorMessage!;
    } else {
      message = 'Waiting to join call...';
    }

    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.isConnecting)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // Session ID display with copy button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Share this Session ID',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.sessionId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _copySessionId,
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Others can use this ID to join the call',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _initializeCall(),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(VideoCallState state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Video Call Session',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (state.currentSession != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'ID: ${widget.sessionId}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _copySessionId(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy,
                                    size: 12,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Connection status indicator
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
              const SizedBox(width: 8),
              // Remote participants button
              IconButton(
                onPressed: () => _navigateToRemoteParticipants(),
                icon: const Icon(Icons.people, color: Colors.white),
                tooltip: 'View Remote Participants',
              ),
              // Debug screen button
              IconButton(
                onPressed: () => _navigateToDebugScreen(),
                icon: const Icon(Icons.settings, color: Colors.white),
                tooltip: 'Debug Screen',
              ),
              IconButton(
                onPressed: _showCameraDebug,
                icon: const Icon(Icons.bug_report, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleScreenShare() {
    try {
      // Note: Screen sharing might not be implemented in the current provider
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screen sharing not available yet')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Screen sharing error: $e')),
      );
    }
  }

  void _switchCamera() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera switching not implemented yet')),
    );
  }

  void _showCameraDebug() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 600,
          height: 500,
          child: SingleChildScrollView(
            child: CameraDebugWidget(),
          ),
        ),
      ),
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
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              try {
                await ref.read(videoCallProvider.notifier).leaveCall();
                if (mounted) {
                  Navigator.of(context).pop(); // Go back to previous screen
                }
              } catch (e) {
                if (mounted) {
                  _showErrorDialog('Failed to leave call: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToRemoteParticipants() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RemoteParticipantsScreen(),
      ),
    );
  }

  void _navigateToDebugScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VideoCallDebugScreen(),
      ),
    );
  }

  void _copySessionId() {
    Clipboard.setData(ClipboardData(text: widget.sessionId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Session ID copied: ${widget.sessionId}'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Don't try to access ref during dispose to avoid the error we saw
    super.dispose();
  }
}
