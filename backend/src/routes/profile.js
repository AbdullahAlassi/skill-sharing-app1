const express = require("express")
const { check } = require("express-validator")
const profileController = require("../controllers/profileController")
const auth = require("../middleware/auth")
const upload = require("../middleware/upload")

const router = express.Router()

// @route   GET /api/profile
// @desc    Get current user's profile
// @access  Private
router.get("/", auth, profileController.getProfile)

// @route   PUT /api/profile
// @desc    Update user profile
// @access  Private
router.put(
  "/",
  [
    auth,
    [
      check("name", "Name is required if provided").optional().not().isEmpty(),
      check("bio", "Bio cannot be empty if provided").optional().not().isEmpty(),
    ],
  ],
  profileController.updateProfile,
)

// @route   POST /api/profile/skills
// @desc    Add skill to user profile
// @access  Private
router.post(
  "/skills",
  [
    auth,
    [
      check("skillId", "Skill ID is required").not().isEmpty(),
      check("proficiency", "Proficiency must be Beginner, Intermediate, or Advanced")
        .optional()
        .isIn(["Beginner", "Intermediate", "Advanced"]),
    ],
  ],
  profileController.addSkill,
)

// @route   DELETE /api/profile/skills/:skillId
// @desc    Remove skill from user profile
// @access  Private
router.delete("/skills/:skillId", auth, profileController.removeSkill)

// @route   POST /api/profile/interests
// @desc    Add interest to user profile
// @access  Private
router.post(
  "/interests",
  [auth, [check("skillId", "Skill ID is required").not().isEmpty()]],
  profileController.addInterest,
)

// @route   DELETE /api/profile/interests/:skillId
// @desc    Remove interest from user profile
// @access  Private
router.delete("/interests/:skillId", auth, profileController.removeInterest)

// @route   POST /api/profile/picture
// @desc    Upload profile picture
// @access  Private
router.post("/picture", auth, upload.single("profilePicture"), profileController.uploadProfilePicture)

module.exports = router

