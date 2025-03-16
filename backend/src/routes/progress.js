const express = require("express")
const { check } = require("express-validator")
const progressController = require("../controllers/progressController")
const auth = require("../middleware/auth")

const router = express.Router()

// @route   GET /api/progress
// @desc    Get all progress for current user
// @access  Private
router.get("/", auth, progressController.getUserProgress)

// @route   GET /api/progress/:id
// @desc    Get progress by ID
// @access  Private
router.get("/:id", auth, progressController.getProgressById)

// @route   POST /api/progress
// @desc    Create a new progress tracking
// @access  Private
router.post(
  "/",
  [auth, [check("skillId", "Skill ID is required").not().isEmpty(), check("goal", "Goal is required").not().isEmpty()]],
  progressController.createProgress,
)

// @route   PUT /api/progress/:id
// @desc    Update progress
// @access  Private
router.put(
  "/:id",
  [
    auth,
    [
      check("goal", "Goal cannot be empty if provided").optional().not().isEmpty(),
      check("progress", "Progress must be between 0 and 100").optional().isInt({ min: 0, max: 100 }),
    ],
  ],
  progressController.updateProgress,
)

// @route   DELETE /api/progress/:id
// @desc    Delete progress
// @access  Private
router.delete("/:id", auth, progressController.deleteProgress)

// @route   POST /api/progress/:id/milestone
// @desc    Add milestone to progress
// @access  Private
router.post(
  "/:id/milestone",
  [auth, [check("title", "Title is required").not().isEmpty()]],
  progressController.addMilestone,
)

// @route   PUT /api/progress/:id/milestone/:milestoneId
// @desc    Update milestone
// @access  Private
router.put(
  "/:id/milestone/:milestoneId",
  [auth, [check("title", "Title cannot be empty if provided").optional().not().isEmpty()]],
  progressController.updateMilestone,
)

module.exports = router

