import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static const String _baseUrl = AppConfig.baseUrl;
  static String? _authToken;
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Initialize the service
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(AppConfig.tokenKey);
  }

  // Get headers with authentication
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Get headers for multipart requests
  Map<String, String> get _multipartHeaders => {
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Set auth token
  static Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.tokenKey, token);
  }

  // Clear auth token
  static Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
  }

  // Get auth token
  static String? get authToken => _authToken;

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final uriWithParams = queryParams != null
          ? uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())))
          : uri;

      final response = await http.get(uriWithParams, headers: _headers);
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(data),
      );
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(data),
      );
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
      );
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // File upload request
  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    File file, {
    String fieldName = 'file',
    Map<String, String>? additionalFields,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$endpoint'),
      );

      request.headers.addAll(_multipartHeaders);
      request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Upload error: ${e.toString()}');
    }
  }

  // Handle response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    try {
      // Check if response body is empty
      if (response.body.isEmpty) {
        return ApiResponse.error(
          'Empty response from server',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (fromJson != null && data['data'] != null) {
          try {
            return ApiResponse.success(fromJson(data['data']), data['message']?.toString());
          } catch (e) {
            return ApiResponse.error(
              'Failed to parse data object: ${e.toString()}',
              statusCode: response.statusCode,
            );
          }
        }
        return ApiResponse.success(data as T, data['message']?.toString());
      } else {
        return ApiResponse.error(
          data['message']?.toString() ?? 'Unknown error occurred',
          statusCode: response.statusCode,
          data: data,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to parse response: ${e.toString()}',
        statusCode: response.statusCode,
      );
    }
  }
}

// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;
  final Map<String, dynamic>? errorData;

  ApiResponse._({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.statusCode,
    this.errorData,
  });

  factory ApiResponse.success(T data, [String? message]) {
    return ApiResponse._(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.error(
    String error, {
    int? statusCode,
    Map<String, dynamic>? data,
  }) {
    return ApiResponse._(
      success: false,
      error: error,
      statusCode: statusCode,
      errorData: data,
    );
  }

  bool get isSuccess => success;
  bool get isError => !success;
}

// API Endpoints
class ApiEndpoints {
  // Authentication
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgotpassword';
  static const String resetPassword = '/auth/resetpassword';
  static const String verifyEmail = '/auth/verify-email';
  static const String verifyPhone = '/auth/verify-phone';
  static const String resendEmailVerification = '/auth/resend-email-verification';

  // User Management
  static const String userProfile = '/users/profile';
  static const String userSettings = '/users/settings';
  static const String userDashboard = '/users/dashboard';
  static const String userDevices = '/users/devices';
  static const String userAvatar = '/users/profile/avatar';

  // AI Module
  static const String aiModule = '/ai/module';
  static const String conceptMaps = '/ai/concept-maps';
  static const String aiRecommendations = '/ai/recommendations';
  static const String generateRecommendations = '/ai/recommendations/generate';

  // Questionnaires
  static const String questionnaires = '/questionnaires';
  static const String myQuestionnaireResponses = '/questionnaires/responses/my';
  
  static String startQuestionnaire(String id) => '/questionnaires/$id/start';
  static String answerQuestionnaire(String id) => '/questionnaires/$id/answer';
  static String questionnaireResults(String id) => '/questionnaires/$id/results';

  // Therapy Sessions
  static const String therapySessions = '/therapy/sessions';
  static const String myTherapySessions = '/therapy/sessions/my';
  
  static String startTherapySession(String id) => '/therapy/sessions/$id/start';
  static String joinTherapySession(String id) => '/therapy/sessions/$id/join';
  static String endTherapySession(String id) => '/therapy/sessions/$id/end';

  // Exercises
  static const String exercises = '/exercises';
  static const String dailyExercises = '/exercises/daily';
  static const String myExercises = '/exercises/my';
  
  static String completeExercise(String id) => '/exercises/$id/complete';
  static String exerciseProgress(String id) => '/exercises/$id/progress';

  // Content
  static const String content = '/content';
  static const String contentFeed = '/content/feed';
  static const String contentCategories = '/content/categories';

  // Journal
  static const String journal = '/journal';
  static const String journalEntries = '/journal/entries';
  
  static String journalEntry(String id) => '/journal/entries/$id';

  // Tasks
  static const String tasks = '/tasks';
  static const String myTasks = '/tasks/my';
  
  static String completeTask(String id) => '/tasks/$id/complete';

  // Notifications
  static const String notifications = '/notifications';
  static const String markNotificationRead = '/notifications/mark-read';
  static const String notificationSettings = '/notifications/settings';

  // Admin (if user has admin role)
  static const String adminUsers = '/admin/users';
  static const String adminContent = '/admin/content';
  static const String adminSessions = '/admin/sessions';
  static const String adminBroadcast = '/admin/broadcast';
}
