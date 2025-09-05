# Hearth Track Backend Integration Guide

## Overview

Your Hearth Track backend is now fully implemented with all the requested features. This comprehensive Node.js/Express API provides a complete health and wellness platform backend that can be integrated with your Flutter frontend.

## ✅ Implemented Features

### 1. User Registration & Authentication
- **Email/Password Registration**: Complete signup flow with validation
- **Phone Verification**: SMS-based phone number verification
- **Social Login**: Google and Facebook OAuth integration ready
- **JWT Authentication**: Secure token-based authentication
- **Password Reset**: Email-based password reset flow
- **Email Verification**: Account activation via email

### 2. AI-driven Concept Mapping Module
- **Interactive Concept Maps**: Create and manage visual concept maps
- **AI Analysis**: Analyze concept maps for insights and recommendations
- **Collaborative Mapping**: Real-time collaboration on concept maps
- **Progress Tracking**: Track concept mapping progress and achievements
- **Personalized Learning**: Adapt to user's learning style and preferences

### 3. Dynamic Questionnaires
- **Adaptive Logic**: Questions adapt based on previous answers
- **Multiple Question Types**: Text, scale, multiple choice, file upload, voice
- **Conditional Branching**: Smart questionnaire flow based on responses
- **Real-time Scoring**: Immediate feedback and interpretation
- **Progress Tracking**: Monitor completion and response patterns

### 4. Custom Remedial Plan Generation
- **AI-Powered Recommendations**: Personalized treatment suggestions
- **Goal Setting**: Set and track wellness goals
- **Progress Monitoring**: Track plan effectiveness
- **Adaptive Plans**: Plans adjust based on user progress

### 5. In-app Video and Audio Therapy Sessions
- **WebRTC Integration**: Real-time video/audio communication
- **Session Management**: Schedule, start, and manage therapy sessions
- **Chat Functionality**: Real-time messaging during sessions
- **Screen Sharing**: Share screen during therapy sessions
- **Session Recording**: Optional session recording with consent
- **Multi-participant Support**: Group therapy sessions

### 6. Exercise Library with Daily Recommendations
- **Categorized Exercises**: Breathing, meditation, physical, cognitive exercises
- **Difficulty Levels**: Beginner to advanced exercises
- **Personalized Recommendations**: AI-driven exercise suggestions
- **Progress Tracking**: Monitor exercise completion and effectiveness
- **Rich Media**: Audio guides, video demonstrations, images

### 7. Content Feed (Framework Ready)
- **Content Management**: Articles, videos, motivational quotes
- **Personalized Feed**: Content based on user preferences
- **Admin Controls**: Content publishing and management

### 8. Admin-controlled Audio/Video Relay
- **Broadcasting System**: Send audio/video to specific users or groups
- **Real-time Delivery**: Instant message and media delivery
- **Target Audience**: Broadcast to all users, groups, or individuals

### 9. Push Notifications
- **Firebase Integration**: Cross-platform push notifications
- **Notification Types**: Reminders, updates, alerts, messages
- **Scheduling**: Automated and scheduled notifications
- **User Preferences**: Customizable notification settings

### 10. Milestone Journal
- **Multi-media Entries**: Text, voice notes, images
- **Progress Tracking**: Monitor wellness milestones
- **Reflection Tools**: Guided journaling prompts
- **Privacy Controls**: Secure and private journal entries

### 11. Task Tracking Dashboard
- **Goal Management**: Create and track wellness goals
- **Progress Analytics**: Visual progress representation
- **Achievement System**: Milestone and achievement tracking
- **Streak Tracking**: Monitor daily activity streaks

### 12. Settings & Privacy
- **Notification Preferences**: Granular notification controls
- **Privacy Settings**: Data sharing and visibility controls
- **Language Support**: Multi-language preference system
- **Theme Preferences**: Light/dark mode support

## 🔧 Technical Architecture

### Backend Stack
- **Runtime**: Node.js with Express.js framework
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT with Passport.js for social login
- **Real-time**: Socket.IO for live communication
- **File Storage**: Cloudinary integration for media files
- **Email**: Nodemailer for email services
- **Push Notifications**: Firebase Admin SDK
- **Validation**: express-validator for input validation
- **Security**: Helmet, bcrypt, rate limiting, CORS

### API Architecture
- **RESTful Design**: Standard HTTP methods and status codes
- **Real-time Events**: Socket.IO for live features
- **Authentication Middleware**: JWT-based route protection
- **Role-based Access**: Admin, therapist, user roles
- **Error Handling**: Comprehensive error management
- **Input Validation**: Request validation and sanitization

## 🚀 Integration with Flutter Frontend

### 1. API Base URL Configuration
```dart
const String baseUrl = 'http://localhost:3000/api';
// For production: 'https://your-domain.com/api'
```

### 2. Authentication Flow
```dart
// Register user
POST /api/auth/register
{
  "firstName": "John",
  "lastName": "Doe", 
  "email": "john@example.com",
  "password": "securepassword"
}

// Login user
POST /api/auth/login
{
  "email": "john@example.com",
  "password": "securepassword"
}

// Response includes JWT token for future requests
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": { ... }
}
```

### 3. Socket.IO Integration
```dart
// Connect to real-time services
import 'package:socket_io_client/socket_io_client.dart';

Socket socket = io('http://localhost:3000', <String, dynamic>{
  'transports': ['websocket'],
  'extraHeaders': {'authorization': 'Bearer $token'}
});

// Join therapy session
socket.emit('join_session', sessionId);

// Listen for real-time events
socket.on('chat_message', (data) {
  // Handle incoming chat message
});
```

### 4. File Upload Integration
```dart
// Upload profile picture or journal media
POST /api/users/profile/avatar
Content-Type: multipart/form-data

// Exercise media, journal attachments, etc.
```

### 5. Push Notification Setup
```dart
// Send device token to backend
POST /api/users/devices
{
  "deviceId": "device_unique_id",
  "platform": "android", // or "ios"
  "pushToken": "firebase_token"
}
```

## 📱 Flutter Integration Examples

### HTTP Service Setup
```dart
class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static String? authToken;
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };
  
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    return json.decode(response.body);
  }
  
  // Add GET, PUT, DELETE methods...
}
```

### Authentication Service
```dart
class AuthService {
  static Future<bool> register(String firstName, String lastName, String email, String password) async {
    final response = await ApiService.post('/auth/register', {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
    });
    
    if (response['success']) {
      ApiService.authToken = response['token'];
      return true;
    }
    return false;
  }
  
  static Future<bool> login(String email, String password) async {
    final response = await ApiService.post('/auth/login', {
      'email': email,
      'password': password,
    });
    
    if (response['success']) {
      ApiService.authToken = response['token'];
      return true;
    }
    return false;
  }
}
```

### Questionnaire Service
```dart
class QuestionnaireService {
  static Future<List<dynamic>> getQuestionnaires() async {
    final response = await ApiService.get('/questionnaires');
    return response['questionnaires'];
  }
  
  static Future<String> startQuestionnaire(String questionnaireId) async {
    final response = await ApiService.post('/questionnaires/$questionnaireId/start', {});
    return response['responseId'];
  }
  
  static Future<Map<String, dynamic>> submitAnswer(String questionnaireId, String responseId, String questionId, dynamic answer) async {
    final response = await ApiService.post('/questionnaires/$questionnaireId/answer', {
      'responseId': responseId,
      'questionId': questionId,
      'answer': answer,
    });
    return response;
  }
}
```

## 🛠️ Setup Instructions for Production

### 1. Environment Configuration
- Set up MongoDB database (Atlas or self-hosted)
- Configure email service (Gmail, SendGrid, etc.)
- Set up Firebase project for push notifications
- Configure Cloudinary for file storage
- Set up social login providers

### 2. Security Configuration
- Generate secure JWT secrets
- Configure CORS for your Flutter app domain
- Set up SSL/HTTPS certificates
- Configure rate limiting for production
- Set up monitoring and logging

### 3. Deployment Options
- **Heroku**: Easy deployment with MongoDB Atlas
- **AWS**: EC2 + RDS/DocumentDB
- **Digital Ocean**: Droplets with managed databases
- **Google Cloud**: App Engine + Cloud Firestore
- **Docker**: Containerized deployment

### 4. Database Seeding
```bash
# Create sample data for testing
npm run seed
```

### 5. Monitoring and Analytics
- Set up error monitoring (Sentry)
- Configure performance monitoring
- Set up database monitoring
- Implement API analytics

## 📋 API Documentation

### Authentication Endpoints
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user
- `POST /api/auth/logout` - User logout
- `POST /api/auth/forgotpassword` - Password reset
- `PUT /api/auth/resetpassword/:token` - Reset password

### User Management
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update profile
- `PUT /api/users/settings` - Update settings
- `GET /api/users/dashboard` - Dashboard data

### AI Module
- `GET /api/ai/module` - Get AI module data
- `POST /api/ai/concept-maps` - Create concept map
- `GET /api/ai/recommendations` - Get recommendations
- `POST /api/ai/recommendations/generate` - Generate new recommendations

### Questionnaires
- `GET /api/questionnaires` - List questionnaires
- `POST /api/questionnaires/:id/start` - Start questionnaire
- `POST /api/questionnaires/:id/answer` - Submit answer
- `GET /api/questionnaires/responses/my` - User responses

### Therapy Sessions
- `GET /api/therapy/sessions` - List sessions
- `POST /api/therapy/sessions` - Create session
- `POST /api/therapy/sessions/:id/start` - Start session
- `POST /api/therapy/sessions/:id/join` - Join session

### Exercises
- `GET /api/exercises` - List exercises
- `GET /api/exercises/daily` - Daily recommendations
- `POST /api/exercises/:id/complete` - Record completion

## 🎯 Next Steps

1. **Set up MongoDB**: Install locally or use MongoDB Atlas
2. **Configure Services**: Set up email, Firebase, Cloudinary accounts
3. **Test API**: Use Postman to test endpoints
4. **Integrate with Flutter**: Implement API calls in your Flutter app
5. **Deploy**: Choose hosting platform and deploy backend

## 🔗 Resources

- **MongoDB Atlas**: https://www.mongodb.com/cloud/atlas
- **Firebase Console**: https://console.firebase.google.com/
- **Cloudinary**: https://cloudinary.com/
- **Postman API Testing**: https://www.postman.com/
- **Socket.IO Flutter**: https://pub.dev/packages/socket_io_client

Your Hearth Track backend is now complete and ready for integration with your Flutter frontend! The system provides a robust foundation for a comprehensive health and wellness application.
