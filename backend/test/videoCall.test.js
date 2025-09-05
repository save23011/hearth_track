const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../server');
const User = require('../models/User');
const CallSession = require('../models/CallSession');
const jwt = require('jsonwebtoken');

describe('Video Call API', () => {
  let authToken;
  let userId;
  let testUser;

  beforeAll(async () => {
    // Create test user
    testUser = new User({
      firstName: 'Test',
      lastName: 'User',
      email: 'test@example.com',
      password: 'password123',
      isVerified: true
    });
    await testUser.save();
    userId = testUser._id;

    // Generate auth token
    authToken = jwt.sign(
      { id: userId },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );
  });

  afterAll(async () => {
    // Clean up test data
    await User.deleteMany({ email: { $regex: /test.*@example\.com/ } });
    await CallSession.deleteMany({});
    await mongoose.connection.close();
  });

  describe('POST /api/video-call/initiate', () => {
    it('should initiate a new video call session', async () => {
      const participant2 = new User({
        firstName: 'Test2',
        lastName: 'User2',
        email: 'test2@example.com',
        password: 'password123',
        isVerified: true
      });
      await participant2.save();

      const response = await request(app)
        .post('/api/video-call/initiate')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          sessionType: 'one-to-one',
          participants: [participant2._id],
          callSettings: {
            isVideoEnabled: true,
            isAudioEnabled: true,
            allowScreenShare: true
          },
          metadata: {
            title: 'Test Call',
            description: 'Test call description'
          }
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.sessionId).toBeDefined();
      expect(response.body.data.iceServers).toBeDefined();
    });

    it('should fail with invalid session type', async () => {
      const response = await request(app)
        .post('/api/video-call/initiate')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          sessionType: 'invalid-type',
          participants: [userId],
          callSettings: {}
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should fail without authentication', async () => {
      const response = await request(app)
        .post('/api/video-call/initiate')
        .send({
          sessionType: 'one-to-one',
          participants: [userId]
        });

      expect(response.status).toBe(401);
    });
  });

  describe('POST /api/video-call/join/:sessionId', () => {
    let sessionId;

    beforeEach(async () => {
      // Create a test call session
      const callSession = await CallSession.createSession({
        sessionType: 'group',
        initiatorId: userId,
        maxParticipants: 8
      });
      sessionId = callSession.sessionId;
    });

    it('should allow user to join an existing call session', async () => {
      const response = await request(app)
        .post(`/api/video-call/join/${sessionId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.sessionId).toBe(sessionId);
      expect(response.body.data.iceServers).toBeDefined();
    });

    it('should fail to join non-existent session', async () => {
      const response = await request(app)
        .post('/api/video-call/join/invalid-session-id')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/video-call/session/:sessionId', () => {
    let sessionId;

    beforeEach(async () => {
      const callSession = await CallSession.createSession({
        sessionType: 'group',
        initiatorId: userId,
        maxParticipants: 8
      });
      sessionId = callSession.sessionId;
    });

    it('should get call session details', async () => {
      const response = await request(app)
        .get(`/api/video-call/session/${sessionId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.sessionId).toBe(sessionId);
    });
  });

  describe('PUT /api/video-call/session/:sessionId/media', () => {
    let sessionId;

    beforeEach(async () => {
      const callSession = await CallSession.createSession({
        sessionType: 'group',
        initiatorId: userId,
        maxParticipants: 8
      });
      
      // Add user as participant
      await callSession.addParticipant(userId, 'socket-id', 'peer-id');
      sessionId = callSession.sessionId;
    });

    it('should update participant media settings', async () => {
      const response = await request(app)
        .put(`/api/video-call/session/${sessionId}/media`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          hasVideo: false,
          hasAudio: true,
          isScreenSharing: false
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('POST /api/video-call/session/:sessionId/end', () => {
    let sessionId;

    beforeEach(async () => {
      const callSession = await CallSession.createSession({
        sessionType: 'group',
        initiatorId: userId,
        maxParticipants: 8
      });
      sessionId = callSession.sessionId;
    });

    it('should end call session', async () => {
      const response = await request(app)
        .post(`/api/video-call/session/${sessionId}/end`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.duration).toBeDefined();
    });
  });

  describe('GET /api/video-call/history', () => {
    beforeEach(async () => {
      // Create some test call sessions
      await CallSession.createSession({
        sessionType: 'one-to-one',
        initiatorId: userId,
        status: 'ended',
        endTime: new Date()
      });

      await CallSession.createSession({
        sessionType: 'group',
        initiatorId: userId,
        status: 'ended',
        endTime: new Date()
      });
    });

    it('should get user call history', async () => {
      const response = await request(app)
        .get('/api/video-call/history')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.callSessions).toBeDefined();
      expect(Array.isArray(response.body.data.callSessions)).toBe(true);
    });

    it('should support pagination', async () => {
      const response = await request(app)
        .get('/api/video-call/history?page=1&limit=1')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.data.callSessions.length).toBeLessThanOrEqual(1);
      expect(response.body.data.totalPages).toBeDefined();
      expect(response.body.data.currentPage).toBe('1');
    });
  });
});
