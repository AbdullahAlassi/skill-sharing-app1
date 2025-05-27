const Chat = require('../models/Chat');
const User = require('../models/User');
const NotificationService = require('../services/notificationService');

// Get chat history between two users
exports.getChatHistory = async (req, res) => {
  try {
    const { friendId } = req.params;
    const userId = req.user.id;

    // Find or create a private chat between the two users
    let chat = await Chat.findOne({
      type: 'private',
      participants: { $all: [userId, friendId] }
    }).populate('messages.sender', 'name profilePicture');

    if (!chat) {
      // Create new chat if it doesn't exist
      chat = new Chat({
        type: 'private',
        participants: [userId, friendId],
        messages: []
      });
      await chat.save();
    }

    res.json({
      success: true,
      data: chat.messages,
      message: 'Chat history retrieved successfully'
    });
  } catch (error) {
    console.error('Error in getChatHistory:', error);
    res.status(500).json({
      success: false,
      message: 'Error retrieving chat history',
      error: error.message
    });
  }
};

// Send a message
exports.sendMessage = async (req, res) => {
  try {
    const { friendId } = req.params;
    const { content } = req.body;
    const userId = req.user.id;

    // Find the chat between the two users
    let chat = await Chat.findOne({
      type: 'private',
      participants: { $all: [userId, friendId] }
    });

    if (!chat) {
      // Create new chat if it doesn't exist
      chat = new Chat({
        type: 'private',
        participants: [userId, friendId],
        messages: []
      });
    }

    // Add the new message
    const message = {
      sender: userId,
      content,
      readBy: [{ user: userId }]
    };

    chat.messages.push(message);
    chat.lastMessage = new Date();
    await chat.save();

    // Get sender's name for the notification
    const sender = await User.findById(userId).select('name');
    
    // Create notification for the recipient
    await NotificationService.createNotification({
      user: friendId,
      title: `New Message from ${sender.name}`,
      message: content.length > 50 ? content.substring(0, 47) + '...' : content,
      type: 'chat',
      referenceId: chat._id,
      referenceType: 'Chat'
    });

    // Populate sender details before sending response
    await chat.populate('messages.sender', 'name profilePicture');

    res.json({
      success: true,
      data: chat.messages[chat.messages.length - 1],
      message: 'Message sent successfully'
    });
  } catch (error) {
    console.error('Error in sendMessage:', error);
    res.status(500).json({
      success: false,
      message: 'Error sending message',
      error: error.message
    });
  }
}; 