class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? profilePicture;
  final DateTime? dateOfBirth;
  final String? gender;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfile? profile;
  final UserSettings? settings;
  final List<String>? roles;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.profilePicture,
    this.dateOfBirth,
    this.gender,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.createdAt,
    required this.updatedAt,
    this.profile,
    this.settings,
    this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: _extractPhoneNumber(json),
      profilePicture: _extractProfilePicture(json),
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : null,
      gender: json['gender'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      profile: json['profile'] != null 
          ? UserProfile.fromJson(json['profile']) 
          : null,
      settings: json['settings'] != null 
          ? UserSettings.fromJson(json['settings']) 
          : null,
      roles: json['roles'] != null 
          ? List<String>.from(json['roles']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'profile': profile?.toJson(),
      'settings': settings?.toJson(),
      'roles': roles,
    };
  }

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();

  // Helper methods for extracting complex fields
  static String? _extractPhoneNumber(Map<String, dynamic> json) {
    if (json['phoneNumber'] != null) {
      return json['phoneNumber'].toString();
    }
    if (json['phone'] != null) {
      if (json['phone'] is String) {
        return json['phone'];
      } else if (json['phone'] is Map) {
        // If phone is an object, try to extract a meaningful value
        final phoneMap = json['phone'] as Map<String, dynamic>;
        return phoneMap['number']?.toString() ?? phoneMap['value']?.toString();
      }
    }
    return null;
  }

  static String? _extractProfilePicture(Map<String, dynamic> json) {
    if (json['profilePicture'] != null) {
      return json['profilePicture'].toString();
    }
    if (json['avatar'] != null) {
      if (json['avatar'] is String) {
        return json['avatar'];
      } else if (json['avatar'] is Map) {
        // If avatar is an object, try to extract a meaningful value
        final avatarMap = json['avatar'] as Map<String, dynamic>;
        return avatarMap['url']?.toString() ?? avatarMap['path']?.toString();
      }
    }
    return null;
  }
}

class UserProfile {
  final double? height;
  final double? weight;
  final String? bloodType;
  final List<String>? allergies;
  final List<String>? medications;
  final List<String>? medicalConditions;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final Map<String, dynamic>? fitnessGoals;
  final Map<String, dynamic>? mentalHealthGoals;

  UserProfile({
    this.height,
    this.weight,
    this.bloodType,
    this.allergies,
    this.medications,
    this.medicalConditions,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.fitnessGoals,
    this.mentalHealthGoals,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      bloodType: json['bloodType'],
      allergies: json['allergies'] != null 
          ? List<String>.from(json['allergies']) 
          : null,
      medications: json['medications'] != null 
          ? List<String>.from(json['medications']) 
          : null,
      medicalConditions: json['medicalConditions'] != null 
          ? List<String>.from(json['medicalConditions']) 
          : null,
      emergencyContactName: json['emergencyContactName'],
      emergencyContactPhone: json['emergencyContactPhone'],
      fitnessGoals: json['fitnessGoals'],
      mentalHealthGoals: json['mentalHealthGoals'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'height': height,
      'weight': weight,
      'bloodType': bloodType,
      'allergies': allergies,
      'medications': medications,
      'medicalConditions': medicalConditions,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'fitnessGoals': fitnessGoals,
      'mentalHealthGoals': mentalHealthGoals,
    };
  }
}

class UserSettings {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final String language;
  final String timezone;
  final String theme;
  final Map<String, bool>? notificationTypes;
  final Map<String, dynamic>? privacySettings;

  UserSettings({
    required this.pushNotifications,
    required this.emailNotifications,
    required this.smsNotifications,
    required this.language,
    required this.timezone,
    required this.theme,
    this.notificationTypes,
    this.privacySettings,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      pushNotifications: json['pushNotifications'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      smsNotifications: json['smsNotifications'] ?? false,
      language: json['language'] ?? 'en',
      timezone: json['timezone'] ?? 'UTC',
      theme: json['theme'] ?? 'light',
      notificationTypes: json['notificationTypes'] != null
          ? Map<String, bool>.from(json['notificationTypes'])
          : null,
      privacySettings: json['privacySettings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'language': language,
      'timezone': timezone,
      'theme': theme,
      'notificationTypes': notificationTypes,
      'privacySettings': privacySettings,
    };
  }
}

class AuthResponse {
  final bool success;
  final String? token;
  final User? user;
  final String? message;

  AuthResponse({
    required this.success,
    this.token,
    this.user,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'token': token,
      'user': user?.toJson(),
      'message': message,
    };
  }
}
