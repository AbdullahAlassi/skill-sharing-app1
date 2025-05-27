const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const {
  createGroup,
  addMember,
  removeMember,
  updateMemberRole,
  postAnnouncement,
  getGroupAnnouncements,
  sendGroupMessage,
  getGroupChatHistory
} = require('../controllers/groupController');

// Group management routes
router.post('/', auth, createGroup);
router.post('/:groupId/add-member', auth, addMember);
router.post('/:groupId/remove-member', auth, removeMember);
router.put('/:groupId/update-role', auth, updateMemberRole);

// Announcement routes
router.post('/:groupId/announcements', auth, postAnnouncement);
router.get('/:groupId/announcements', auth, getGroupAnnouncements);

// Chat routes
router.post('/:groupId/messages', auth, sendGroupMessage);
router.get('/:groupId/messages', auth, getGroupChatHistory);

module.exports = router; 