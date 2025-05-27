const express = require("express");
const userController = require("../controllers/userController");
const { check } = require("express-validator");
const {
  getCurrentUser,
  updateProfile,
  updateProfilePhoto,
  getUserSkills,
  updatePreferences,
  getPreferences,
  updateSkillProficiency
} = require("../controllers/userController");
const auth = require("../middleware/auth");
const upload = require("../middleware/upload");

const router = express.Router();

// Debug route to inspect token and user state
router.get("/debug-token", auth, (req, res) => {
  res.json({
    decodedToken: req.user._id,
    attachedEmail: req.user.email,
    attachedName: req.user.name,
    fullUser: req.user
  });
});

// @route   GET /api/users/me
// @desc    Get current user profile
// @access  Private
router.get('/me', auth, userController.getCurrentUser);


// @route   PUT /api/users/me
// @desc    Update user profile
// @access  Private
router.put(
  "/me",
  [
    auth,
    [
      check("name", "Name is required").not().isEmpty(),
      check("bio", "Bio is required").not().isEmpty(),
    ],
  ],
  updateProfile
);

// @route   PUT /api/users/me/photo
// @desc    Update user profile photo
// @access  Private
router.put(
  "/me/photo",
  [auth, upload.single("photo")],
  updateProfilePhoto
);

// @route   GET /api/users/me/skills
// @desc    Get user's skills
// @access  Private
router.get("/me/skills", auth, getUserSkills);

// @route   PUT /api/users/me/skills/:skillId/proficiency
// @desc    Update skill proficiency
// @access  Private
router.put(
  "/me/skills/:skillId/proficiency",
  [
    auth,
    [
      check("level", "Proficiency level is required").not().isEmpty(),
      check("level", "Proficiency level must be Beginner, Intermediate, or Advanced")
        .isIn(["Beginner", "Intermediate", "Advanced"]),
    ],
  ],
  updateSkillProficiency
);

// @route   PUT /api/users/preferences
// @desc    Update user preferences
// @access  Private
router.put("/preferences", auth, updatePreferences);

// @route   GET /api/users/preferences
// @desc    Get user preferences
// @access  Private
router.get("/preferences", auth, getPreferences);

// @route   GET /api/users/:id
// @desc    Get public user profile by ID
// @access  Public
router.get("/:id", userController.getPublicProfile);

// @route   PUT /api/users/me/password
// @desc    Change user password
// @access  Private
router.put(
  "/me/password",
  [
    auth,
    [
      check("oldPassword", "Old password is required").exists(),
      check("newPassword", "New password must be at least 6 characters").isLength({ min: 6 }),
    ],
  ],
  userController.changePassword
);

module.exports = router; 