const express = require("express")
const { check } = require("express-validator")
const skillController = require("../controllers/skillController")
const auth = require("../middleware/auth")

const router = express.Router()

// @route   GET /api/skills
// @desc    Get all skills
// @access  Public
router.get("/", skillController.getSkills)

// @route   POST /api/skills
// @desc    Create a new skill
// @access  Private
router.post(
  "/",
  [
    auth,
    [
      check("name", "Name is required").not().isEmpty(),
      check("category", "Category is required").not().isEmpty(),
      check("description", "Description is required").not().isEmpty(),
    ],
  ],
  skillController.createSkill,
)

// @route   PUT /api/skills/:id
// @desc    Update a skill
// @access  Private
router.put(
  "/:id",
  [
    auth,
    [
      check("name", "Name cannot be empty if provided").optional().not().isEmpty(),
      check("category", "Category cannot be empty if provided").optional().not().isEmpty(),
      check("description", "Description cannot be empty if provided").optional().not().isEmpty(),
    ],
  ],
  skillController.updateSkill,
)

// @route   GET /api/skills/categories
// @desc    Get all skill categories
// @access  Public
router.get("/categories", skillController.getCategories)

// @route   GET /api/skills/recommendations
// @desc    Get skill recommendations for user
// @access  Private
router.get("/recommendations", auth, skillController.getRecommendations)


// @route   GET /api/skills/:id
// @desc    Get skill by ID
// @access  Public
router.get("/:id", skillController.getSkillById)

module.exports = router

