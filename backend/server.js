const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { createServer } = require('http');
const { Server } = require('socket.io');
require('dotenv').config();

// Import routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');
const aiRoutes = require('./routes/ai');
const questionnaireRoutes = require('./routes/questionnaire');
const therapyRoutes = require('./routes/therapy');
const exerciseRoutes = require('./routes/exercise');
const contentRoutes = require('./routes/content');
const notificationRoutes = require('./routes/notification');
const journalRoutes = require('./routes/journal');
const taskRoutes = require('./routes/task');
const adminRoutes = require('./routes/admin');
const videoCallRoutes = require('./routes/videoCall');

// Import middleware
const errorHandler = require('./middleware/errorHandler');
const { auth: authMiddleware } = require('./middleware/auth');

// Import socket handlers
const socketHandlers = require('./sockets/socketHandlers');

// Import scheduled jobs
require('./jobs/scheduledJobs');

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.FRONTEND_URL || "http://localhost:3001",
    methods: ["GET", "POST"]
  }
});

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});

// Middleware
app.use(helmet());
app.use(compression());
app.use(morgan('combined'));
app.use(limiter);
app.use(cors({
  origin: process.env.FRONTEND_URL || "http://localhost:3001",
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Make io accessible to routes
app.use((req, res, next) => {
  req.io = io;
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'Hearth Track API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', authMiddleware, userRoutes);
app.use('/api/ai', authMiddleware, aiRoutes);
app.use('/api/questionnaires', authMiddleware, questionnaireRoutes);
app.use('/api/therapy', authMiddleware, therapyRoutes);
app.use('/api/exercises', authMiddleware, exerciseRoutes);
app.use('/api/content', authMiddleware, contentRoutes);
app.use('/api/notifications', authMiddleware, notificationRoutes);
app.use('/api/journal', authMiddleware, journalRoutes);
app.use('/api/tasks', authMiddleware, taskRoutes);
app.use('/api/admin', authMiddleware, adminRoutes);
app.use('/api/video-call', authMiddleware, videoCallRoutes);

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  socketHandlers(socket, io);
});

// Error handling middleware
app.use(errorHandler);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint not found'
  });
});

// Database connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/hearth_track', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => {
  console.log('Connected to MongoDB');
})
.catch((error) => {
  console.error('MongoDB connection error:', error);
  process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err, promise) => {
  console.log(`Error: ${err.message}`);
  server.close(() => {
    process.exit(1);
  });
});

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`Hearth Track API server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
});

module.exports = app;
