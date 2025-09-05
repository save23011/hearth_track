const mongoose = require('mongoose');

const exerciseSchema = new mongoose.Schema({
  // Basic Information
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 200
  },
  description: {
    type: String,
    required: true,
    trim: true,
    maxlength: 2000
  },
  shortDescription: {
    type: String,
    trim: true,
    maxlength: 500
  },
  
  // Categorization
  category: {
    type: String,
    required: true,
    enum: [
      'breathing',
      'meditation',
      'mindfulness',
      'physical',
      'cognitive',
      'relaxation',
      'grounding',
      'visualization',
      'journaling',
      'movement'
    ]
  },
  subcategory: String,
  tags: [String],
  
  // Difficulty and Duration
  difficulty: {
    type: String,
    enum: ['beginner', 'intermediate', 'advanced'],
    required: true
  },
  duration: {
    estimated: {
      type: Number, // in minutes
      required: true
    },
    minimum: Number,
    maximum: Number,
    flexible: {
      type: Boolean,
      default: false
    }
  },
  
  // Target Audience
  targetConditions: [{
    condition: String,
    effectiveness: {
      type: Number,
      min: 1,
      max: 5
    }
  }],
  ageGroup: {
    min: Number,
    max: Number
  },
  
  // Content
  instructions: [{
    step: {
      type: Number,
      required: true
    },
    text: {
      type: String,
      required: true
    },
    duration: Number, // duration of this step in seconds
    audio: {
      url: String,
      transcript: String
    },
    visual: {
      type: String,
      enum: ['image', 'animation', 'video'],
      url: String,
      description: String
    }
  }],
  
  // Media Assets
  media: {
    thumbnail: {
      url: String,
      public_id: String
    },
    backgroundMusic: {
      url: String,
      volume: {
        type: Number,
        default: 0.3
      },
      loop: {
        type: Boolean,
        default: true
      }
    },
    guidedAudio: {
      url: String,
      transcript: String,
      narrator: String
    },
    video: {
      url: String,
      thumbnail: String,
      duration: Number
    },
    images: [{
      url: String,
      caption: String,
      order: Number
    }]
  },
  
  // Exercise Configuration
  settings: {
    customizable: {
      type: Boolean,
      default: false
    },
    parameters: [{
      name: String,
      type: {
        type: String,
        enum: ['number', 'duration', 'text', 'boolean', 'select']
      },
      defaultValue: mongoose.Schema.Types.Mixed,
      options: [String], // for select type
      min: Number,
      max: Number
    }],
    variations: [{
      name: String,
      description: String,
      modifications: [String]
    }]
  },
  
  // AI Integration
  aiFeatures: {
    adaptiveDifficulty: {
      type: Boolean,
      default: false
    },
    personalizedInstructions: {
      type: Boolean,
      default: false
    },
    realTimeFeedback: {
      type: Boolean,
      default: false
    },
    progressTracking: {
      type: Boolean,
      default: true
    }
  },
  
  // Effectiveness Tracking
  outcomes: {
    primaryBenefits: [String],
    secondaryBenefits: [String],
    measurableOutcomes: [{
      metric: String,
      expectedChange: String,
      timeframe: String
    }]
  },
  
  // Usage Analytics
  analytics: {
    totalCompletions: {
      type: Number,
      default: 0
    },
    averageRating: {
      type: Number,
      default: 0
    },
    totalRatings: {
      type: Number,
      default: 0
    },
    averageCompletionTime: Number,
    completionRate: {
      type: Number,
      default: 0
    },
    popularityScore: {
      type: Number,
      default: 0
    }
  },
  
  // Status and Publishing
  status: {
    type: String,
    enum: ['draft', 'review', 'published', 'archived'],
    default: 'draft'
  },
  publishedAt: Date,
  
  // Accessibility
  accessibility: {
    audioDescription: String,
    closedCaptions: {
      available: {
        type: Boolean,
        default: false
      },
      languages: [String]
    },
    visuallyImpaired: {
      supported: {
        type: Boolean,
        default: false
      },
      alternativeText: String
    },
    mobilityLimited: {
      supported: {
        type: Boolean,
        default: false
      },
      modifications: [String]
    }
  },
  
  // Licensing and Attribution
  license: {
    type: {
      type: String,
      enum: ['proprietary', 'creative-commons', 'public-domain']
    },
    attribution: String,
    restrictions: [String]
  },
  
  // Creation Info
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  reviewedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  lastModifiedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
exerciseSchema.index({ category: 1, difficulty: 1, status: 1 });
exerciseSchema.index({ tags: 1, status: 1 });
exerciseSchema.index({ 'analytics.popularityScore': -1, status: 1 });
exerciseSchema.index({ 'duration.estimated': 1, difficulty: 1 });
exerciseSchema.index({ createdAt: -1 });

// Virtual for total instruction time
exerciseSchema.virtual('totalInstructionTime').get(function() {
  return this.instructions.reduce((total, instruction) => {
    return total + (instruction.duration || 0);
  }, 0);
});

// Method to calculate popularity score
exerciseSchema.methods.calculatePopularityScore = function() {
  const completionWeight = 0.4;
  const ratingWeight = 0.4;
  const recencyWeight = 0.2;
  
  const completionScore = Math.min(this.analytics.totalCompletions / 100, 1);
  const ratingScore = this.analytics.averageRating / 5;
  const recencyScore = Math.max(0, 1 - ((Date.now() - this.createdAt) / (365 * 24 * 60 * 60 * 1000)));
  
  this.analytics.popularityScore = (
    completionScore * completionWeight +
    ratingScore * ratingWeight +
    recencyScore * recencyWeight
  ) * 100;
  
  return this.analytics.popularityScore;
};

// Method to update analytics
exerciseSchema.methods.updateAnalytics = function(rating = null, completionTime = null, completed = true) {
  if (completed) {
    this.analytics.totalCompletions += 1;
  }
  
  if (rating !== null) {
    const totalRatingPoints = this.analytics.averageRating * this.analytics.totalRatings;
    this.analytics.totalRatings += 1;
    this.analytics.averageRating = (totalRatingPoints + rating) / this.analytics.totalRatings;
  }
  
  if (completionTime !== null) {
    if (this.analytics.averageCompletionTime) {
      this.analytics.averageCompletionTime = (
        (this.analytics.averageCompletionTime + completionTime) / 2
      );
    } else {
      this.analytics.averageCompletionTime = completionTime;
    }
  }
  
  // Recalculate popularity score
  this.calculatePopularityScore();
  
  return this.save();
};

// Static method to get recommended exercises for user
exerciseSchema.statics.getRecommendedForUser = function(userProfile, limit = 10) {
  const conditions = userProfile.healthProfile?.conditions || [];
  const difficulty = userProfile.aiProfile?.preferences?.difficulty || 'beginner';
  
  return this.find({
    status: 'published',
    difficulty: { $lte: difficulty },
    $or: [
      { 'targetConditions.condition': { $in: conditions } },
      { tags: { $in: conditions } }
    ]
  })
  .sort({ 'analytics.popularityScore': -1 })
  .limit(limit);
};

module.exports = mongoose.model('Exercise', exerciseSchema);
