const mongoose = require('mongoose');

const participantSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  socketId: {
    type: String,
    required: true
  },
  peerId: String,
  joinedAt: {
    type: Date,
    default: Date.now
  },
  leftAt: Date,
  isActive: {
    type: Boolean,
    default: true
  },
  hasVideo: {
    type: Boolean,
    default: true
  },
  hasAudio: {
    type: Boolean,
    default: true
  },
  isScreenSharing: {
    type: Boolean,
    default: false
  }
});

const callSessionSchema = new mongoose.Schema({
  sessionId: {
    type: String,
    required: true,
    unique: true
  },
  sessionType: {
    type: String,
    enum: ['one-to-one', 'group', 'therapy'],
    required: true
  },
  initiatorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  participants: [participantSchema],
  maxParticipants: {
    type: Number,
    default: 8
  },
  status: {
    type: String,
    enum: ['waiting', 'active', 'ended'],
    default: 'waiting'
  },
  startTime: Date,
  endTime: Date,
  duration: {
    type: Number, // in seconds
    default: 0
  },
  callSettings: {
    isVideoEnabled: {
      type: Boolean,
      default: true
    },
    isAudioEnabled: {
      type: Boolean,
      default: true
    },
    isRecordingEnabled: {
      type: Boolean,
      default: false
    },
    allowScreenShare: {
      type: Boolean,
      default: true
    }
  },
  therapySessionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'TherapySession',
    required: false
  },
  metadata: {
    title: String,
    description: String,
    tags: [String]
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for active participants count
callSessionSchema.virtual('activeParticipantsCount').get(function() {
  return this.participants.filter(p => p.isActive).length;
});

// Virtual for call duration in minutes
callSessionSchema.virtual('durationInMinutes').get(function() {
  return Math.round(this.duration / 60);
});

// Methods
callSessionSchema.methods.addParticipant = function(userId, socketId, peerId) {
  const existingParticipant = this.participants.find(p => 
    p.userId.toString() === userId.toString() && p.isActive
  );
  
  if (existingParticipant) {
    // Update existing participant
    existingParticipant.socketId = socketId;
    existingParticipant.peerId = peerId;
    existingParticipant.joinedAt = new Date();
    existingParticipant.isActive = true;
  } else {
    // Add new participant
    this.participants.push({
      userId,
      socketId,
      peerId,
      joinedAt: new Date(),
      isActive: true
    });
  }
  
  return this.save();
};

callSessionSchema.methods.removeParticipant = function(userId, socketId) {
  const participant = this.participants.find(p => 
    (p.userId.toString() === userId.toString() || p.socketId === socketId) && p.isActive
  );
  
  if (participant) {
    participant.isActive = false;
    participant.leftAt = new Date();
  }
  
  // End session if no active participants
  if (this.activeParticipantsCount === 0) {
    this.status = 'ended';
    this.endTime = new Date();
    this.duration = Math.floor((this.endTime - this.startTime) / 1000);
  }
  
  return this.save();
};

callSessionSchema.methods.updateParticipantMedia = function(userId, mediaSettings) {
  const participant = this.participants.find(p => 
    p.userId.toString() === userId.toString() && p.isActive
  );
  
  if (participant) {
    if (mediaSettings.hasVideo !== undefined) {
      participant.hasVideo = mediaSettings.hasVideo;
    }
    if (mediaSettings.hasAudio !== undefined) {
      participant.hasAudio = mediaSettings.hasAudio;
    }
    if (mediaSettings.isScreenSharing !== undefined) {
      participant.isScreenSharing = mediaSettings.isScreenSharing;
    }
  }
  
  return this.save();
};

// Static methods
callSessionSchema.statics.createSession = function(sessionData) {
  const sessionId = `call_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  
  return this.create({
    sessionId,
    ...sessionData,
    startTime: new Date(),
    status: 'waiting'
  });
};

callSessionSchema.statics.findActiveSession = function(sessionId) {
  return this.findOne({ 
    sessionId, 
    status: { $in: ['waiting', 'active'] } 
  }).populate('participants.userId', 'firstName lastName profilePicture');
};

// Indexes
callSessionSchema.index({ sessionId: 1 });
callSessionSchema.index({ initiatorId: 1 });
callSessionSchema.index({ status: 1 });
callSessionSchema.index({ createdAt: -1 });
callSessionSchema.index({ 'participants.userId': 1 });

module.exports = mongoose.model('CallSession', callSessionSchema);
