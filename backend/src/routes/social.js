const express = require("express")
const { check } = require("express-validator")
const socialController = require("../controllers/socialController")
const auth = require("../middleware/auth")

const router = express.Router()

// @route   GET /api/social/groups
// @desc    Get all groups
// @access  Public
router.get("/groups", socialController.getGroups)

// @route   GET /api/social/groups/:id
// @desc    Get group by ID
// @access  Public/Private
router.get("/groups/:id", socialController.getGroupById)

// @route   POST /api/social/groups
// @desc    Create a new group
// @access  Private
router.post(
  "/groups",
  [
    auth,
    [
      check("name", "Name is required").not().isEmpty(),
      check("description", "Description is required").not().isEmpty(),
    ],
  ],
  socialController.createGroup,
)

// @route   PUT /api/social/groups/:id
// @desc    Update a group
// @access  Private
router.put(
  "/groups/:id",
  [
    auth,
    [
      check("name", "Name cannot be empty if provided").optional().not().isEmpty(),
      check("description", "Description cannot be empty if provided").optional().not().isEmpty(),
    ],
  ],
  socialController.updateGroup,
)

// @route   POST /api/social/groups/:id/join
// @desc    Join a group
// @access  Private
router.post("/groups/:id/join", auth, socialController.joinGroup)

// @route   DELETE /api/social/groups/:id/leave
// @desc    Leave a group
// @access  Private
router.delete("/groups/:id/leave", auth, socialController.leaveGroup)

// @route   GET /api/social/discussions/group/:groupId
// @desc    Get discussions for a group
// @access  Private
router.get("/discussions/group/:groupId", auth, socialController.getGroupDiscussions)

// @route   POST /api/social/discussions
// @desc    Create a new discussion
// @access  Private
router.post(
  "/discussions",
  [
    auth,
    [
      check("groupId", "Group ID is required").not().isEmpty(),
      check("title", "Title is required").not().isEmpty(),
      check("content", "Content is required").not().isEmpty(),
    ],
  ],
  socialController.createDiscussion,
)

// @route   POST /api/social/discussions/:id/reply
// @desc    Add a reply to a discussion
// @access  Private
router.post(
  "/discussions/:id/reply",
  [auth, [check("content", "Content is required").not().isEmpty()]],
  socialController.addReply,
)

// @route   GET /api/social/friends
// @desc    Get user's friends
// @access  Private
router.get("/friends", auth, socialController.getFriends)

// @route   POST /api/social/friends/:userId
// @desc    Add a friend
// @access  Private
router.post("/friends/:userId", auth, socialController.addFriend)

// @route   DELETE /api/social/friends/:userId
// @desc    Remove a friend
// @access  Private
router.delete("/friends/:userId", auth, socialController.removeFriend)

module.exports = router

