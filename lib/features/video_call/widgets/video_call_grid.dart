import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call_participant.dart';
import 'participant_video_view.dart';

class VideoCallGrid extends StatelessWidget {
  final List<CallParticipant> participants;
  final Map<String, RTCVideoRenderer> remoteRenderers;
  final RTCVideoRenderer? localRenderer;

  const VideoCallGrid({
    super.key,
    required this.participants,
    required this.remoteRenderers,
    this.localRenderer,
  });

  @override
  Widget build(BuildContext context) {
    final participantCount = participants.length;
    
    if (participantCount == 0) {
      return const Center(
        child: Text(
          'No participants in call',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildGridLayout(context, constraints, participantCount);
      },
    );
  }

  Widget _buildGridLayout(BuildContext context, BoxConstraints constraints, int count) {
    if (count == 1) {
      return _buildSingleParticipantView();
    } else if (count == 2) {
      return _buildTwoParticipantView();
    } else if (count <= 4) {
      return _buildFourGridView();
    } else if (count <= 6) {
      return _buildSixGridView();
    } else {
      return _buildScrollableGridView();
    }
  }

  Widget _buildSingleParticipantView() {
    final participant = participants.first;
    final renderer = participant.isLocal 
        ? localRenderer 
        : remoteRenderers[participant.userId];

    return Padding(
      padding: const EdgeInsets.all(8),
      child: ParticipantVideoView(
        participant: participant,
        videoRenderer: renderer,
        isLocalParticipant: participant.isLocal,
      ),
    );
  }

  Widget _buildTwoParticipantView() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: _buildParticipantView(participants[0]),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: _buildParticipantView(participants[1]),
          ),
        ),
      ],
    );
  }

  Widget _buildFourGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 4 / 3,
      ),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        return _buildParticipantView(participants[index]);
      },
    );
  }

  Widget _buildSixGridView() {
    return Column(
      children: [
        // Top row with 2 participants
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _buildParticipantView(participants[0]),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _buildParticipantView(participants[1]),
                ),
              ),
            ],
          ),
        ),
        // Middle row with 2 participants
        if (participants.length > 2)
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildParticipantView(participants[2]),
                  ),
                ),
                if (participants.length > 3)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _buildParticipantView(participants[3]),
                    ),
                  ),
              ],
            ),
          ),
        // Bottom row with remaining participants
        if (participants.length > 4)
          Expanded(
            child: Row(
              children: [
                if (participants.length > 4)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _buildParticipantView(participants[4]),
                    ),
                  ),
                if (participants.length > 5)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _buildParticipantView(participants[5]),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildScrollableGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 4 / 3,
      ),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        return _buildParticipantView(participants[index]);
      },
    );
  }

  Widget _buildParticipantView(CallParticipant participant) {
    final renderer = participant.isLocal 
        ? localRenderer 
        : remoteRenderers[participant.userId];

    return ParticipantVideoView(
      participant: participant,
      videoRenderer: renderer,
      isLocalParticipant: participant.isLocal,
    );
  }
}
