const mongoose = require('mongoose');

const therapySessionSchema = new mongoose.Schema({
  // Basic Information
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 200
  },
  description: {
    type: String,
    trim: true,
    maxlength: 1000
  },
  type: {
    type: String,
    required: true,
    enum: ['individual', 'group', 'ai-guided', 'self-paced']
  },
  
  // Participants
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  therapist: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  participants: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    role: {
      type: String,
      enum: ['participant', 'observer', 'co-therapist']
    }
  }],
  
  // Scheduling
  scheduledFor: Date,
  duration: {
    type: Number, // in minutes
    default: 60
  },
  timezone: String,
  
  // Session Content
  sessionPlan: {
    objectives: [String],
    activities: [{
      name: String,
      description: String,
      duration: Number,
      materials: [String]
    }],
    homework: [String],
    notes: String
  },
  
  // Media Content
  media: {
    video: {
      enabled: {
        type: Boolean,
        default: true
      },
      recordingEnabled: {
        type: Boolean,
        default: false
      },
      url: String,
      recordingUrl: String,
      quality: {
        type: String,
        enum: ['low', 'medium', 'high'],
        default: 'medium'
      }
    },
    audio: {
      enabled: {
        type: Boolean,
        default: true
      },
      recordingEnabled: {
        type: Boolean,
        default: false
      },
      url: String,
      recordingUrl: String
    },
    chat: {
      enabled: {
        type: Boolean,
        default: true
      },
      messages: [{
        sender: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'User'
        },
        message: String,
        timestamp: {
          type: Date,
          default: Date.now
        },
        type: {
          type: String,
          enum: ['text', 'file', 'emoji'],
          default: 'text'
        }
      }]
    },
    screenShare: {
      enabled: {
        type: Boolean,
        default: false
      },
      activeSharer: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      }
    }
  },
  
  // Session Status
  status: {
    type: String,
    enum: ['scheduled', 'in-progress', 'completed', 'cancelled', 'no-show'],
    default: 'scheduled'
  },
  joinLink: String,
  sessionId: String, // for video platform integration
  
  // Session Data
  actualStartTime: Date,
  actualEndTime: Date,
  actualDuration: Number,
  
  // Outcomes and Notes
  sessionNotes: {
    therapistNotes: String,
    userReflections: String,
    keyInsights: [String],
    breakthroughs: [String],
    challenges: [String]
  },
  
  // Assessments
  preSessionAssessment: {
    mood: {
      type: Number,
      min: 1,
      max: 10
    },
    anxiety: {
      type: Number,
      min: 1,
      max: 10
    },
    motivation: {
      type: Number,
      min: 1,
      max: 10
    },
    goals: [String]
  },
  
  postSessionAssessment: {
    mood: {
      type: Number,
      min: 1,
      max: 10
    },
    anxiety: {
      type: Number,
      min: 1,
      max: 10
    },
    satisfaction: {
      type: Number,
      min: 1,
      max: 10
    },
    helpfulness: {
      type: Number,
      min: 1,
      max: 10
    },
    feedback: String,
    goalsProgress: [String]
  },
  
  // Follow-up
  followUp: {
    nextSessionScheduled: Date,
    homework: [{
      task: String,
      dueDate: Date,
      completed: {
        type: Boolean,
        default: false
      },
      notes: String
    }],
    resources: [{
      type: {
        type: String,
        enum: ['article', 'video', 'exercise', 'app', 'book']
      },
      title: String,
      url: String,
      description: String
    }],
    checkInReminder: {
      enabled: {
        type: Boolean,
        default: false
      },
      scheduledFor: Date,
      message: String
    }
  },
  
  // AI Analysis
  aiAnalysis: {
    sentimentAnalysis: {
      overall: String,
      throughout: [{
        timestamp: Number,
        sentiment: String,
        confidence: Number
      }]
    },
    keyTopics: [String],
    emotionalPatterns: [String],
    recommendations: [String],
    riskFlags: [String]
  },
  
  // Technical Details
  technical: {
    platform: {
      type: String,
      enum: ['webrtc', 'zoom', 'teams', 'custom']
    },
    quality: {
      video: String,
      audio: String,
      connection: String
    },
    issues: [String],
    deviceInfo: [{
      user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      device: String,
      browser: String,
      connection: String
    }]
  },
  
  // Privacy and Compliance
  privacy: {
    recordingConsent: [{
      user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      consented: Boolean,
      timestamp: Date
    }],
    dataRetention: {
      deleteAfter: Number, // days
      autoDelete: {
        type: Boolean,
        default: true
      }
    },
    accessLevel: {
      type: String,
      enum: ['private', 'therapist-only', 'care-team'],
      default: 'private'
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
therapySessionSchema.index({ user: 1, scheduledFor: -1 });
therapySessionSchema.index({ therapist: 1, scheduledFor: -1 });
therapySessionSchema.index({ status: 1, scheduledFor: 1 });
therapySessionSchema.index({ 'sessionId': 1 });

// Virtual for session duration in minutes
therapySessionSchema.virtual('sessionDuration').get(function() {
  if (this.actualStartTime && this.actualEndTime) {
    return Math.round((this.actualEndTime - this.actualStartTime) / (1000 * 60));
  }
  return this.duration;
});

// Method to start session
therapySessionSchema.methods.startSession = function() {
  this.status = 'in-progress';
  this.actualStartTime = new Date();
  return this.save();
};

// Method to end session
therapySessionSchema.methods.endSession = function() {
  this.status = 'completed';
  this.actualEndTime = new Date();
  this.actualDuration = this.sessionDuration;
  return this.save();
};

// Method to add chat message
therapySessionSchema.methods.addChatMessage = function(senderId, message, type = 'text') {
  this.media.chat.messages.push({
    sender: senderId,
    message: message,
    type: type,
    timestamp: new Date()
  });
  return this.save();
};

module.exports = mongoose.model('TherapySession', therapySessionSchema);
