const mongoose = require('mongoose');

const questionnaireSchema = new mongoose.Schema({
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
  category: {
    type: String,
    required: true,
    enum: [
      'mental-health',
      'physical-health',
      'lifestyle',
      'goals',
      'assessment',
      'therapy',
      'ai-training'
    ]
  },
  type: {
    type: String,
    required: true,
    enum: ['dynamic', 'static', 'adaptive']
  },
  
  // Dynamic Questionnaire Configuration
  dynamicConfig: {
    enabled: {
      type: Boolean,
      default: false
    },
    triggers: [{
      condition: String, // e.g., "score < 5", "previous_answer == 'yes'"
      action: String,    // e.g., "show_question", "skip_section", "end_questionnaire"
      targetQuestionId: String
    }],
    adaptiveLogic: {
      enabled: {
        type: Boolean,
        default: false
      },
      algorithm: {
        type: String,
        enum: ['item-response-theory', 'difficulty-adjustment', 'content-branching']
      },
      parameters: mongoose.Schema.Types.Mixed
    }
  },
  
  // Questions Array
  questions: [{
    id: {
      type: String,
      required: true
    },
    text: {
      type: String,
      required: true,
      maxlength: 500
    },
    type: {
      type: String,
      required: true,
      enum: [
        'multiple-choice',
        'single-choice',
        'text',
        'number',
        'scale',
        'boolean',
        'date',
        'time',
        'file-upload',
        'voice-recording'
      ]
    },
    required: {
      type: Boolean,
      default: true
    },
    options: [{
      value: String,
      label: String,
      score: Number,
      triggers: [{
        condition: String,
        action: String,
        targetQuestionId: String
      }]
    }],
    validation: {
      min: Number,
      max: Number,
      pattern: String,
      customMessage: String
    },
    conditional: {
      dependsOn: String, // Question ID
      showWhen: String,  // Condition
      hideWhen: String   // Condition
    },
    metadata: {
      section: String,
      subsection: String,
      tags: [String],
      difficulty: {
        type: String,
        enum: ['easy', 'medium', 'hard']
      },
      estimatedTime: Number // in seconds
    }
  }],
  
  // Scoring Configuration
  scoring: {
    enabled: {
      type: Boolean,
      default: false
    },
    method: {
      type: String,
      enum: ['sum', 'average', 'weighted', 'custom']
    },
    ranges: [{
      min: Number,
      max: Number,
      label: String,
      description: String,
      recommendations: [String]
    }],
    weights: [{
      questionId: String,
      weight: Number
    }]
  },
  
  // AI Integration
  aiIntegration: {
    enabled: {
      type: Boolean,
      default: false
    },
    analysisType: {
      type: String,
      enum: ['sentiment', 'topic-modeling', 'concept-mapping', 'recommendation']
    },
    trainingData: {
      collectResponses: {
        type: Boolean,
        default: false
      },
      anonymize: {
        type: Boolean,
        default: true
      }
    },
    recommendations: {
      generateAutomatic: {
        type: Boolean,
        default: false
      },
      templates: [String]
    }
  },
  
  // Access Control
  access: {
    public: {
      type: Boolean,
      default: false
    },
    targetAudience: [{
      type: String,
      enum: ['all-users', 'premium-users', 'specific-conditions', 'age-group', 'custom']
    }],
    conditions: [{
      field: String,
      operator: String,
      value: mongoose.Schema.Types.Mixed
    }],
    permissions: {
      view: [String],
      respond: [String],
      edit: [String]
    }
  },
  
  // Scheduling
  schedule: {
    frequency: {
      type: String,
      enum: ['once', 'daily', 'weekly', 'monthly', 'custom']
    },
    startDate: Date,
    endDate: Date,
    reminderSettings: {
      enabled: {
        type: Boolean,
        default: false
      },
      beforeHours: Number,
      message: String
    }
  },
  
  // Status and Metadata
  status: {
    type: String,
    enum: ['draft', 'active', 'archived', 'disabled'],
    default: 'draft'
  },
  version: {
    type: Number,
    default: 1
  },
  previousVersions: [{
    version: Number,
    data: mongoose.Schema.Types.Mixed,
    createdAt: Date,
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }
  }],
  
  // Analytics
  analytics: {
    totalResponses: {
      type: Number,
      default: 0
    },
    completionRate: {
      type: Number,
      default: 0
    },
    averageTime: Number,
    lastResponseAt: Date,
    responseDistribution: mongoose.Schema.Types.Mixed
  },
  
  // Creation Info
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
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
questionnaireSchema.index({ category: 1, status: 1 });
questionnaireSchema.index({ 'access.public': 1, status: 1 });
questionnaireSchema.index({ createdBy: 1 });
questionnaireSchema.index({ createdAt: -1 });

// Virtual for total questions
questionnaireSchema.virtual('totalQuestions').get(function() {
  return this.questions.length;
});

// Method to check if user can access questionnaire
questionnaireSchema.methods.canUserAccess = function(user) {
  if (this.access.public) return true;
  
  // Check target audience
  for (let audience of this.access.targetAudience) {
    switch (audience) {
      case 'all-users':
        return true;
      case 'premium-users':
        return user.subscription.plan !== 'free';
      // Add more conditions as needed
    }
  }
  
  return false;
};

// Method to get next question based on dynamic logic
questionnaireSchema.methods.getNextQuestion = function(currentQuestionId, responses) {
  const currentIndex = this.questions.findIndex(q => q.id === currentQuestionId);
  if (currentIndex === -1) return this.questions[0];
  
  const currentQuestion = this.questions[currentIndex];
  const userResponse = responses[currentQuestionId];
  
  // Check for triggers in current question's options
  if (userResponse && currentQuestion.options) {
    const selectedOption = currentQuestion.options.find(opt => opt.value === userResponse);
    if (selectedOption && selectedOption.triggers) {
      for (let trigger of selectedOption.triggers) {
        if (this.evaluateCondition(trigger.condition, responses)) {
          if (trigger.action === 'show_question') {
            return this.questions.find(q => q.id === trigger.targetQuestionId);
          } else if (trigger.action === 'skip_section') {
            // Logic to skip to next section
          }
        }
      }
    }
  }
  
  // Default: return next question
  return this.questions[currentIndex + 1] || null;
};

// Method to evaluate dynamic conditions
questionnaireSchema.methods.evaluateCondition = function(condition, responses) {
  // Simple condition evaluation (can be enhanced)
  try {
    // Replace variables in condition with actual values
    let evaluableCondition = condition;
    for (let [questionId, response] of Object.entries(responses)) {
      evaluableCondition = evaluableCondition.replace(
        new RegExp(`\\b${questionId}\\b`, 'g'),
        typeof response === 'string' ? `"${response}"` : response
      );
    }
    
    // Basic evaluation (in production, use a safer evaluation method)
    return eval(evaluableCondition);
  } catch (error) {
    console.error('Error evaluating condition:', error);
    return false;
  }
};

module.exports = mongoose.model('Questionnaire', questionnaireSchema);
