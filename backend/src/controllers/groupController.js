const Group = require('../models/Group');
const mongoose = require('mongoose');

// Helper function to check if user has admin or moderator role
const hasAdminOrModeratorRole = (group, userId) => {
  const member = group.members.find(m => m.user.toString() === userId);
  return member && (member.role === 'Admin' || member.role === 'Moderator');
};

// Create a new group
exports.createGroup = async (req, res) => {
  try {
    const { name, description, relatedSkills, isPublic } = req.body;
    const userId = req.user.id;

    const group = new Group({
      name,
      description,
      relatedSkills,
      isPublic,
      creator: userId,
      members: [{ user: userId, role: 'Admin' }]
    });

    await group.save();
    await group.populate('creator', 'name profilePicture');
    await group.populate('members.user', 'name profilePicture');

    res.status(201).json(group);
  } catch (error) {
    console.error('Error in createGroup:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Add member to group
exports.addMember = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { userId } = req.body;
    const currentUserId = req.user.id;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid user ID' });
    }

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    // Check if current user has permission to add members
    if (!hasAdminOrModeratorRole(group, currentUserId)) {
      return res.status(403).json({ message: 'Not authorized to add members' });
    }

    // Check if user is already a member
    if (group.members.some(m => m.user.toString() === userId)) {
      return res.status(400).json({ message: 'User is already a member' });
    }

    group.members.push({ user: userId, role: 'Member' });
    await group.save();
    await group.populate('members.user', 'name profilePicture');

    res.json(group);
  } catch (error) {
    console.error('Error in addMember:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Remove member from group
exports.removeMember = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { userId } = req.body;
    const currentUserId = req.user.id;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid user ID' });
    }

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    // Check if current user has permission to remove members
    if (!hasAdminOrModeratorRole(group, currentUserId)) {
      return res.status(403).json({ message: 'Not authorized to remove members' });
    }

    // Cannot remove the creator
    if (group.creator.toString() === userId) {
      return res.status(400).json({ message: 'Cannot remove group creator' });
    }

    group.members = group.members.filter(m => m.user.toString() !== userId);
    await group.save();

    res.json({ message: 'Member removed successfully' });
  } catch (error) {
    console.error('Error in removeMember:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Update member role
exports.updateMemberRole = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { userId, newRole } = req.body;
    const currentUserId = req.user.id;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid user ID' });
    }

    if (!['Admin', 'Moderator', 'Member'].includes(newRole)) {
      return res.status(400).json({ message: 'Invalid role' });
    }

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    // Only admin can update roles
    if (!group.members.find(m => m.user.toString() === currentUserId)?.role === 'Admin') {
      return res.status(403).json({ message: 'Only admin can update roles' });
    }

    const memberIndex = group.members.findIndex(m => m.user.toString() === userId);
    if (memberIndex === -1) {
      return res.status(404).json({ message: 'Member not found' });
    }

    group.members[memberIndex].role = newRole;
    await group.save();

    res.json(group);
  } catch (error) {
    console.error('Error in updateMemberRole:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Post announcement
exports.postAnnouncement = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { title, content } = req.body;
    const userId = req.user.id;

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    // Check if user has permission to post announcements
    if (!hasAdminOrModeratorRole(group, userId)) {
      return res.status(403).json({ message: 'Not authorized to post announcements' });
    }

    group.announcements.push({
      title,
      content,
      createdBy: userId
    });

    await group.save();
    await group.populate('announcements.createdBy', 'name profilePicture');

    res.json(group.announcements);
  } catch (error) {
    console.error('Error in postAnnouncement:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get group announcements
exports.getGroupAnnouncements = async (req, res) => {
  try {
    const { groupId } = req.params;
    const userId = req.user.id;

    const group = await Group.findById(groupId)
      .populate('announcements.createdBy', 'name profilePicture');

    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    // Check if user is a member
    if (!group.members.some(m => m.user.toString() === userId)) {
      return res.status(403).json({ message: 'Not authorized to view announcements' });
    }

    res.json(group.announcements);
  } catch (error) {
    console.error('Error in getGroupAnnouncements:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Send group message
exports.sendGroupMessage = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { message, attachments } = req.body;
    const userId = req.user.id;

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    // Check if user is a member
    if (!group.members.some(m => m.user.toString() === userId)) {
      return res.status(403).json({ message: 'Not authorized to send messages' });
    }

    // Check if chat is enabled
    if (!group.chatEnabled) {
      return res.status(400).json({ message: 'Chat is disabled for this group' });
    }

    // Check if user has permission to send messages
    const member = group.members.find(m => m.user.toString() === userId);
    if (!group.chatPermissions.canSendMessages) {
      return res.status(403).json({ message: 'Sending messages is not allowed' });
    }

    // Check if user has permission to send media
    if (attachments && attachments.length > 0 && !group.chatPermissions.canSendMedia) {
      return res.status(403).json({ message: 'Sending media is not allowed' });
    }

    group.chat.push({
      sender: userId,
      message,
      attachments,
      readBy: [{ user: userId }]
    });

    await group.save();
    await group.populate('chat.sender', 'name profilePicture');

    res.json(group.chat[group.chat.length - 1]);
  } catch (error) {
    console.error('Error in sendGroupMessage:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get group chat history
exports.getGroupChatHistory = async (req, res) => {
  try {
    const { groupId } = req.params;
    const userId = req.user.id;
    const { limit = 50, before } = req.query;

    const group = await Group.findById(groupId)
      .populate('chat.sender', 'name profilePicture');

    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    // Check if user is a member
    if (!group.members.some(m => m.user.toString() === userId)) {
      return res.status(403).json({ message: 'Not authorized to view chat' });
    }

    let messages = group.chat;
    
    // Filter messages before a certain date if specified
    if (before) {
      const beforeDate = new Date(before);
      messages = messages.filter(m => m.createdAt < beforeDate);
    }

    // Sort by date and limit
    messages = messages
      .sort((a, b) => b.createdAt - a.createdAt)
      .slice(0, parseInt(limit));

    // Mark messages as read
    messages.forEach(message => {
      if (!message.readBy.some(r => r.user.toString() === userId)) {
        message.readBy.push({ user: userId });
      }
    });

    await group.save();

    res.json(messages);
  } catch (error) {
    console.error('Error in getGroupChatHistory:', error);
    res.status(500).json({ message: 'Server error' });
  }
}; 