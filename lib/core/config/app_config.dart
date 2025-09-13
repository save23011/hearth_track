class AppConfig {
  // API Configuration
  static const String baseUrl = 'https://sol-3a0fa16a1680.herokuapp.com/api';
  static const String socketUrl = 'https://sol-3a0fa16a1680.herokuapp.com';
  
  // For production, use your deployed backend URL
  // static const String baseUrl = 'https://your-domain.com/api';
  // static const String socketUrl = 'https://your-domain.com';
  
  // App Information
  static const String appName = 'Soulene';
  static const String appVersion = '1.0.0';
  
  // Database Configuration
  static const String databaseName = 'hearth_track.db';
  static const int databaseVersion = 1;
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  static const String notificationKey = 'notification_settings';
  
  // File Upload Configuration
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedAudioTypes = ['mp3', 'wav', 'aac'];
  static const List<String> allowedVideoTypes = ['mp4', 'mov', 'avi'];
  
  // WebRTC Configuration
  static const Map<String, dynamic> rtcConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };
  
  // Feature Flags
  static const bool enableSocialLogin = true;
  static const bool enablePushNotifications = true;
  static const bool enableVideoCall = true;
  static const bool enableAudioRecording = true;
  static const bool enableLocationServices = false;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Questionnaire Configuration
  static const int maxQuestionsPerPage = 5;
  static const Duration questionnaireTimeout = Duration(minutes: 30);
  
  // Therapy Session Configuration
  static const Duration maxSessionDuration = Duration(hours: 2);
  static const Duration sessionWarningTime = Duration(minutes: 5);
  
  // Exercise Configuration
  static const Duration defaultExerciseDuration = Duration(minutes: 10);
  static const int dailyExerciseGoal = 3;
  
  // Journal Configuration
  static const int maxJournalEntryLength = 5000;
  static const int maxVoiceRecordingDuration = 300; // seconds
  
  // Notification Configuration
  static const String defaultNotificationChannelId = 'hearth_track_general';
  static const String defaultNotificationChannelName = 'General Notifications';
  static const String reminderChannelId = 'hearth_track_reminders';
  static const String reminderChannelName = 'Reminders';
  
  // Colors (hex values for consistency with design system)
  static const String primaryColorHex = '#6366F1';
  static const String secondaryColorHex = '#EC4899';
  static const String accentColorHex = '#F59E0B';
  static const String errorColorHex = '#EF4444';
  static const String successColorHex = '#10B981';
  static const String warningColorHex = '#F59E0B';
}
