import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class StreamDebugWidget extends StatelessWidget {
  final Map<String, RTCVideoRenderer> remoteRenderers;
  final RTCVideoRenderer? localRenderer;
  final List<dynamic> participants;

  const StreamDebugWidget({
    super.key,
    required this.remoteRenderers,
    this.localRenderer,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'STREAM DEBUG INFO',
            style: TextStyle(
              color: Colors.yellow,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Local Renderer: ${localRenderer != null ? "Available" : "NULL"}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            'Remote Renderers Count: ${remoteRenderers.length}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            'Participants Count: ${participants.length}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 8),
          
          // Local renderer details
          if (localRenderer != null) ...[
            const Text(
              'Local Stream Details:',
              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              '  - Stream Object: ${localRenderer!.srcObject != null ? "Present" : "NULL"}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            if (localRenderer!.srcObject != null) ...[
              Text(
                '  - Stream ID: ${localRenderer!.srcObject!.id}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                '  - Video Tracks: ${localRenderer!.srcObject!.getVideoTracks().length}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                '  - Audio Tracks: ${localRenderer!.srcObject!.getAudioTracks().length}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ],

          // Remote renderers details
          if (remoteRenderers.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Remote Streams Details:',
              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            ...remoteRenderers.entries.map((entry) {
              final participantId = entry.key;
              final renderer = entry.value;
              return Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Participant: $participantId',
                      style: const TextStyle(color: Colors.cyan, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '  - Renderer: ${renderer.runtimeType}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    Text(
                      '  - Stream Object: ${renderer.srcObject != null ? "Present" : "NULL"}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    if (renderer.srcObject != null) ...[
                      Text(
                        '  - Stream ID: ${renderer.srcObject!.id}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      Text(
                        '  - Video Tracks: ${renderer.srcObject!.getVideoTracks().length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      Text(
                        '  - Audio Tracks: ${renderer.srcObject!.getAudioTracks().length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      
                      // Check video track states
                      ...renderer.srcObject!.getVideoTracks().map((track) {
                        return Text(
                          '    • Video Track ${track.id}: enabled=${track.enabled}, muted=${track.muted}',
                          style: const TextStyle(color: Colors.white, fontSize: 9),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],

          // Participants details
          if (participants.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Participants List:',
              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            ...participants.map((participant) {
              return Text(
                '  - ${participant.toString()}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}
