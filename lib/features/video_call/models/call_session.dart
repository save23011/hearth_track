import 'package:equatable/equatable.dart';
import 'call_participant.dart';

enum CallStatus {
  idle,
  connecting,
  connected,
  disconnected,
  error,
  ended,
}

enum CallType {
  video,
  audio,
  screen,
}

class CallSession extends Equatable {
  final String sessionId;
  final String initiatorId;
  final CallType callType;
  final CallStatus status;
  final List<CallParticipant> participants;
  final CallSettings callSettings;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? errorMessage;

  const CallSession({
    required this.sessionId,
    required this.initiatorId,
    required this.callType,
    required this.status,
    required this.participants,
    required this.callSettings,
    this.startTime,
    this.endTime,
    this.errorMessage,
  });

  bool get isActive => status == CallStatus.connected || status == CallStatus.connecting;
  
  int get participantCount => participants.length;
  
  Duration? get duration {
    if (startTime == null) return null;
    final endTimeToUse = endTime ?? DateTime.now();
    return endTimeToUse.difference(startTime!);
  }

  CallParticipant? get localParticipant {
    try {
      return participants.firstWhere((p) => p.isLocal);
    } catch (e) {
      return null;
    }
  }

  List<CallParticipant> get remoteParticipants {
    return participants.where((p) => !p.isLocal).toList();
  }

  CallSession copyWith({
    String? sessionId,
    String? initiatorId,
    CallType? callType,
    CallStatus? status,
    List<CallParticipant>? participants,
    CallSettings? callSettings,
    DateTime? startTime,
    DateTime? endTime,
    String? errorMessage,
  }) {
    return CallSession(
      sessionId: sessionId ?? this.sessionId,
      initiatorId: initiatorId ?? this.initiatorId,
      callType: callType ?? this.callType,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      callSettings: callSettings ?? this.callSettings,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory CallSession.fromJson(Map<String, dynamic> json) {
    return CallSession(
      sessionId: json['sessionId'] as String,
      initiatorId: json['initiatorId'] as String,
      callType: CallType.values.firstWhere(
        (e) => e.name == (json['callType'] as String? ?? 'video'),
        orElse: () => CallType.video,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'idle'),
        orElse: () => CallStatus.idle,
      ),
      participants: (json['participants'] as List<dynamic>?)
          ?.map((p) => CallParticipant.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      callSettings: CallSettings.fromJson(
        json['callSettings'] as Map<String, dynamic>? ?? {},
      ),
      startTime: json['startTime'] != null 
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'initiatorId': initiatorId,
      'callType': callType.name,
      'status': status.name,
      'participants': participants.map((p) => p.toJson()).toList(),
      'callSettings': callSettings.toJson(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  @override
  List<Object?> get props => [
        sessionId,
        initiatorId,
        callType,
        status,
        participants,
        callSettings,
        startTime,
        endTime,
        errorMessage,
      ];
}

class CallSettings extends Equatable {
  final bool videoEnabled;
  final bool audioEnabled;
  final bool screenShareEnabled;
  final int maxParticipants;
  final bool isRecordingEnabled;
  final Map<String, dynamic> additionalSettings;

  const CallSettings({
    this.videoEnabled = true,
    this.audioEnabled = true,
    this.screenShareEnabled = false,
    this.maxParticipants = 10,
    this.isRecordingEnabled = false,
    this.additionalSettings = const {},
  });

  CallSettings copyWith({
    bool? videoEnabled,
    bool? audioEnabled,
    bool? screenShareEnabled,
    int? maxParticipants,
    bool? isRecordingEnabled,
    Map<String, dynamic>? additionalSettings,
  }) {
    return CallSettings(
      videoEnabled: videoEnabled ?? this.videoEnabled,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      screenShareEnabled: screenShareEnabled ?? this.screenShareEnabled,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      isRecordingEnabled: isRecordingEnabled ?? this.isRecordingEnabled,
      additionalSettings: additionalSettings ?? this.additionalSettings,
    );
  }

  factory CallSettings.fromJson(Map<String, dynamic> json) {
    return CallSettings(
      videoEnabled: json['videoEnabled'] as bool? ?? true,
      audioEnabled: json['audioEnabled'] as bool? ?? true,
      screenShareEnabled: json['screenShareEnabled'] as bool? ?? false,
      maxParticipants: json['maxParticipants'] as int? ?? 10,
      isRecordingEnabled: json['isRecordingEnabled'] as bool? ?? false,
      additionalSettings: json['additionalSettings'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoEnabled': videoEnabled,
      'audioEnabled': audioEnabled,
      'screenShareEnabled': screenShareEnabled,
      'maxParticipants': maxParticipants,
      'isRecordingEnabled': isRecordingEnabled,
      'additionalSettings': additionalSettings,
    };
  }

  @override
  List<Object?> get props => [
        videoEnabled,
        audioEnabled,
        screenShareEnabled,
        maxParticipants,
        isRecordingEnabled,
        additionalSettings,
      ];
}
