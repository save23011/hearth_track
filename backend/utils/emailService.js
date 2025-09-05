const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    this.transporter = nodemailer.createTransporter({
      host: process.env.EMAIL_HOST,
      port: process.env.EMAIL_PORT,
      secure: false, // true for 465, false for other ports
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
      }
    });
  }

  async sendEmail(options) {
    try {
      const mailOptions = {
        from: `${process.env.APP_NAME} <${process.env.EMAIL_USER}>`,
        to: options.email,
        subject: options.subject,
        html: options.html || options.message,
        text: options.text
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log('Email sent:', info.messageId);
      return info;
    } catch (error) {
      console.error('Email sending failed:', error);
      throw error;
    }
  }

  async sendWelcomeEmail(user, verificationToken) {
    const verificationUrl = `${process.env.FRONTEND_URL}/verify-email/${verificationToken}`;
    
    const html = `
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <h1 style="color: #4F46E5;">Welcome to ${process.env.APP_NAME}!</h1>
        <p>Hi ${user.firstName},</p>
        <p>Thank you for joining ${process.env.APP_NAME}. We're excited to help you on your wellness journey.</p>
        <p>To get started, please verify your email address by clicking the button below:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${verificationUrl}" 
             style="background-color: #4F46E5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
            Verify Email Address
          </a>
        </div>
        <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
        <p style="word-break: break-all; color: #6B7280;">${verificationUrl}</p>
        <p>This verification link will expire in 24 hours.</p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #E5E7EB;">
        <p style="color: #6B7280; font-size: 12px;">
          If you didn't create an account with ${process.env.APP_NAME}, please ignore this email.
        </p>
      </div>
    `;

    return this.sendEmail({
      email: user.email,
      subject: `Welcome to ${process.env.APP_NAME} - Verify Your Email`,
      html
    });
  }

  async sendPasswordResetEmail(user, resetToken) {
    const resetUrl = `${process.env.FRONTEND_URL}/reset-password/${resetToken}`;
    
    const html = `
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <h1 style="color: #4F46E5;">Password Reset Request</h1>
        <p>Hi ${user.firstName},</p>
        <p>We received a request to reset your password for your ${process.env.APP_NAME} account.</p>
        <p>Click the button below to reset your password:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${resetUrl}" 
             style="background-color: #DC2626; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
            Reset Password
          </a>
        </div>
        <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
        <p style="word-break: break-all; color: #6B7280;">${resetUrl}</p>
        <p>This password reset link will expire in 10 minutes.</p>
        <p><strong>If you didn't request a password reset, please ignore this email and your password will remain unchanged.</strong></p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #E5E7EB;">
        <p style="color: #6B7280; font-size: 12px;">
          For security reasons, this link can only be used once and will expire soon.
        </p>
      </div>
    `;

    return this.sendEmail({
      email: user.email,
      subject: `${process.env.APP_NAME} - Password Reset Request`,
      html
    });
  }

  async sendSessionReminderEmail(user, session) {
    const joinUrl = `${process.env.FRONTEND_URL}/therapy/join/${session._id}`;
    
    const html = `
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <h1 style="color: #4F46E5;">Therapy Session Reminder</h1>
        <p>Hi ${user.firstName},</p>
        <p>This is a reminder that you have an upcoming therapy session:</p>
        <div style="background-color: #F3F4F6; padding: 20px; border-radius: 5px; margin: 20px 0;">
          <h3 style="margin: 0 0 10px 0; color: #374151;">${session.title}</h3>
          <p style="margin: 5px 0;"><strong>Date:</strong> ${session.scheduledFor.toLocaleDateString()}</p>
          <p style="margin: 5px 0;"><strong>Time:</strong> ${session.scheduledFor.toLocaleTimeString()}</p>
          <p style="margin: 5px 0;"><strong>Duration:</strong> ${session.duration} minutes</p>
        </div>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${joinUrl}" 
             style="background-color: #10B981; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
            Join Session
          </a>
        </div>
        <p>We recommend joining 5 minutes before the scheduled time to ensure a smooth start.</p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #E5E7EB;">
        <p style="color: #6B7280; font-size: 12px;">
          Need to reschedule? Please contact your therapist or visit your dashboard.
        </p>
      </div>
    `;

    return this.sendEmail({
      email: user.email,
      subject: `${process.env.APP_NAME} - Session Reminder: ${session.title}`,
      html
    });
  }

  async sendWeeklyProgressReport(user, progressData) {
    const dashboardUrl = `${process.env.FRONTEND_URL}/dashboard`;
    
    const html = `
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <h1 style="color: #4F46E5;">Your Weekly Progress Report</h1>
        <p>Hi ${user.firstName},</p>
        <p>Here's a summary of your wellness journey this week:</p>
        
        <div style="background-color: #F3F4F6; padding: 20px; border-radius: 5px; margin: 20px 0;">
          <h3 style="margin: 0 0 15px 0; color: #374151;">This Week's Highlights</h3>
          <ul style="margin: 0; padding-left: 20px;">
            <li>Completed ${progressData.exercisesCompleted || 0} exercises</li>
            <li>Attended ${progressData.sessionsAttended || 0} therapy sessions</li>
            <li>Logged ${progressData.journalEntries || 0} journal entries</li>
            <li>Maintained a ${progressData.streakDays || 0}-day activity streak</li>
          </ul>
        </div>
        
        <div style="text-align: center; margin: 30px 0;">
          <a href="${dashboardUrl}" 
             style="background-color: #4F46E5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
            View Full Dashboard
          </a>
        </div>
        
        <p>Keep up the great work! Remember, every small step counts towards your wellness goals.</p>
        
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #E5E7EB;">
        <p style="color: #6B7280; font-size: 12px;">
          Don't want to receive these reports? You can update your preferences in your account settings.
        </p>
      </div>
    `;

    return this.sendEmail({
      email: user.email,
      subject: `${process.env.APP_NAME} - Your Weekly Progress Report`,
      html
    });
  }
}

module.exports = new EmailService();
