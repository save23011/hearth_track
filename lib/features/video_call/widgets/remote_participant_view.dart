import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call_participant.dart';

class RemoteParticipantView extends StatefulWidget {
  final CallParticipant participant;
  final RTCVideoRenderer? videoRenderer;
  final bool showDebugInfo;

  const RemoteParticipantView({
    super.key,
    required this.participant,
    this.videoRenderer,
    this.showDebugInfo = false,
  });

  @override
  State<RemoteParticipantView> createState() => _RemoteParticipantViewState();
}

class _RemoteParticipantViewState extends State<RemoteParticipantView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.videoRenderer != null ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Video or placeholder
            Positioned.fill(
              child: _buildVideoContent(),
            ),
            
            // Participant info overlay
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: _buildParticipantInfo(),
            ),
            
            // Status indicators
            _buildStatusIndicators(),
            
            // Debug info
            if (widget.showDebugInfo)
              Positioned(
                top: 8,
                left: 8,
                child: _buildDebugInfo(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (widget.videoRenderer != null && widget.participant.hasVideo) {
      return RTCVideoView(
        widget.videoRenderer!,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        mirror: false, // Don't mirror remote video
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              backgroundImage: widget.participant.profilePicture != null
                  ? NetworkImage(widget.participant.profilePicture!)
                  : null,
              child: widget.participant.profilePicture == null
                  ? Text(
                      widget.participant.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              widget.participant.fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.videoRenderer == null 
                  ? 'Connecting...' 
                  : !widget.participant.hasVideo 
                      ? 'Camera Off' 
                      : 'Loading video...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Connection status indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.videoRenderer != null ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              widget.participant.fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicators() {
    return Positioned(
      top: 8,
      right: 8,
      child: Column(
        children: [
          // Audio muted indicator
          if (!widget.participant.hasAudio)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.mic_off,
                color: Colors.white,
                size: 16,
              ),
            ),
          
          // Video off indicator
          if (!widget.participant.hasVideo)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.videocam_off,
                color: Colors.white,
                size: 16,
              ),
            ),
          
          // Screen sharing indicator
          if (widget.participant.isScreenSharing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Sharing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.yellow, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'DEBUG',
            style: const TextStyle(
              color: Colors.yellow,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Renderer: ${widget.videoRenderer != null ? "OK" : "NULL"}',
            style: const TextStyle(color: Colors.white, fontSize: 8),
          ),
          Text(
            'Peer ID: ${widget.participant.peerId}',
            style: const TextStyle(color: Colors.white, fontSize: 8),
          ),
          Text(
            'User ID: ${widget.participant.userId}',
            style: const TextStyle(color: Colors.white, fontSize: 8),
          ),
          if (widget.videoRenderer?.srcObject != null)
            Text(
              'Stream: ${widget.videoRenderer!.srcObject!.id}',
              style: const TextStyle(color: Colors.green, fontSize: 8),
            ),
        ],
      ),
    );
  }
}
