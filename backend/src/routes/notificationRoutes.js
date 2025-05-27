const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const auth = require('../middleware/auth');
const { check } = require('express-validator');

// Core notification CRUD operations
router.get('/', auth, notificationController.getNotifications);
router.get('/unread/count', auth, notificationController.getUnreadCount);
router.post('/', auth, notificationController.createNotification);
router.patch('/:notificationId/read', auth, notificationController.markAsRead);
router.patch('/read-all', auth, notificationController.markAllAsRead);
router.delete('/:notificationId', auth, notificationController.deleteNotification);

// FCM token management
router.post('/register-token', auth, [
  check('fcmToken', 'FCM token is required').not().isEmpty()
], notificationController.registerToken);

// Push notification sending
router.post('/send', auth, [
  check('title', 'Title is required').not().isEmpty(),
  check('body', 'Body is required').not().isEmpty(),
  check('userIds', 'User IDs are required').isArray()
], notificationController.sendNotification);

// Event notifications
router.post('/send-event', auth, [
  check('eventId', 'Event ID is required').not().isEmpty(),
  check('title', 'Title is required').not().isEmpty(),
  check('description', 'Description is required').not().isEmpty()
], notificationController.sendEventNotification);

// Goal notifications
router.post('/send-goal', auth, [
  check('goalId', 'Goal ID is required').not().isEmpty(),
  check('title', 'Title is required').not().isEmpty(),
  check('description', 'Description is required').not().isEmpty()
], notificationController.sendGoalNotification);

module.exports = router; 