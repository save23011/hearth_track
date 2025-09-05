import '../models/user_model.dart';
import '../../core/services/api_service.dart';

class AuthService {
  static final ApiService _apiService = ApiService();

  // Register user
  static Future<AuthResponse> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        },
      );

      if (response.isSuccess && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);
        
        // Save token if registration successful
        if (authResponse.success && authResponse.token != null) {
          await ApiService.setAuthToken(authResponse.token!);
        }
        
        return authResponse;
      } else {
        return AuthResponse(
          success: false,
          message: response.error ?? 'Registration failed',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Login user
  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        {
          'email': email,
          'password': password,
        },
      );

      if (response.isSuccess && response.data != null) {
        // The response data already contains the auth response directly
        final authResponse = AuthResponse.fromJson(response.data!);
        
        // Save token if login successful
        if (authResponse.success && authResponse.token != null) {
          await ApiService.setAuthToken(authResponse.token!);
        }
        
        return authResponse;
      } else {
        return AuthResponse(
          success: false,
          message: response.error ?? 'Login failed',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Get current user
  static Future<User?> getCurrentUser() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.me,
        fromJson: (data) => data,
      );

      if (response.isSuccess && response.data != null) {
        return User.fromJson(response.data!['user']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Logout user
  static Future<bool> logout() async {
    try {
      await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.logout,
        {},
      );
      
      // Clear token regardless of API response
      await ApiService.clearAuthToken();
      return true;
    } catch (e) {
      // Clear token even if API call fails
      await ApiService.clearAuthToken();
      return true;
    }
  }

  // Forgot password
  static Future<bool> forgotPassword(String email) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.forgotPassword,
        {'email': email},
      );

      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Reset password
  static Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '${ApiEndpoints.resetPassword}/$token',
        {'password': newPassword},
      );

      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Verify email
  static Future<bool> verifyEmail(String token) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.verifyEmail,
        {'token': token},
      );

      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Verify phone
  static Future<bool> verifyPhone({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.verifyPhone,
        {
          'phoneNumber': phoneNumber,
          'code': code,
        },
      );

      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Resend email verification
  static Future<bool> resendEmailVerification() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.resendEmailVerification,
        {},
      );

      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Check if user is logged in
  static bool get isLoggedIn => ApiService.authToken != null;

  // Get auth token
  static String? get authToken => ApiService.authToken;

  // Social login with Google
  static Future<AuthResponse> loginWithGoogle(String idToken) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/auth/google',
        {'idToken': idToken},
      );

      if (response.isSuccess && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);
        
        // Save token if login successful
        if (authResponse.success && authResponse.token != null) {
          await ApiService.setAuthToken(authResponse.token!);
        }
        
        return authResponse;
      } else {
        return AuthResponse(
          success: false,
          message: response.error ?? 'Google login failed',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Social login with Facebook
  static Future<AuthResponse> loginWithFacebook(String accessToken) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/auth/facebook',
        {'accessToken': accessToken},
      );

      if (response.isSuccess && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);
        
        // Save token if login successful
        if (authResponse.success && authResponse.token != null) {
          await ApiService.setAuthToken(authResponse.token!);
        }
        
        return authResponse;
      } else {
        return AuthResponse(
          success: false,
          message: response.error ?? 'Facebook login failed',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}
