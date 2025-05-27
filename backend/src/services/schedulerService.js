const Event = require('../models/Event');
const NotificationService = require('./notificationService');

class SchedulerService {
  /**
   * Send reminders for upcoming events
   * Should be called by a cron job every hour
   */
  static async sendEventReminders() {
    try {
      const now = new Date();
      const oneDayFromNow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
      const oneHourFromNow = new Date(now.getTime() + 60 * 60 * 1000);

      // Find events starting in the next 24 hours
      const upcomingEvents = await Event.find({
        date: {
          $gte: now,
          $lte: oneDayFromNow
        },
        participants: { $exists: true, $not: { $size: 0 } }
      }).populate('participants.user', 'name');

      for (const event of upcomingEvents) {
        const eventDate = new Date(event.date);
        const timeUntilEvent = eventDate - now;
        const hoursUntilEvent = timeUntilEvent / (60 * 60 * 1000);

        // Send 24-hour reminder
        if (hoursUntilEvent <= 24 && hoursUntilEvent > 23) {
          await this.sendEventReminder(event, '24 hours');
        }
        // Send 1-hour reminder
        else if (hoursUntilEvent <= 1 && hoursUntilEvent > 0) {
          await this.sendEventReminder(event, '1 hour');
        }
      }
    } catch (error) {
      console.error('Error sending event reminders:', error);
    }
  }

  /**
   * Send reminder notifications for an event
   */
  static async sendEventReminder(event, timeFrame) {
    try {
      const notifications = event.participants.map(participant => ({
        user: participant.user._id,
        title: 'Event Reminder',
        message: `${event.title} starts in ${timeFrame}. Get ready!`,
        type: 'event',
        referenceId: event._id,
        referenceType: 'Event'
      }));

      await NotificationService.createNotificationsForUsers(
        notifications.map(n => n.user),
        {
          title: notifications[0].title,
          message: notifications[0].message,
          type: notifications[0].type,
          referenceId: notifications[0].referenceId,
          referenceType: notifications[0].referenceType
        }
      );
    } catch (error) {
      console.error(`Error sending ${timeFrame} reminder for event ${event._id}:`, error);
    }
  }

  /**
   * Clean up old notifications
   * Should be called by a cron job daily
   */
  static async cleanupOldNotifications() {
    try {
      await NotificationService.cleanupOldNotifications();
    } catch (error) {
      console.error('Error cleaning up old notifications:', error);
    }
  }
}

module.exports = SchedulerService; 