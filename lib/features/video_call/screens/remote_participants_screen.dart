import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../providers/video_call_provider.dart';
import '../widgets/remote_participant_view.dart';
import '../models/call_participant.dart';

class RemoteParticipantsScreen extends ConsumerStatefulWidget {
  const RemoteParticipantsScreen({super.key});

  @override
  ConsumerState<RemoteParticipantsScreen> createState() => _RemoteParticipantsScreenState();
}

class _RemoteParticipantsScreenState extends ConsumerState<RemoteParticipantsScreen> {
  bool _showDebugInfo = true;

  @override
  Widget build(BuildContext context) {
    final videoCallState = ref.watch(videoCallProvider);
    
    // Filter out local participants
    final remoteParticipants = videoCallState.participants
        .where((p) => !p.isLocal)
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Remote Participants (${remoteParticipants.length})',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showDebugInfo ? Icons.bug_report : Icons.bug_report_outlined,
              color: _showDebugInfo ? Colors.yellow : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showDebugInfo = !_showDebugInfo;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshConnections,
          ),
        ],
      ),
      body: Column(
        children: [
          // Debug summary
          if (_showDebugInfo)
            _buildDebugSummary(videoCallState),
          
          // Remote participants grid
          Expanded(
            child: _buildRemoteParticipantsGrid(remoteParticipants, videoCallState.remoteRenderers),
          ),
          
          // Bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildDebugSummary(VideoCallState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEBUG SUMMARY',
            style: TextStyle(
              color: Colors.yellow,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Remote Renderers: ${state.remoteRenderers.length}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            'Total Participants: ${state.participants.length}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            'Remote Participants: ${state.participants.where((p) => !p.isLocal).length}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 4),
          
          // Renderer keys
          if (state.remoteRenderers.isNotEmpty) ...[
            const Text(
              'Renderer Keys:',
              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            ...state.remoteRenderers.keys.map((key) => Text(
              '  • $key',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            )),
          ],
          
          // Participant IDs
          if (state.participants.isNotEmpty) ...[
            const Text(
              'Participant IDs:',
              style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            ...state.participants.map((p) => Text(
              '  • ${p.isLocal ? "LOCAL" : "REMOTE"}: userId=${p.userId}, peerId=${p.peerId}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildRemoteParticipantsGrid(List<CallParticipant> remoteParticipants, Map<String, RTCVideoRenderer> remoteRenderers) {
    if (remoteParticipants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'No remote participants',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Waiting for others to join...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: remoteParticipants.length == 1 ? 1 : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 4 / 3,
        ),
        itemCount: remoteParticipants.length,
        itemBuilder: (context, index) {
          final participant = remoteParticipants[index];
          
          // Try multiple keys to find the renderer
          RTCVideoRenderer? renderer;
          
          // First try with peerId
          if (participant.peerId.isNotEmpty) {
            renderer = remoteRenderers[participant.peerId];
          }
          
          // If not found, try with userId
          if (renderer == null) {
            renderer = remoteRenderers[participant.userId];
          }
          
          // If still not found, try with socket ID
          if (renderer == null && participant.socketId.isNotEmpty) {
            renderer = remoteRenderers[participant.socketId];
          }

          return RemoteParticipantView(
            participant: participant,
            videoRenderer: renderer,
            showDebugInfo: _showDebugInfo,
          );
        },
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _refreshConnections,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _testWebRTCConnections,
            icon: const Icon(Icons.network_check),
            label: const Text('Test Connections'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _refreshConnections() {
    // Trigger a refresh of connections
    ref.read(videoCallProvider.notifier).refreshConnections();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing connections...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _testWebRTCConnections() {
    // Show connection test results
    final videoCallState = ref.read(videoCallProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WebRTC Connection Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remote Renderers: ${videoCallState.remoteRenderers.length}'),
            Text('Remote Participants: ${videoCallState.participants.where((p) => !p.isLocal).length}'),
            const SizedBox(height: 16),
            if (videoCallState.remoteRenderers.isEmpty)
              const Text(
                'No remote video streams detected.\nThis could indicate:\n• WebRTC connection issues\n• Signaling problems\n• Peer connection setup errors',
                style: TextStyle(color: Colors.red),
              )
            else
              const Text(
                'Remote streams detected successfully!',
                style: TextStyle(color: Colors.green),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
