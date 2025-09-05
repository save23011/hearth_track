const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  // Basic Information
  firstName: {
    type: String,
    required: true,
    trim: true,
    maxlength: 50
  },
  lastName: {
    type: String,
    required: true,
    trim: true,
    maxlength: 50
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  password: {
    type: String,
    required: function() {
      return !this.socialLogin.google.id && !this.socialLogin.facebook.id;
    },
    minlength: 6,
    select: false
  },
  phone: {
    number: {
      type: String,
      trim: true,
      match: [/^\+?[1-9]\d{1,14}$/, 'Please enter a valid phone number']
    },
    verified: {
      type: Boolean,
      default: false
    },
    verificationCode: String,
    verificationExpires: Date
  },
  
  // Profile Information
  avatar: {
    url: String,
    public_id: String
  },
  dateOfBirth: Date,
  gender: {
    type: String,
    enum: ['male', 'female', 'other', 'prefer-not-to-say']
  },
  location: {
    country: String,
    state: String,
    city: String,
    timezone: String
  },
  
  // Social Login
  socialLogin: {
    google: {
      id: String,
      email: String
    },
    facebook: {
      id: String,
      email: String
    }
  },
  
  // Account Status
  isActive: {
    type: Boolean,
    default: true
  },
  isEmailVerified: {
    type: Boolean,
    default: false
  },
  emailVerificationToken: String,
  emailVerificationExpires: Date,
  
  // Password Reset
  passwordResetToken: String,
  passwordResetExpires: Date,
  
  // Health Profile
  healthProfile: {
    conditions: [String],
    medications: [String],
    allergies: [String],
    emergencyContact: {
      name: String,
      phone: String,
      relationship: String
    }
  },
  
  // AI Module Data
  aiProfile: {
    conceptMaps: [{
      topic: String,
      nodes: [{
        id: String,
        label: String,
        x: Number,
        y: Number,
        connections: [String]
      }],
      createdAt: {
        type: Date,
        default: Date.now
      }
    }],
    preferences: {
      learningStyle: {
        type: String,
        enum: ['visual', 'auditory', 'kinesthetic', 'reading']
      },
      difficulty: {
        type: String,
        enum: ['beginner', 'intermediate', 'advanced']
      },
      topics: [String]
    },
    progress: {
      completedAssessments: Number,
      totalScore: Number,
      lastAssessment: Date
    }
  },
  
  // Therapy & Sessions
  therapyProfile: {
    preferredTherapist: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Therapist'
    },
    sessionHistory: [{
      sessionId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'TherapySession'
      },
      rating: Number,
      feedback: String,
      date: Date
    }],
    goals: [String],
    currentPlan: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'RemedialPlan'
    }
  },
  
  // Settings
  settings: {
    notifications: {
      push: {
        type: Boolean,
        default: true
      },
      email: {
        type: Boolean,
        default: true
      },
      sms: {
        type: Boolean,
        default: false
      },
      reminders: {
        type: Boolean,
        default: true
      },
      content: {
        type: Boolean,
        default: true
      }
    },
    privacy: {
      profileVisibility: {
        type: String,
        enum: ['public', 'friends', 'private'],
        default: 'private'
      },
      shareProgress: {
        type: Boolean,
        default: false
      },
      dataCollection: {
        type: Boolean,
        default: true
      }
    },
    language: {
      type: String,
      default: 'en'
    },
    theme: {
      type: String,
      enum: ['light', 'dark', 'auto'],
      default: 'auto'
    }
  },
  
  // Device & Push Notifications
  devices: [{
    deviceId: String,
    platform: {
      type: String,
      enum: ['ios', 'android', 'web']
    },
    pushToken: String,
    lastSeen: Date,
    isActive: {
      type: Boolean,
      default: true
    }
  }],
  
  // Subscription & Premium
  subscription: {
    plan: {
      type: String,
      enum: ['free', 'premium', 'family'],
      default: 'free'
    },
    startDate: Date,
    endDate: Date,
    autoRenew: {
      type: Boolean,
      default: false
    },
    paymentMethod: String
  },
  
  // Analytics
  analytics: {
    lastLoginAt: Date,
    loginCount: {
      type: Number,
      default: 0
    },
    appUsageTime: {
      type: Number,
      default: 0
    },
    featuresUsed: [String]
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for full name
userSchema.virtual('fullName').get(function() {
  return `${this.firstName} ${this.lastName}`;
});

// Index for better performance (removed email index as it's already unique)
userSchema.index({ 'phone.number': 1 });
userSchema.index({ 'socialLogin.google.id': 1 });
userSchema.index({ 'socialLogin.facebook.id': 1 });
userSchema.index({ createdAt: -1 });

// Encrypt password using bcrypt
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) {
    next();
  }
  
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// Match user entered password to hashed password in database
userSchema.methods.matchPassword = async function(enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

// Generate and hash password token
userSchema.methods.getResetPasswordToken = function() {
  // Generate token
  const resetToken = crypto.randomBytes(20).toString('hex');
  
  // Hash token and set to resetPasswordToken field
  this.passwordResetToken = crypto.createHash('sha256').update(resetToken).digest('hex');
  
  // Set expire
  this.passwordResetExpires = Date.now() + 10 * 60 * 1000; // 10 minutes
  
  return resetToken;
};

module.exports = mongoose.model('User', userSchema);
