# Hearth Track Backend API

A comprehensive Node.js backend API for the Hearth Track health and wellness application, featuring AI-driven concept mapping, dynamic questionnaires, therapy sessions, exercise library, and user management.

## Features

### Core Features
- **User Registration & Authentication** - Email, phone, social login support
- **AI-driven Concept Mapping Module** - Interactive concept mapping with AI analysis
- **Dynamic Questionnaires** - Adaptive questionnaires with conditional logic
- **Custom Remedial Plan Generation** - Personalized treatment plans
- **In-app Video and Audio Therapy Sessions** - Real-time communication
- **Exercise Library** - Curated wellness exercises with recommendations
- **Content Feed** - Motivational articles, videos, and quotes
- **Admin-controlled Audio/Video Relay** - Broadcasting to users
- **Push Notifications** - Engagement and reminder notifications
- **Milestone Journal** - Text, voice, and image notes
- **Task Tracking Dashboard** - Progress monitoring
- **Settings Management** - Privacy, notifications, language preferences

### Technical Features
- RESTful API design
- Real-time communication with Socket.IO
- JWT-based authentication
- Role-based access control
- File upload support
- Email notifications
- Push notifications (Firebase)
- Scheduled jobs and cron tasks
- Comprehensive validation
- Error handling middleware
- Rate limiting
- CORS support

## Tech Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT, Passport.js
- **Real-time**: Socket.IO
- **Email**: Nodemailer
- **Push Notifications**: Firebase Admin SDK
- **File Upload**: Multer, Cloudinary
- **Validation**: express-validator
- **Security**: Helmet, bcryptjs
- **Scheduling**: node-cron

## Project Structure

```
backend/
├── config/
│   ├── database.js          # Database connection
│   └── firebase-admin-sdk.json  # Firebase service account (not included)
├── jobs/
│   └── scheduledJobs.js     # Cron jobs and scheduled tasks
├── middleware/
│   ├── auth.js              # Authentication middleware
│   ├── errorHandler.js      # Global error handling
│   └── validation.js        # Input validation
├── models/
│   ├── User.js              # User model with authentication
│   ├── AIModule.js          # AI concept mapping and recommendations
│   ├── Questionnaire.js     # Dynamic questionnaire system
│   ├── QuestionnaireResponse.js  # User responses to questionnaires
│   ├── TherapySession.js    # Video/audio therapy sessions
│   └── Exercise.js          # Exercise library
├── routes/
│   ├── auth.js              # Authentication routes
│   ├── user.js              # User management
│   ├── ai.js                # AI module endpoints
│   ├── questionnaire.js     # Questionnaire management
│   ├── therapy.js           # Therapy session management
│   ├── exercise.js          # Exercise library
│   ├── content.js           # Content management (placeholder)
│   ├── notification.js      # Notification management (placeholder)
│   ├── journal.js           # Journal functionality (placeholder)
│   ├── task.js              # Task management (placeholder)
│   └── admin.js             # Admin functionality (placeholder)
├── sockets/
│   └── socketHandlers.js    # Socket.IO event handlers
├── utils/
│   ├── emailService.js      # Email service utility
│   └── pushNotificationService.js  # Push notification utility
├── .env.example             # Environment variables template
├── .gitignore              # Git ignore rules
├── package.json            # Dependencies and scripts
└── server.js               # Main application entry point
```

## Setup Instructions

### Prerequisites
- Node.js (v16 or higher)
- MongoDB (local or cloud instance)
- NPM or Yarn package manager

### Installation

1. **Clone and Navigate**
   ```bash
   cd hearth_track/backend
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Environment Configuration**
   ```bash
   cp .env.example .env
   ```
   
   Update the `.env` file with your configuration:
   ```env
   NODE_ENV=development
   PORT=3000
   MONGODB_URI=mongodb://localhost:27017/hearth_track
   JWT_SECRET=your_super_secret_jwt_key_here
   
   # Email Configuration
   EMAIL_HOST=smtp.gmail.com
   EMAIL_PORT=587
   EMAIL_USER=your_email@gmail.com
   EMAIL_PASS=your_app_password
   
   # Social Login
   GOOGLE_CLIENT_ID=your_google_client_id
   GOOGLE_CLIENT_SECRET=your_google_client_secret
   
   # Push Notifications
   FIREBASE_ADMIN_SDK_KEY_PATH=./config/firebase-admin-sdk.json
   
   # File Storage
   CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
   CLOUDINARY_API_KEY=your_cloudinary_api_key
   CLOUDINARY_API_SECRET=your_cloudinary_api_secret
   ```

4. **Database Setup**
   - Ensure MongoDB is running
   - The application will create collections automatically

5. **Firebase Setup (Optional)**
   - Create a Firebase project
   - Download the service account key
   - Place it as `config/firebase-admin-sdk.json`

6. **Start the Server**
   
   Development mode:
   ```bash
   npm run dev
   ```
   
   Production mode:
   ```bash
   npm start
   ```

The server will start on `http://localhost:3000`

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user
- `POST /api/auth/logout` - User logout
- `POST /api/auth/forgotpassword` - Password reset request
- `PUT /api/auth/resetpassword/:token` - Reset password
- `GET /api/auth/verifyemail/:token` - Verify email
- `POST /api/auth/phone/verify` - Send phone verification
- `POST /api/auth/phone/confirm` - Confirm phone verification

### User Management
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update profile
- `PUT /api/users/settings` - Update settings
- `GET /api/users/analytics` - Get user analytics
- `GET /api/users/dashboard` - Get dashboard data

### AI Module
- `GET /api/ai/module` - Get AI module data
- `POST /api/ai/concept-maps` - Create concept map
- `PUT /api/ai/concept-maps/:id` - Update concept map
- `GET /api/ai/concept-maps` - Get concept maps
- `POST /api/ai/concept-maps/:id/analyze` - Analyze concept map
- `GET /api/ai/recommendations` - Get AI recommendations
- `POST /api/ai/recommendations/generate` - Generate recommendations

### Questionnaires
- `GET /api/questionnaires` - Get questionnaires
- `GET /api/questionnaires/:id` - Get single questionnaire
- `POST /api/questionnaires` - Create questionnaire (admin)
- `POST /api/questionnaires/:id/start` - Start questionnaire
- `POST /api/questionnaires/:id/answer` - Submit answer
- `GET /api/questionnaires/responses/my` - Get user responses

### Therapy Sessions
- `GET /api/therapy/sessions` - Get therapy sessions
- `POST /api/therapy/sessions` - Create session
- `POST /api/therapy/sessions/:id/start` - Start session
- `POST /api/therapy/sessions/:id/end` - End session
- `POST /api/therapy/sessions/:id/join` - Join session
- `POST /api/therapy/sessions/:id/chat` - Send chat message

### Exercises
- `GET /api/exercises` - Get exercises
- `GET /api/exercises/:id` - Get single exercise
- `GET /api/exercises/recommendations` - Get recommended exercises
- `GET /api/exercises/daily` - Get daily exercises
- `POST /api/exercises/:id/complete` - Record completion
- `POST /api/exercises/:id/rate` - Rate exercise

## Socket.IO Events

### Connection & Authentication
- `authenticate` - Authenticate socket connection
- `authenticated` - Authentication success
- `authentication_error` - Authentication failed

### Therapy Sessions
- `join_session` - Join therapy session room
- `leave_session` - Leave therapy session room
- `user_joined` - User joined session
- `user_left` - User left session
- `chat_message` - Real-time chat message
- `typing_start` / `typing_stop` - Typing indicators

### Video/Audio Calls
- `video_offer` - WebRTC offer
- `video_answer` - WebRTC answer
- `ice_candidate` - ICE candidate exchange
- `start_screen_share` / `stop_screen_share` - Screen sharing

### AI Concept Mapping
- `join_concept_map` - Join collaborative mapping
- `concept_map_update` - Real-time map updates

## Development

### Running Tests
```bash
npm test
```

### Code Style
The project follows standard Node.js conventions. Use ESLint for code formatting:
```bash
npm run lint
```

### Database Seeding
```bash
npm run seed
```

## Security Features

- JWT token authentication
- Password hashing with bcrypt
- Rate limiting
- CORS protection
- Helmet security headers
- Input validation and sanitization
- Role-based access control
- Secure file upload handling

## Environment Variables

See `.env.example` for all required environment variables. Key configurations include:

- Database connection strings
- JWT secrets
- Email service credentials
- Social login credentials
- Firebase configuration
- File storage credentials

## Deployment

### Production Checklist
- [ ] Set `NODE_ENV=production`
- [ ] Configure production database
- [ ] Set secure JWT secrets
- [ ] Configure email service
- [ ] Set up Firebase for push notifications
- [ ] Configure file storage
- [ ] Set up SSL/HTTPS
- [ ] Configure reverse proxy (nginx)
- [ ] Set up monitoring and logging

### Docker Support
The application can be containerized using Docker for easy deployment.

## Contributing

1. Follow the established code structure
2. Add proper error handling
3. Include input validation
4. Write comprehensive tests
5. Update documentation

## License

This project is licensed under the MIT License.

## Support

For development support or questions, refer to the project documentation or contact the development team.
