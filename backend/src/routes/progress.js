const express = require("express")
const { check } = require("express-validator")
const progressController = require("../controllers/progressController")
const auth = require("../middleware/auth")
const LearningGoal = require('../models/LearningGoal')
const { startOfWeek, endOfWeek, startOfMonth, endOfMonth, subWeeks, subMonths } = require('date-fns')

const router = express.Router()

// Get all goals for the current user
router.get('/goals', auth, async (req, res) => {
  try {
    console.log('[DEBUG] User ID:', req.user._id);
    console.log('[DEBUG] LearningGoal schema:', LearningGoal.schema);

    const goals = await LearningGoal.find({ user: req.user._id })
      .populate('skill', 'name category')
      .sort({ createdAt: -1 });

    console.log('[DEBUG] Found goals:', goals);

    res.json({
      success: true,
      data: goals,
      message: 'Goals retrieved successfully'
    });
  } catch (error) {
    console.error('[ERROR] GET /goals:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve goals',
      error: error.message
    });
  }
});

// Create a new learning goal
router.post('/goals', auth, async (req, res) => {
  try {
    const { skill, targetDate, currentProgress } = req.body;
    
    const goal = new LearningGoal({
      user: req.user._id,
      skill,
      targetDate,
      currentProgress: currentProgress || 0
    });

    await goal.save();

    res.status(201).json({
      success: true,
      data: goal
    });

  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Update a goal
router.put('/goals/:id', auth, async (req, res) => {
  try {
    const goal = await LearningGoal.findOne({
      _id: req.params.id,
      user: req.user._id
    });

    if (!goal) {
      return res.status(404).json({ message: 'Goal not found' });
    }

    const { currentProgress, targetDate } = req.body;
    
    if (currentProgress !== undefined) {
      goal.currentProgress = currentProgress;
    }
    if (targetDate) {
      goal.targetDate = targetDate;
    }

    await goal.save();
    res.json(goal);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Delete a goal
router.delete('/goals/:id', auth, async (req, res) => {
  try {
    const goal = await LearningGoal.findOneAndDelete({
      _id: req.params.id,
      user: req.user._id
    });

    if (!goal) {
      return res.status(404).json({ message: 'Goal not found' });
    }

    res.json({ message: 'Goal deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get analytics for the current user
router.get('/analytics', auth, async (req, res) => {
  try {
    const goals = await LearningGoal.find({ user: req.user._id });
    
    const analytics = {
      total: goals.length,
      completed: goals.filter(g => g.status === 'completed').length,
      inProgress: goals.filter(g => g.status === 'in_progress').length,
      expired: goals.filter(g => g.status === 'expired').length
    };

    res.json(analytics);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get goal completion trends
router.get('/analytics/trends', auth, async (req, res) => {
  try {
    const userId = req.user._id;

    // Get weekly trends (last 4 weeks)
    const weeklyTrends = [];
    for (let i = 0; i < 4; i++) {
      const weekStart = startOfWeek(subWeeks(new Date(), i));
      const weekEnd = endOfWeek(weekStart);

      const completedGoals = await LearningGoal.countDocuments({
        user: userId,
        status: 'completed',
        completedAt: {
          $gte: weekStart,
          $lte: weekEnd
        }
      });

      weeklyTrends.unshift({
        week: weekStart.toISOString(),
        count: completedGoals
      });
    }

    // Get monthly trends (last 6 months)
    const monthlyTrends = [];
    for (let i = 0; i < 6; i++) {
      const monthStart = startOfMonth(subMonths(new Date(), i));
      const monthEnd = endOfMonth(monthStart);

      const completedGoals = await LearningGoal.countDocuments({
        user: userId,
        status: 'completed',
        completedAt: {
          $gte: monthStart,
          $lte: monthEnd
        }
      });

      monthlyTrends.unshift({
        month: monthStart.toISOString(),
        count: completedGoals
      });
    }

    res.json({
      success: true,
      data: {
        weeklyTrends,
        monthlyTrends
      }
    });
  } catch (error) {
    console.error('Error getting goal trends:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get goal trends'
    });
  }
});

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

// Get user progress for a specific skill
router.get('/:userId/:skillId', auth, progressController.getUserProgress);

// Mark a learning resource as completed
router.post('/:skillId/complete-resource', auth, progressController.completeResource);

// Unmark a learning resource as completed
router.delete('/:skillId/complete-resource/:resourceId', auth, progressController.unmarkResourceComplete);

// Add practice time
router.post('/:skillId/add-practice-time', auth, progressController.addPracticeTime);

// Submit assessment score
router.post('/:skillId/submit-assessment', auth, progressController.submitAssessment);

// Update learning path progress
router.post('/:skillId/update-learning-path', auth, progressController.updateLearningPath);

// GET /api/progress/skill/:skillId
router.get('/skill/:skillId', auth, progressController.getSkillProgress);

module.exports = router

