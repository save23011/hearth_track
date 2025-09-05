import 'package:flutter/material.dart';

class VideoCallControls extends StatelessWidget {
  final bool isVideoEnabled;
  final bool isAudioEnabled;
  final bool isScreenSharing;
  final VoidCallback onToggleVideo;
  final VoidCallback onToggleAudio;
  final VoidCallback onToggleScreenShare;
  final VoidCallback onEndCall;
  final VoidCallback? onSwitchCamera;

  const VideoCallControls({
    super.key,
    required this.isVideoEnabled,
    required this.isAudioEnabled,
    required this.isScreenSharing,
    required this.onToggleVideo,
    required this.onToggleAudio,
    required this.onToggleScreenShare,
    required this.onEndCall,
    this.onSwitchCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Video toggle
            _buildControlButton(
              icon: isVideoEnabled ? Icons.videocam : Icons.videocam_off,
              isActive: isVideoEnabled,
              onPressed: onToggleVideo,
              tooltip: isVideoEnabled ? 'Turn off camera' : 'Turn on camera',
            ),
            
            // Audio toggle
            _buildControlButton(
              icon: isAudioEnabled ? Icons.mic : Icons.mic_off,
              isActive: isAudioEnabled,
              onPressed: onToggleAudio,
              tooltip: isAudioEnabled ? 'Mute microphone' : 'Unmute microphone',
            ),
            
            // Screen share toggle
            _buildControlButton(
              icon: isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
              isActive: isScreenSharing,
              onPressed: onToggleScreenShare,
              tooltip: isScreenSharing ? 'Stop sharing' : 'Share screen',
            ),
            
            // Switch camera (if available)
            if (onSwitchCamera != null)
              _buildControlButton(
                icon: Icons.flip_camera_ios,
                isActive: false,
                onPressed: onSwitchCamera!,
                tooltip: 'Switch camera',
              ),
            
            // End call
            _buildControlButton(
              icon: Icons.call_end,
              isActive: false,
              onPressed: onEndCall,
              tooltip: 'End call',
              backgroundColor: Colors.red,
              iconColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required String tooltip,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    final defaultBackgroundColor = isActive 
        ? Colors.white 
        : Colors.grey[800];
    final defaultIconColor = isActive 
        ? Colors.black 
        : Colors.white;

    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: backgroundColor ?? defaultBackgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor ?? defaultIconColor,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
