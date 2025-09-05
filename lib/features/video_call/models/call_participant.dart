import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallParticipant extends Equatable {
  final String userId;
  final String peerId;
  final String socketId;
  final String firstName;
  final String lastName;
  final String? profilePicture;
  final bool hasVideo;
  final bool hasAudio;
  final bool isScreenSharing;
  final RTCVideoRenderer? videoRenderer;
  final bool isLocal;

  const CallParticipant({
    required this.userId,
    required this.peerId,
    required this.socketId,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
    this.hasVideo = true,
    this.hasAudio = true,
    this.isScreenSharing = false,
    this.videoRenderer,
    this.isLocal = false,
  });

  String get fullName => '$firstName $lastName';

  String get initials => 
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

  CallParticipant copyWith({
    String? userId,
    String? peerId,
    String? socketId,
    String? firstName,
    String? lastName,
    String? profilePicture,
    bool? hasVideo,
    bool? hasAudio,
    bool? isScreenSharing,
    RTCVideoRenderer? videoRenderer,
    bool? isLocal,
  }) {
    return CallParticipant(
      userId: userId ?? this.userId,
      peerId: peerId ?? this.peerId,
      socketId: socketId ?? this.socketId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profilePicture: profilePicture ?? this.profilePicture,
      hasVideo: hasVideo ?? this.hasVideo,
      hasAudio: hasAudio ?? this.hasAudio,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      videoRenderer: videoRenderer ?? this.videoRenderer,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      userId: json['userId'] as String,
      peerId: json['peerId'] as String,
      socketId: json['socketId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      profilePicture: json['profilePicture'] as String?,
      hasVideo: json['hasVideo'] as bool? ?? true,
      hasAudio: json['hasAudio'] as bool? ?? true,
      isScreenSharing: json['isScreenSharing'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'peerId': peerId,
      'socketId': socketId,
      'firstName': firstName,
      'lastName': lastName,
      'profilePicture': profilePicture,
      'hasVideo': hasVideo,
      'hasAudio': hasAudio,
      'isScreenSharing': isScreenSharing,
    };
  }

  @override
  List<Object?> get props => [
        userId,
        peerId,
        socketId,
        firstName,
        lastName,
        profilePicture,
        hasVideo,
        hasAudio,
        isScreenSharing,
        isLocal,
      ];
}
