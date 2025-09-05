const cron = require('node-cron');
const User = require('../models/User');
const TherapySession = require('../models/TherapySession');
const AIModule = require('../models/AIModule');

// Run every day at 9 AM to send daily exercise reminders
cron.schedule('0 9 * * *', async () => {
  console.log('Running daily exercise reminder job...');
  
  try {
    const users = await User.find({
      isActive: true,
      'settings.notifications.reminders': true
    });

    for (const user of users) {
      // TODO: Send push notification for daily exercises
      console.log(`Sending daily exercise reminder to ${user.email}`);
    }
  } catch (error) {
    console.error('Error in daily exercise reminder job:', error);
  }
});

// Run every hour to check for upcoming therapy sessions
cron.schedule('0 * * * *', async () => {
  console.log('Checking for upcoming therapy sessions...');
  
  try {
    const now = new Date();
    const oneHourLater = new Date(now.getTime() + 60 * 60 * 1000);
    
    const upcomingSessions = await TherapySession.find({
      scheduledFor: {
        $gte: now,
        $lte: oneHourLater
      },
      status: 'scheduled'
    }).populate('user therapist');

    for (const session of upcomingSessions) {
      // TODO: Send reminder notifications to participants
      console.log(`Upcoming session reminder: ${session.title} at ${session.scheduledFor}`);
    }
  } catch (error) {
    console.error('Error in upcoming sessions check:', error);
  }
});

// Run daily at midnight to generate AI recommendations
cron.schedule('0 0 * * *', async () => {
  console.log('Generating daily AI recommendations...');
  
  try {
    const aiModules = await AIModule.find({
      'settings.autoGenerateRecommendations': true
    }).populate('user');

    for (const aiModule of aiModules) {
      if (aiModule.user.isActive) {
        await aiModule.generateRecommendations();
        await aiModule.save();
        console.log(`Generated recommendations for user ${aiModule.user.email}`);
      }
    }
  } catch (error) {
    console.error('Error in AI recommendation generation:', error);
  }
});

// Run weekly on Sundays at 10 AM to generate progress reports
cron.schedule('0 10 * * 0', async () => {
  console.log('Generating weekly progress reports...');
  
  try {
    const users = await User.find({
      isActive: true,
      'settings.notifications.content': true
    });

    for (const user of users) {
      // TODO: Generate and send weekly progress report
      console.log(`Generating weekly progress report for ${user.email}`);
    }
  } catch (error) {
    console.error('Error in weekly progress report generation:', error);
  }
});

// Run every 15 minutes to clean up expired sessions and tokens
cron.schedule('*/15 * * * *', async () => {
  console.log('Cleaning up expired data...');
  
  try {
    // Clean up expired password reset tokens
    await User.updateMany(
      { passwordResetExpires: { $lt: new Date() } },
      {
        $unset: {
          passwordResetToken: 1,
          passwordResetExpires: 1
        }
      }
    );

    // Clean up expired email verification tokens
    await User.updateMany(
      { emailVerificationExpires: { $lt: new Date() } },
      {
        $unset: {
          emailVerificationToken: 1,
          emailVerificationExpires: 1
        }
      }
    );

    // Clean up expired phone verification codes
    await User.updateMany(
      { 'phone.verificationExpires': { $lt: new Date() } },
      {
        $unset: {
          'phone.verificationCode': 1,
          'phone.verificationExpires': 1
        }
      }
    );

    console.log('Expired data cleanup completed');
  } catch (error) {
    console.error('Error in data cleanup job:', error);
  }
});

// Run monthly on the 1st at 2 AM to archive old data
cron.schedule('0 2 1 * *', async () => {
  console.log('Archiving old data...');
  
  try {
    const oneYearAgo = new Date();
    oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);

    // Archive old therapy sessions
    const oldSessions = await TherapySession.updateMany(
      {
        createdAt: { $lt: oneYearAgo },
        status: 'completed'
      },
      {
        $set: { archived: true }
      }
    );

    console.log(`Archived ${oldSessions.modifiedCount} old therapy sessions`);
  } catch (error) {
    console.error('Error in data archiving job:', error);
  }
});

console.log('Scheduled jobs initialized');
