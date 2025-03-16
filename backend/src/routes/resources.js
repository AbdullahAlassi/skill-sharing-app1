const express = require("express")
const { check } = require("express-validator")
const resourceController = require("../controllers/resourceController")
const auth = require("../middleware/auth")

const router = express.Router()

// @route   GET /api/resources
// @desc    Get all resources
// @access  Public
router.get("/", resourceController.getResources)

// @route   GET /api/resources/:id
// @desc    Get resource by ID
// @access  Public
router.get("/:id", resourceController.getResourceById)

// @route   POST /api/resources
// @desc    Create a new resource
// @access  Private
router.post(
  "/",
  [
    auth,
    [
      check("title", "Title is required").not().isEmpty(),
      check("description", "Description is required").not().isEmpty(),
      check("link", "Link is required").not().isEmpty(),
      check("skillId", "Skill ID is required").not().isEmpty(),
      check("type", "Type must be Article, Video, Course, Book, or Other")
        .optional()
        .isIn(["Article", "Video", "Course", "Book", "Other"]),
    ],
  ],
  resourceController.createResource,
)

// @route   PUT /api/resources/:id
// @desc    Update a resource
// @access  Private
router.put(
  "/:id",
  [
    auth,
    [
      check("title", "Title cannot be empty if provided").optional().not().isEmpty(),
      check("description", "Description cannot be empty if provided").optional().not().isEmpty(),
      check("link", "Link cannot be empty if provided").optional().not().isEmpty(),
      check("type", "Type must be Article, Video, Course, Book, or Other")
        .optional()
        .isIn(["Article", "Video", "Course", "Book", "Other"]),
    ],
  ],
  resourceController.updateResource,
)

// @route   DELETE /api/resources/:id
// @desc    Delete a resource
// @access  Private
router.delete("/:id", auth, resourceController.deleteResource)

// @route   GET /api/resources/skill/:skillId
// @desc    Get resources by skill ID
// @access  Public
router.get("/skill/:skillId", resourceController.getResourcesBySkill)

// @route   POST /api/resources/:id/review
// @desc    Add a review to a resource
// @access  Private
router.post(
  "/:id/review",
  [auth, [check("rating", "Rating is required and must be between 1 and 5").isInt({ min: 1, max: 5 })]],
  resourceController.addReview,
)

module.exports = router

