const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chat.controller');
const authMiddleware = require('../middleware/auth');

// Apply auth middleware to all routes
router.use(authMiddleware);

// Get chat history with a friend
router.get('/:friendId', chatController.getChatHistory);

// Send a message to a friend
router.post('/:friendId', chatController.sendMessage);

module.exports = router; 