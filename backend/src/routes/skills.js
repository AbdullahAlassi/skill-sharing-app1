const express = require("express")
const { check } = require("express-validator")
const skillController = require("../controllers/skillController")
const auth = require("../middleware/auth")
const Skill = require('../models/Skill')
const skillReviewController = require('../controllers/skillReviewController')
const SkillCategory = require('../models/skillCategory')

const router = express.Router()

// @route   GET /api/skills
// @desc    Get all skills
// @access  Public
router.get("/", async (req, res) => {
  try {
    const skills = await Skill.find()
    res.json(skills)
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
})

// @route   POST /api/skills
// @desc    Create a new skill
// @access  Private
router.post("/", auth, skillController.createSkill)

// @route   PUT /api/skills/:id
// @desc    Update a skill
// @access  Private
router.put("/:id", auth, async (req, res) => {
  try {
    const skill = await Skill.findByIdAndUpdate(req.params.id, req.body, { new: true })
    if (!skill) {
      return res.status(404).json({ message: "Skill not found" })
    }
    res.json(skill)
  } catch (error) {
    res.status(400).json({ message: error.message })
  }
})

// @route   GET /api/skills/categories
// @desc    Get all skill categories
// @access  Public
router.get("/categories", async (req, res) => {
  try {
    const categories = await SkillCategory.find();
    res.json(categories);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
})

// @route   GET /api/skills/recommendations
// @desc    Get skill recommendations for user
// @access  Private
router.get("/recommendations", auth, skillController.getRecommendations)

// @route   GET /api/skills/my
// @desc    Get all skills created by the current user
// @access  Private
router.get('/my', auth, require('../controllers/skillController').getSkillsByCreator);

// @route   GET /api/skills/search
// @desc    Search skills with filters
// @access  Public
router.get('/search', async (req, res) => {
  try {
    const { query, category, level } = req.query;
    const filter = {};
    
    if (query) filter.name = { $regex: query, $options: 'i' };
    if (category) filter['category.name'] = category;
    if (level) filter.difficultyLevel = level;
    
    const skills = await Skill.find(filter)
      .populate('category', '_id name')
      .sort({ name: 1 });
    
    res.json({ success: true, data: skills });
  } catch (error) {
    console.error('Error searching skills:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// @route   GET /api/skills/:id
// @desc    Get skill by ID
// @access  Public
router.get("/:id", skillController.getSkillById)

// Delete a skill
router.delete("/:id", auth, async (req, res) => {
  try {
    const skill = await Skill.findByIdAndDelete(req.params.id)
    if (!skill) {
      return res.status(404).json({ message: "Skill not found" })
    }
    res.json({ message: "Skill deleted" })
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
})

// @route   GET /api/skills/:id/roadmap
// @desc    Get skill roadmap
// @access  Public
router.get("/:id/roadmap", async (req, res) => {
  try {
    const skill = await Skill.findById(req.params.id)
    if (!skill) {
      return res.status(404).json({ message: "Skill not found" })
    }
    res.json({ roadmap: skill.roadmap || [] })
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
})

// @route   GET /api/skills/category/:categoryName
// @desc    Get skills by category
// @access  Public
router.get("/category/:categoryName", skillController.getSkillsByCategory)

// Skill Review Routes
router.post(
  '/:skillId/reviews',
  [
    auth,
    [
      check('rating', 'Rating is required and must be between 1 and 5')
        .isInt({ min: 1, max: 5 }),
      check('comment', 'Comment is required').not().isEmpty()
    ]
  ],
  skillReviewController.addReview
);

router.get(
  '/:skillId/reviews',
  skillReviewController.getReviews
);

router.put(
  '/:skillId/reviews/:reviewId',
  [
    auth,
    [
      check('rating', 'Rating is required and must be between 1 and 5')
        .isInt({ min: 1, max: 5 }),
      check('comment', 'Comment is required').not().isEmpty()
    ]
  ],
  skillReviewController.updateReview
);

router.delete(
  '/:skillId/reviews/:reviewId',
  auth,
  skillReviewController.deleteReview
);

module.exports = router

