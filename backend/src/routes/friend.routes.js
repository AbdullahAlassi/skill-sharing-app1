const express = require('express');
const router = express.Router();
const friendController = require('../controllers/friend.controller');
const authMiddleware = require('../middleware/auth');

// Apply auth middleware to all routes
router.use(authMiddleware);

// User search route
router.get('/users/search', friendController.searchUsers);

// Friend request routes
router.post('/send-request', friendController.sendFriendRequest);
router.get('/friend-requests', friendController.getFriendRequests);
router.put('/friend-requests/:requestId/accept', friendController.acceptFriendRequest);
router.put('/friend-requests/:requestId/reject', friendController.rejectFriendRequest);

// Friends management routes
router.get('/friends', friendController.getFriends);
router.delete('/friends/:friendId', friendController.removeFriend);

module.exports = router; 