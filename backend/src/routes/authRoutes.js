const express = require("express")
const { check } = require("express-validator")
const authController = require("../controllers/authController")
const auth = require("../middleware/auth")

const router = express.Router()

// @route   POST /api/auth/register
// @desc    Register a new user
// @access  Public
router.post(
  "/register",
  [
    check("name", "Name is required").not().isEmpty(),
    check("email", "Please include a valid email").isEmail(),
    check("password", "Password must be at least 6 characters").isLength({ min: 6 }),
  ],
  authController.register,
)

// @route   POST /api/auth/login
// @desc    Authenticate user & get token
// @access  Public
router.post(
  "/login",
  [check("email", "Please include a valid email").isEmail(), check("password", "Password is required").exists()],
  authController.login,
)

// @route   GET /api/auth/user
// @desc    Get authenticated user
// @access  Private
router.get("/user", auth, authController.getUser)

module.exports = router

