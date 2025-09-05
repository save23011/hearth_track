const mongoose = require('mongoose');

const questionnaireResponseSchema = new mongoose.Schema({
  questionnaire: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Questionnaire',
    required: true
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  
  // Response Data
  responses: {
    type: Map,
    of: mongoose.Schema.Types.Mixed
  },
  
  // Completion Status
  status: {
    type: String,
    enum: ['in-progress', 'completed', 'abandoned'],
    default: 'in-progress'
  },
  startedAt: {
    type: Date,
    default: Date.now
  },
  completedAt: Date,
  
  // Progress Tracking
  progress: {
    currentQuestionId: String,
    questionsAnswered: {
      type: Number,
      default: 0
    },
    totalQuestions: Number,
    percentComplete: {
      type: Number,
      default: 0
    }
  },
  
  // Scoring Results
  scoring: {
    totalScore: Number,
    subscores: [{
      category: String,
      score: Number,
      maxScore: Number
    }],
    interpretation: {
      level: String,
      description: String,
      recommendations: [String]
    }
  },
  
  // AI Analysis Results
  aiAnalysis: {
    sentiment: {
      overall: String,
      confidence: Number,
      breakdown: [{
        questionId: String,
        sentiment: String,
        confidence: Number
      }]
    },
    insights: [String],
    recommendations: [String],
    riskFactors: [String],
    conceptMap: {
      nodes: [{
        id: String,
        label: String,
        weight: Number
      }],
      connections: [{
        from: String,
        to: String,
        strength: Number
      }]
    }
  },
  
  // Metadata
  metadata: {
    deviceInfo: {
      platform: String,
      version: String,
      userAgent: String
    },
    sessionInfo: {
      duration: Number, // in seconds
      interruptions: Number,
      browserTabs: Number
    },
    location: {
      country: String,
      timezone: String
    }
  },
  
  // Follow-up Actions
  followUp: {
    recommendedActions: [String],
    nextQuestionnaire: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Questionnaire'
    },
    scheduledReminders: [{
      type: String,
      scheduledFor: Date,
      sent: {
        type: Boolean,
        default: false
      }
    }],
    therapistNotification: {
      sent: {
        type: Boolean,
        default: false
      },
      sentAt: Date,
      priority: {
        type: String,
        enum: ['low', 'medium', 'high', 'urgent']
      }
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
questionnaireResponseSchema.index({ user: 1, questionnaire: 1 });
questionnaireResponseSchema.index({ user: 1, createdAt: -1 });
questionnaireResponseSchema.index({ questionnaire: 1, status: 1 });
questionnaireResponseSchema.index({ completedAt: -1 });

// Virtual for response time
questionnaireResponseSchema.virtual('responseTime').get(function() {
  if (this.completedAt && this.startedAt) {
    return Math.round((this.completedAt - this.startedAt) / 1000); // in seconds
  }
  return null;
});

// Method to calculate progress
questionnaireResponseSchema.methods.updateProgress = function(totalQuestions) {
  this.progress.questionsAnswered = this.responses.size;
  this.progress.totalQuestions = totalQuestions;
  this.progress.percentComplete = Math.round((this.responses.size / totalQuestions) * 100);
};

// Method to mark as completed
questionnaireResponseSchema.methods.markCompleted = function() {
  this.status = 'completed';
  this.completedAt = new Date();
  this.progress.percentComplete = 100;
};

module.exports = mongoose.model('QuestionnaireResponse', questionnaireResponseSchema);
