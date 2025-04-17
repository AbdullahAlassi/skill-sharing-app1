const express = require("express");
const { check } = require("express-validator");
const userController = require("../controllers/userController");
const auth = require("../middleware/auth");

const router = express.Router();

// @route   GET /api/users/me
// @desc    Get current user
// @access  Private
router.get("/me", auth, userController.getCurrentUser);

// @route   PUT /api/users/preferences
// @desc    Update user preferences
// @access  Private
router.put("/preferences", auth, userController.updatePreferences);

// @route   GET /api/users/preferences
// @desc    Get user preferences
// @access  Private
router.get("/preferences", auth, userController.getPreferences);

module.exports = router; 