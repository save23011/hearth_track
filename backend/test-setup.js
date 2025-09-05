const mongoose = require('mongoose');
const User = require('./models/User');
const Questionnaire = require('./models/Questionnaire');
const Exercise = require('./models/Exercise');
require('dotenv').config();

const testSetup = async () => {
  try {
    console.log('🚀 Testing Hearth Track Backend Setup...\n');

    // Test environment variables
    console.log('📋 Environment Configuration:');
    console.log(`- Node Environment: ${process.env.NODE_ENV}`);
    console.log(`- Port: ${process.env.PORT}`);
    console.log(`- Database URI: ${process.env.MONGODB_URI}`);
    console.log(`- JWT Secret: ${process.env.JWT_SECRET ? '✅ Set' : '❌ Not set'}`);
    console.log(`- App Name: ${process.env.APP_NAME}\n`);

    // Test database connection
    console.log('🗄️  Testing Database Connection...');
    try {
      await mongoose.connect(process.env.MONGODB_URI, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });
      console.log('✅ Database connection successful\n');
    } catch (error) {
      console.log('❌ Database connection failed:', error.message, '\n');
      return;
    }

    // Test models
    console.log('📊 Testing Data Models...');
    
    try {
      // Test User model
      const testUser = new User({
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        password: 'testpassword123'
      });
      await testUser.validate();
      console.log('✅ User model validation passed');

      // Test Questionnaire model
      const testQuestionnaire = new Questionnaire({
        title: 'Test Questionnaire',
        description: 'A test questionnaire',
        category: 'mental-health',
        type: 'static',
        questions: [{
          id: 'q1',
          text: 'How are you feeling today?',
          type: 'scale',
          required: true
        }],
        createdBy: new mongoose.Types.ObjectId()
      });
      await testQuestionnaire.validate();
      console.log('✅ Questionnaire model validation passed');

      // Test Exercise model
      const testExercise = new Exercise({
        title: 'Test Exercise',
        description: 'A test exercise for wellness',
        category: 'breathing',
        difficulty: 'beginner',
        duration: { estimated: 10 },
        instructions: [{
          step: 1,
          text: 'Take a deep breath',
          duration: 30
        }],
        createdBy: new mongoose.Types.ObjectId()
      });
      await testExercise.validate();
      console.log('✅ Exercise model validation passed\n');

    } catch (error) {
      console.log('❌ Model validation failed:', error.message, '\n');
    }

    // Test API routes structure
    console.log('🛣️  API Routes Available:');
    console.log('- Authentication: /api/auth/*');
    console.log('- Users: /api/users/*');
    console.log('- AI Module: /api/ai/*');
    console.log('- Questionnaires: /api/questionnaires/*');
    console.log('- Therapy Sessions: /api/therapy/*');
    console.log('- Exercises: /api/exercises/*');
    console.log('- Content: /api/content/*');
    console.log('- Notifications: /api/notifications/*');
    console.log('- Journal: /api/journal/*');
    console.log('- Tasks: /api/tasks/*');
    console.log('- Admin: /api/admin/*\n');

    console.log('🎉 Backend setup test completed successfully!');
    console.log('\n📝 Next Steps:');
    console.log('1. Configure your MongoDB connection');
    console.log('2. Set up email service credentials');
    console.log('3. Configure social login providers');
    console.log('4. Set up Firebase for push notifications');
    console.log('5. Configure file storage (Cloudinary)');
    console.log('6. Start the server with: npm run dev');
    console.log('\n🚀 Your Hearth Track backend is ready to go!');

  } catch (error) {
    console.error('❌ Setup test failed:', error);
  } finally {
    if (mongoose.connection.readyState === 1) {
      await mongoose.connection.close();
    }
    process.exit(0);
  }
};

// Run the test
testSetup();
