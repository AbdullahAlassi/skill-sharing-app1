const Notification = require('../models/Notification');
const NotificationService = require('../services/notificationService');

// Get notifications for a user
exports.getNotifications = async (req, res) => {
  try {
    const userId = req.user._id;
    const notifications = await Notification.find({ user: userId })
      .sort({ createdAt: -1 })
      .limit(50);
    
    res.json(notifications);
  } catch (error) {
    console.error('Error getting notifications:', error);
    res.status(500).json({ message: 'Failed to get notifications' });
  }
};

// Create a notification
exports.createNotification = async (req, res) => {
  try {
    const { title, message, type, referenceId, referenceType } = req.body;
    const notification = await NotificationService.createNotification({
      user: req.user._id,
      title,
      message,
      type,
      referenceId,
      referenceType
    });

    res.status(201).json(notification);
  } catch (error) {
    console.error('Error creating notification:', error);
    res.status(500).json({ message: 'Failed to create notification' });
  }
};

// Mark notification as read
exports.markAsRead = async (req, res) => {
  try {
    const { notificationId } = req.params;
    const notification = await Notification.findOneAndUpdate(
      { _id: notificationId, user: req.user._id },
      { $set: { read: true } },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }

    res.json(notification);
  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({ message: 'Failed to mark notification as read' });
  }
};

// Mark all notifications as read
exports.markAllAsRead = async (req, res) => {
  try {
    await NotificationService.markAllAsRead(req.user._id);
    res.json({ message: 'All notifications marked as read' });
  } catch (error) {
    console.error('Error marking all notifications as read:', error);
    res.status(500).json({ message: 'Failed to mark all notifications as read' });
  }
};

// Delete notification
exports.deleteNotification = async (req, res) => {
  try {
    const { notificationId } = req.params;
    const result = await Notification.findOneAndDelete({
      _id: notificationId,
      user: req.user._id
    });

    if (!result) {
      return res.status(404).json({ message: 'Notification not found' });
    }

    res.json({ message: 'Notification deleted successfully' });
  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({ message: 'Failed to delete notification' });
  }
};

// Get unread notifications count
exports.getUnreadCount = async (req, res) => {
  try {
    const count = await NotificationService.getUnreadCount(req.user._id);
    res.json({ count });
  } catch (error) {
    console.error('Error getting unread notifications count:', error);
    res.status(500).json({ message: 'Failed to get unread notifications count' });
  }
};

// Register FCM token
exports.registerToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;
    await NotificationService.registerToken(req.user._id, fcmToken);
    res.json({ message: 'FCM token registered successfully' });
  } catch (error) {
    console.error('Error registering FCM token:', error);
    res.status(500).json({ message: 'Failed to register FCM token' });
  }
};

// Send notification to specific users
exports.sendNotification = async (req, res) => {
  try {
    const { title, body, userIds } = req.body;
    await NotificationService.sendNotification(title, body, userIds);
    res.json({ message: 'Notification sent successfully' });
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({ message: 'Failed to send notification' });
  }
};

// Send event notification
exports.sendEventNotification = async (req, res) => {
  try {
    const { eventId, title, description } = req.body;
    await NotificationService.sendEventNotification(eventId, title, description);
    res.json({ message: 'Event notification sent successfully' });
  } catch (error) {
    console.error('Error sending event notification:', error);
    res.status(500).json({ message: 'Failed to send event notification' });
  }
};

// Send goal notification
exports.sendGoalNotification = async (req, res) => {
  try {
    const { goalId, title, description } = req.body;
    await NotificationService.sendGoalNotification(goalId, title, description);
    res.json({ message: 'Goal notification sent successfully' });
  } catch (error) {
    console.error('Error sending goal notification:', error);
    res.status(500).json({ message: 'Failed to send goal notification' });
  }
}; 