const mongoose = require('mongoose');

const aiModuleSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  
  // Concept Mapping Data
  conceptMaps: [{
    id: {
      type: String,
      required: true
    },
    title: {
      type: String,
      required: true
    },
    topic: {
      type: String,
      required: true
    },
    description: String,
    
    // Graph Structure
    nodes: [{
      id: String,
      label: String,
      type: {
        type: String,
        enum: ['concept', 'skill', 'goal', 'barrier', 'resource']
      },
      position: {
        x: Number,
        y: Number
      },
      properties: {
        color: String,
        size: Number,
        weight: Number,
        confidence: Number
      },
      metadata: {
        source: String,
        createdBy: String,
        importance: Number
      }
    }],
    
    edges: [{
      id: String,
      from: String,
      to: String,
      type: {
        type: String,
        enum: ['causes', 'enables', 'requires', 'supports', 'conflicts', 'related']
      },
      strength: {
        type: Number,
        min: 0,
        max: 1
      },
      direction: {
        type: String,
        enum: ['bidirectional', 'unidirectional']
      },
      properties: {
        color: String,
        width: Number,
        style: String
      }
    }],
    
    // Analysis Results
    analysis: {
      complexity: Number,
      density: Number,
      centralNodes: [String],
      clusters: [{
        id: String,
        nodes: [String],
        theme: String
      }],
      recommendations: [String],
      gaps: [String]
    },
    
    version: {
      type: Number,
      default: 1
    },
    isActive: {
      type: Boolean,
      default: true
    },
    createdAt: {
      type: Date,
      default: Date.now
    },
    lastModified: Date
  }],
  
  // Learning Profile
  learningProfile: {
    style: {
      visual: Number,
      auditory: Number,
      kinesthetic: Number,
      reading: Number
    },
    preferences: {
      sessionDuration: Number, // minutes
      difficulty: {
        type: String,
        enum: ['beginner', 'intermediate', 'advanced'],
        default: 'beginner'
      },
      topics: [String],
      goals: [String]
    },
    cognitiveLoad: {
      current: Number,
      optimal: Number,
      factors: [String]
    }
  },
  
  // AI Recommendations
  recommendations: [{
    id: String,
    type: {
      type: String,
      enum: ['exercise', 'content', 'therapy', 'goal', 'skill-building']
    },
    title: String,
    description: String,
    priority: {
      type: String,
      enum: ['low', 'medium', 'high'],
      default: 'medium'
    },
    confidence: Number,
    reasoning: String,
    
    // Recommendation Content
    content: {
      exercises: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Exercise'
      }],
      articles: [String],
      videos: [String],
      goals: [String]
    },
    
    // Tracking
    status: {
      type: String,
      enum: ['pending', 'accepted', 'declined', 'completed'],
      default: 'pending'
    },
    feedback: {
      helpful: Boolean,
      rating: Number,
      comments: String
    },
    
    createdAt: {
      type: Date,
      default: Date.now
    },
    expiresAt: Date
  }],
  
  // Progress Tracking
  progress: {
    assessmentsCompleted: {
      type: Number,
      default: 0
    },
    conceptMapsCreated: {
      type: Number,
      default: 0
    },
    skillsAcquired: [String],
    goalsAchieved: [String],
    totalEngagementTime: {
      type: Number,
      default: 0
    },
    
    // Weekly/Monthly Progress
    weeklyProgress: [{
      week: String, // YYYY-WW format
      activeDays: Number,
      conceptMapsWorked: Number,
      recommendationsFollowed: Number,
      engagementTime: Number
    }],
    
    // Milestones
    milestones: [{
      id: String,
      title: String,
      description: String,
      achievedAt: Date,
      category: String
    }]
  },
  
  // AI Model Data
  modelData: {
    personalityProfile: {
      openness: Number,
      conscientiousness: Number,
      extraversion: Number,
      agreeableness: Number,
      neuroticism: Number
    },
    
    cognitiveProfile: {
      workingMemory: Number,
      processingSpeed: Number,
      attention: Number,
      executiveFunction: Number
    },
    
    // Behavioral Patterns
    patterns: [{
      type: String,
      description: String,
      frequency: Number,
      contexts: [String],
      triggers: [String]
    }],
    
    // Risk Assessment
    riskFactors: [{
      factor: String,
      level: {
        type: String,
        enum: ['low', 'medium', 'high']
      },
      confidence: Number,
      lastUpdated: Date
    }],
    
    // Adaptive Parameters
    adaptiveParameters: {
      difficulty: Number,
      pace: Number,
      support: Number,
      challenge: Number
    }
  },
  
  // Integration with Other Modules
  integrations: {
    questionnaires: [{
      questionnaireId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Questionnaire'
      },
      responses: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'QuestionnaireResponse'
      },
      insights: [String],
      updatedConceptMaps: [String]
    }],
    
    therapy: [{
      sessionId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'TherapySession'
      },
      insights: [String],
      recommendationsGenerated: [String]
    }],
    
    exercises: [{
      exerciseId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Exercise'
      },
      performance: Number,
      adaptations: [String]
    }]
  },
  
  // Settings
  settings: {
    autoGenerateRecommendations: {
      type: Boolean,
      default: true
    },
    shareDataForResearch: {
      type: Boolean,
      default: false
    },
    notificationPreferences: {
      newRecommendations: Boolean,
      progressUpdates: Boolean,
      conceptMapSuggestions: Boolean
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
aiModuleSchema.index({ user: 1 });
aiModuleSchema.index({ 'conceptMaps.topic': 1 });
aiModuleSchema.index({ 'recommendations.type': 1, 'recommendations.status': 1 });
aiModuleSchema.index({ createdAt: -1 });

// Virtual for active concept maps
aiModuleSchema.virtual('activeConceptMaps').get(function() {
  return this.conceptMaps.filter(map => map.isActive);
});

// Virtual for pending recommendations
aiModuleSchema.virtual('pendingRecommendations').get(function() {
  return this.recommendations.filter(rec => rec.status === 'pending');
});

// Method to add new concept map
aiModuleSchema.methods.addConceptMap = function(mapData) {
  const newMap = {
    ...mapData,
    id: new mongoose.Types.ObjectId().toString(),
    createdAt: new Date(),
    lastModified: new Date()
  };
  
  this.conceptMaps.push(newMap);
  this.progress.conceptMapsCreated += 1;
  
  return newMap.id;
};

// Method to update concept map
aiModuleSchema.methods.updateConceptMap = function(mapId, updateData) {
  const mapIndex = this.conceptMaps.findIndex(map => map.id === mapId);
  if (mapIndex !== -1) {
    Object.assign(this.conceptMaps[mapIndex], updateData);
    this.conceptMaps[mapIndex].lastModified = new Date();
    this.conceptMaps[mapIndex].version += 1;
    return true;
  }
  return false;
};

// Method to generate recommendations
aiModuleSchema.methods.generateRecommendations = async function() {
  // This would integrate with actual AI service
  // For now, return mock recommendations
  const mockRecommendations = [
    {
      id: new mongoose.Types.ObjectId().toString(),
      type: 'exercise',
      title: 'Breathing Exercise',
      description: 'Based on your stress patterns, try this breathing exercise',
      priority: 'high',
      confidence: 0.85,
      reasoning: 'High stress indicators in recent assessments'
    }
  ];
  
  this.recommendations.push(...mockRecommendations);
  return mockRecommendations;
};

// Method to update progress
aiModuleSchema.methods.updateProgress = function(type, data) {
  switch (type) {
    case 'assessment':
      this.progress.assessmentsCompleted += 1;
      break;
    case 'engagement':
      this.progress.totalEngagementTime += data.duration || 0;
      break;
    case 'milestone':
      this.progress.milestones.push({
        ...data,
        achievedAt: new Date()
      });
      break;
  }
};

module.exports = mongoose.model('AIModule', aiModuleSchema);
