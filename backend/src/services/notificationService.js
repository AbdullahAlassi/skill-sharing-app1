const Notification = require('../models/Notification');
const User = require('../models/User');

class NotificationService {
  /**
   * Create a notification for a single user
   */
  static async createNotification({ user, title, message, type, referenceId, referenceType }) {
    try {
      const notification = await Notification.create({
        user,
        title,
        message,
        type,
        referenceId,
        referenceType
      });
      return notification;
    } catch (error) {
      console.error('Error creating notification:', error);
      throw error;
    }
  }

  /**
   * Create notifications for multiple users
   */
  static async createNotificationsForUsers(userIds, notificationData) {
    try {
      const notifications = userIds.map(userId => ({
        ...notificationData,
        user: userId
      }));
      return await Notification.insertMany(notifications);
    } catch (error) {
      console.error('Error creating notifications for users:', error);
      throw error;
    }
  }

  /**
   * Notify users who have specific skills
   */
  static async notifyUsersWithSkills(skillIds, notificationData) {
    try {
      // Find users who have any of the specified skills
      const users = await User.find({
        'skills.skill': { $in: skillIds }
      }).select('_id');

      const userIds = users.map(user => user._id);
      return await this.createNotificationsForUsers(userIds, notificationData);
    } catch (error) {
      console.error('Error notifying users with skills:', error);
      throw error;
    }
  }

  /**
   * Get unread notifications count for a user
   */
  static async getUnreadCount(userId) {
    try {
      return await Notification.countDocuments({
        user: userId,
        read: false
      });
    } catch (error) {
      console.error('Error getting unread notifications count:', error);
      throw error;
    }
  }

  /**
   * Mark all notifications as read for a user
   */
  static async markAllAsRead(userId) {
    try {
      return await Notification.updateMany(
        { user: userId, read: false },
        { $set: { read: true } }
      );
    } catch (error) {
      console.error('Error marking all notifications as read:', error);
      throw error;
    }
  }

  /**
   * Delete old notifications (older than 30 days)
   */
  static async cleanupOldNotifications() {
    try {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      return await Notification.deleteMany({
        createdAt: { $lt: thirtyDaysAgo }
      });
    } catch (error) {
      console.error('Error cleaning up old notifications:', error);
      throw error;
    }
  }

  /**
   * Register FCM token for a user
   */
  static async registerToken(userId, fcmToken) {
    try {
      await User.findByIdAndUpdate(userId, {
        $set: { fcmToken }
      });
    } catch (error) {
      console.error('Error registering FCM token:', error);
      throw error;
    }
  }

  /**
   * Send notification to specific users
   */
  static async sendNotification(title, body, userIds) {
    try {
      const notificationData = {
        title,
        message: body,
        type: 'message'
      };
      return await this.createNotificationsForUsers(userIds, notificationData);
    } catch (error) {
      console.error('Error sending notification:', error);
      throw error;
    }
  }

  /**
   * Send event notification
   */
  static async sendEventNotification(eventId, title, description) {
    try {
      const notificationData = {
        title,
        message: description,
        type: 'event',
        referenceId: eventId,
        referenceType: 'event'
      };
      // Get users who are interested in events
      const users = await User.find({ 'preferences.notifications.events': true }).select('_id');
      const userIds = users.map(user => user._id);
      return await this.createNotificationsForUsers(userIds, notificationData);
    } catch (error) {
      console.error('Error sending event notification:', error);
      throw error;
    }
  }

  /**
   * Send goal notification
   */
  static async sendGoalNotification(goalId, title, description) {
    try {
      const notificationData = {
        title,
        message: description,
        type: 'goal',
        referenceId: goalId,
        referenceType: 'goal'
      };
      // Get users who are interested in goals
      const users = await User.find({ 'preferences.notifications.goals': true }).select('_id');
      const userIds = users.map(user => user._id);
      return await this.createNotificationsForUsers(userIds, notificationData);
    } catch (error) {
      console.error('Error sending goal notification:', error);
      throw error;
    }
  }
}

module.exports = NotificationService; 