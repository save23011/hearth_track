const admin = require('firebase-admin');

class PushNotificationService {
  constructor() {
    this.initialized = false;
    this.init();
  }

  init() {
    try {
      if (process.env.FIREBASE_ADMIN_SDK_KEY_PATH) {
        const serviceAccount = require(process.env.FIREBASE_ADMIN_SDK_KEY_PATH);
        
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount)
        });
        
        this.initialized = true;
        console.log('Firebase Admin SDK initialized');
      } else {
        console.warn('Firebase Admin SDK not configured - push notifications disabled');
      }
    } catch (error) {
      console.error('Failed to initialize Firebase Admin SDK:', error);
    }
  }

  async sendToDevice(token, payload) {
    if (!this.initialized) {
      console.warn('Push notification service not initialized');
      return null;
    }

    try {
      const message = {
        token,
        notification: {
          title: payload.title,
          body: payload.body,
          icon: payload.icon || '/icons/icon-192x192.png'
        },
        data: payload.data || {},
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: payload.badge || 1
            }
          }
        }
      };

      const response = await admin.messaging().send(message);
      console.log('Push notification sent successfully:', response);
      return response;
    } catch (error) {
      console.error('Failed to send push notification:', error);
      throw error;
    }
  }

  async sendToMultipleDevices(tokens, payload) {
    if (!this.initialized) {
      console.warn('Push notification service not initialized');
      return null;
    }

    try {
      const message = {
        tokens,
        notification: {
          title: payload.title,
          body: payload.body,
          icon: payload.icon || '/icons/icon-192x192.png'
        },
        data: payload.data || {},
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: payload.badge || 1
            }
          }
        }
      };

      const response = await admin.messaging().sendMulticast(message);
      console.log(`Push notifications sent: ${response.successCount} successful, ${response.failureCount} failed`);
      
      // Handle failed tokens
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error(`Failed to send to token ${tokens[idx]}:`, resp.error);
          }
        });
      }
      
      return response;
    } catch (error) {
      console.error('Failed to send push notifications:', error);
      throw error;
    }
  }

  async sendToTopic(topic, payload) {
    if (!this.initialized) {
      console.warn('Push notification service not initialized');
      return null;
    }

    try {
      const message = {
        topic,
        notification: {
          title: payload.title,
          body: payload.body,
          icon: payload.icon || '/icons/icon-192x192.png'
        },
        data: payload.data || {},
        android: {
          priority: 'high',
          notification: {
            sound: 'default'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: payload.badge || 1
            }
          }
        }
      };

      const response = await admin.messaging().send(message);
      console.log('Topic notification sent successfully:', response);
      return response;
    } catch (error) {
      console.error('Failed to send topic notification:', error);
      throw error;
    }
  }

  async subscribeToTopic(tokens, topic) {
    if (!this.initialized) {
      console.warn('Push notification service not initialized');
      return null;
    }

    try {
      const response = await admin.messaging().subscribeToTopic(tokens, topic);
      console.log(`Subscribed ${response.successCount} devices to topic ${topic}`);
      return response;
    } catch (error) {
      console.error('Failed to subscribe to topic:', error);
      throw error;
    }
  }

  async unsubscribeFromTopic(tokens, topic) {
    if (!this.initialized) {
      console.warn('Push notification service not initialized');
      return null;
    }

    try {
      const response = await admin.messaging().unsubscribeFromTopic(tokens, topic);
      console.log(`Unsubscribed ${response.successCount} devices from topic ${topic}`);
      return response;
    } catch (error) {
      console.error('Failed to unsubscribe from topic:', error);
      throw error;
    }
  }

  // Helper methods for common notification types
  async sendSessionReminder(userTokens, session) {
    const payload = {
      title: 'Therapy Session Reminder',
      body: `Your session "${session.title}" starts in 1 hour`,
      data: {
        type: 'session_reminder',
        sessionId: session._id.toString(),
        action: 'open_session'
      },
      badge: 1
    };

    return this.sendToMultipleDevices(userTokens, payload);
  }

  async sendExerciseReminder(userTokens) {
    const payload = {
      title: 'Daily Exercise Reminder',
      body: "Don't forget to complete your daily wellness exercises!",
      data: {
        type: 'exercise_reminder',
        action: 'open_exercises'
      },
      badge: 1
    };

    return this.sendToMultipleDevices(userTokens, payload);
  }

  async sendProgressUpdate(userTokens, progressData) {
    const payload = {
      title: 'Progress Update',
      body: `Great job! You've completed ${progressData.exercisesThisWeek} exercises this week.`,
      data: {
        type: 'progress_update',
        action: 'open_dashboard'
      },
      badge: 1
    };

    return this.sendToMultipleDevices(userTokens, payload);
  }

  async sendChatMessage(userTokens, sender, message) {
    const payload = {
      title: `Message from ${sender.firstName} ${sender.lastName}`,
      body: message.length > 100 ? message.substring(0, 100) + '...' : message,
      data: {
        type: 'chat_message',
        senderId: sender._id.toString(),
        action: 'open_chat'
      },
      badge: 1
    };

    return this.sendToMultipleDevices(userTokens, payload);
  }

  async sendAIRecommendation(userTokens, recommendation) {
    const payload = {
      title: 'New AI Recommendation',
      body: recommendation.title,
      data: {
        type: 'ai_recommendation',
        recommendationId: recommendation.id,
        action: 'open_recommendations'
      },
      badge: 1
    };

    return this.sendToMultipleDevices(userTokens, payload);
  }
}

module.exports = new PushNotificationService();
