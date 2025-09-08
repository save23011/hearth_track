import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../providers/video_call_provider.dart';

class VideoCallDebugScreen extends ConsumerStatefulWidget {
  const VideoCallDebugScreen({super.key});

  @override
  ConsumerState<VideoCallDebugScreen> createState() => _VideoCallDebugScreenState();
}

class _VideoCallDebugScreenState extends ConsumerState<VideoCallDebugScreen> {
  @override
  Widget build(BuildContext context) {
    final videoCallState = ref.watch(videoCallProvider);
    final notifier = ref.read(videoCallProvider.notifier);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Video Call Debug Center',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => notifier.refreshConnections(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Card
            _buildConnectionStatusCard(videoCallState),
            const SizedBox(height: 16),
            
            // Streams Overview Card
            _buildStreamsOverviewCard(videoCallState),
            const SizedBox(height: 16),
            
            // Remote Participants Card
            _buildRemoteParticipantsCard(videoCallState),
            const SizedBox(height: 16),
            
            // Debug Actions Card
            _buildDebugActionsCard(notifier),
            const SizedBox(height: 16),
            
            // Raw Debug Data Card
            _buildRawDebugDataCard(videoCallState),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard(VideoCallState state) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusRow('In Call', state.isInCall ? 'Yes' : 'No', state.isInCall ? Colors.green : Colors.red),
            _buildStatusRow('Video Enabled', state.isVideoEnabled ? 'Yes' : 'No', state.isVideoEnabled ? Colors.green : Colors.orange),
            _buildStatusRow('Audio Enabled', state.isAudioEnabled ? 'Yes' : 'No', state.isAudioEnabled ? Colors.green : Colors.orange),
            _buildStatusRow('Local Renderer', state.localRenderer != null ? 'Available' : 'Not Available', state.localRenderer != null ? Colors.green : Colors.red),
            if (state.errorMessage != null)
              _buildStatusRow('Error', state.errorMessage!, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamsOverviewCard(VideoCallState state) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Streams Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Total Participants', '${state.participants.length}', Colors.blue),
            _buildStatusRow('Remote Participants', '${state.participants.where((p) => !p.isLocal).length}', Colors.blue),
            _buildStatusRow('Remote Renderers', '${state.remoteRenderers.length}', state.remoteRenderers.isNotEmpty ? Colors.green : Colors.red),
            
            const SizedBox(height: 8),
            const Text(
              'Renderer Keys:',
              style: TextStyle(color: Colors.yellow, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (state.remoteRenderers.isEmpty)
              const Text('  No remote renderers', style: TextStyle(color: Colors.red, fontSize: 12))
            else
              ...state.remoteRenderers.keys.map((key) => Text(
                '  • $key',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteParticipantsCard(VideoCallState state) {
    final remoteParticipants = state.participants.where((p) => !p.isLocal).toList();
    
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Remote Participants',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (remoteParticipants.isEmpty)
              const Text(
                'No remote participants',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              )
            else
              ...remoteParticipants.map((participant) {
                final renderer = _getRendererForParticipant(participant, state.remoteRenderers);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: renderer != null ? Colors.green : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participant.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusRow('User ID', participant.userId, Colors.blue),
                      _buildStatusRow('Peer ID', participant.peerId, Colors.blue),
                      _buildStatusRow('Socket ID', participant.socketId, Colors.blue),
                      _buildStatusRow('Has Video', participant.hasVideo ? 'Yes' : 'No', participant.hasVideo ? Colors.green : Colors.orange),
                      _buildStatusRow('Has Audio', participant.hasAudio ? 'Yes' : 'No', participant.hasAudio ? Colors.green : Colors.orange),
                      _buildStatusRow('Renderer Available', renderer != null ? 'Yes' : 'No', renderer != null ? Colors.green : Colors.red),
                      
                      if (renderer != null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Renderer Details:',
                          style: TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        _buildStatusRow('  Has Stream', renderer.srcObject != null ? 'Yes' : 'No', renderer.srcObject != null ? Colors.green : Colors.red),
                        if (renderer.srcObject != null) ...[
                          _buildStatusRow('  Video Tracks', '${renderer.srcObject!.getVideoTracks().length}', Colors.white),
                          _buildStatusRow('  Audio Tracks', '${renderer.srcObject!.getAudioTracks().length}', Colors.white),
                        ],
                      ],
                      
                      // Video preview if available
                      if (renderer != null && renderer.srcObject != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: RTCVideoView(
                              renderer,
                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                              mirror: false,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugActionsCard(VideoCallNotifier notifier) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => notifier.refreshConnections(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Connections'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _syncParticipants(notifier),
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync Participants'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showConnectionInfo(),
                  icon: const Icon(Icons.info),
                  label: const Text('Connection Info'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => notifier.clearError(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Errors'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRawDebugDataCard(VideoCallState state) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Raw Debug Data',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey, width: 1),
              ),
              child: SelectableText(
                '''
Remote Renderers Keys: ${state.remoteRenderers.keys.toList()}
Participants: ${state.participants.map((p) => '${p.fullName} (${p.isLocal ? "LOCAL" : "REMOTE"}, userId: ${p.userId}, peerId: ${p.peerId})').join(', ')}
Session ID: ${state.currentSession?.sessionId ?? 'None'}
                ''',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  RTCVideoRenderer? _getRendererForParticipant(dynamic participant, Map<String, RTCVideoRenderer> remoteRenderers) {
    // Try multiple keys
    if (participant.peerId.isNotEmpty) {
      final renderer = remoteRenderers[participant.peerId];
      if (renderer != null) return renderer;
    }
    
    final renderer = remoteRenderers[participant.userId];
    if (renderer != null) return renderer;
    
    if (participant.socketId.isNotEmpty) {
      return remoteRenderers[participant.socketId];
    }
    
    return null;
  }

  void _showConnectionInfo() {
    final videoCallState = ref.read(videoCallProvider);
    final debugInfo = ref.read(videoCallProvider.notifier).getRendererMappingDebug();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Renderer Mappings:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...debugInfo.entries.map((entry) => Text('${entry.key}: ${entry.value}')),
              const SizedBox(height: 16),
              const Text('Remote Renderers:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...videoCallState.remoteRenderers.entries.map((entry) => 
                Text('${entry.key}: ${entry.value.srcObject != null ? "Has Stream" : "No Stream"}')),
            ],
          ),
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

  void _syncParticipants(VideoCallNotifier notifier) async {
    try {
      // Access the private method through reflection or create a public method
      await notifier.refreshConnections(); // This now includes sync
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Participants synced successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
