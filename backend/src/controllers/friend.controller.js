const FriendRequest = require('../models/friend.model');
const User = require('../models/User');
const NotificationService = require('../services/notificationService');

// Send friend request
exports.sendFriendRequest = async (req, res) => {
  try {
    const { receiverId } = req.body;
    const senderId = req.user.id;

    // Check if users exist
    const [sender, receiver] = await Promise.all([
      User.findById(senderId),
      User.findById(receiverId)
    ]);

    if (!sender || !receiver) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Check if request already exists
    const existingRequest = await FriendRequest.findOne({
      $or: [
        { sender: senderId, receiver: receiverId },
        { sender: receiverId, receiver: senderId }
      ]
    });

    if (existingRequest) {
      return res.status(400).json({ message: 'Friend request already exists' });
    }

    // Create new friend request
    const friendRequest = new FriendRequest({
      sender: senderId,
      receiver: receiverId
    });

    await friendRequest.save();

    // Create notification for receiver
    await NotificationService.createNotification({
      user: receiverId,
      title: 'New Friend Request',
      message: `${sender.name} sent you a friend request`,
      type: 'friend',
      referenceId: friendRequest._id,
      referenceType: 'Friend'
    });

    res.status(201).json({
      message: 'Friend request sent successfully',
      friendRequest
    });
  } catch (error) {
    res.status(500).json({ message: 'Error sending friend request', error: error.message });
  }
};

// Get friend requests
exports.getFriendRequests = async (req, res) => {
  try {
    const userId = req.user.id;
    const requests = await FriendRequest.find({
      $or: [{ sender: userId }, { receiver: userId }],
    })
      .populate('sender', 'username email name profilePicture')
      .populate('receiver', 'username email name profilePicture')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: {
        requests,
        currentUserId: userId
      },
      message: 'Friend requests retrieved successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Accept friend request
exports.acceptFriendRequest = async (req, res) => {
  try {
    const requestId = req.params.requestId;
    const currentUserId = req.user.id;

    // Find the friend request
    const request = await FriendRequest.findById(requestId);
    if (!request) {
      return res.status(404).json({ success: false, message: 'Friend request not found' });
    }

    // Permission check
    if (request.receiver.toString() !== currentUserId) {
      return res.status(403).json({ success: false, message: 'Not authorized to accept this request' });
    }

    // Update the status
    request.status = 'accepted';
    request.updatedAt = Date.now();
    await request.save();

    const senderId = request.sender.toString();
    const receiverId = request.receiver.toString();

    // Add to both users' friends lists
    await Promise.all([
      User.findByIdAndUpdate(senderId, { $addToSet: { friends: receiverId } }),
      User.findByIdAndUpdate(receiverId, { $addToSet: { friends: senderId } }),
    ]);

    // Create notification for sender
    await NotificationService.createNotification({
      user: senderId,
      title: 'Friend Request Accepted',
      message: `${req.user.name} accepted your friend request`,
      type: 'friend',
      referenceId: request._id,
      referenceType: 'Friend'
    });

    return res.status(200).json({ 
      success: true, 
      message: 'Friend request accepted and users linked',
      friendRequest: request
    });
  } catch (error) {
    console.error('[AcceptFriendRequest Error]', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Server error', 
      error: error.message 
    });
  }
};

// Reject friend request
exports.rejectFriendRequest = async (req, res) => {
  try {
    const { requestId } = req.params;
    const userId = req.user.id;

    const friendRequest = await FriendRequest.findOne({
      _id: requestId,
      receiver: userId,
      status: 'pending'
    });

    if (!friendRequest) {
      return res.status(404).json({ message: 'Friend request not found' });
    }

    friendRequest.status = 'rejected';
    friendRequest.updatedAt = Date.now();
    await friendRequest.save();

    res.json({ message: 'Friend request rejected', friendRequest });
  } catch (error) {
    res.status(500).json({ message: 'Error rejecting friend request', error: error.message });
  }
};

// Get friends list
exports.getFriends = async (req, res) => {
  try {
    const userId = req.user.id;

    const friendRequests = await FriendRequest.find({
      $or: [{ sender: userId }, { receiver: userId }],
      status: 'accepted'
    }).populate('sender receiver', 'name email profilePicture');

    const friends = friendRequests.map(request => {
      const friend = request.sender._id.toString() === userId
        ? request.receiver
        : request.sender;
      return friend;
    });

    res.json(friends);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching friends', error: error.message });
  }
};

// Remove friend
exports.removeFriend = async (req, res) => {
  try {
    const { friendId } = req.params;
    const userId = req.user.id;

    const friendRequest = await FriendRequest.findOne({
      $or: [
        { sender: userId, receiver: friendId },
        { sender: friendId, receiver: userId }
      ],
      status: 'accepted'
    });

    if (!friendRequest) {
      return res.status(404).json({ message: 'Friendship not found' });
    }

    await friendRequest.deleteOne();

    res.json({ message: 'Friend removed successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error removing friend', error: error.message });
  }
};

// Search users
exports.searchUsers = async (req, res) => {
  try {
    const { q } = req.query;
    if (!q) {
      return res.status(400).json({ message: 'Search query is required' });
    }

    const users = await User.find({
      $or: [
        { name: { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } }
      ],
      _id: { $ne: req.user.id } // Exclude current user
    }).select('name email profilePicture bio');

    res.json(users);
  } catch (error) {
    res.status(500).json({ message: 'Error searching users', error: error.message });
  }
}; 