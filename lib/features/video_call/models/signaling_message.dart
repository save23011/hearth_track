import 'package:equatable/equatable.dart';

class SignalingMessage extends Equatable {
  final String type;
  final String from;
  final String to;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const SignalingMessage({
    required this.type,
    required this.from,
    required this.to,
    required this.data,
    required this.timestamp,
  });

  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    return SignalingMessage(
      type: json['type'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'from': from,
      'to': to,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [type, from, to, data, timestamp];
}

enum SignalingMessageType {
  offer('offer'),
  answer('answer'),
  candidate('candidate'),
  hangup('hangup'),
  joinCall('join_call'),
  leaveCall('leave_call'),
  toggleVideo('toggle_video'),
  toggleAudio('toggle_audio'),
  shareScreen('share_screen'),
  stopScreenShare('stop_screen_share');

  const SignalingMessageType(this.value);
  final String value;
}
