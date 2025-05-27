const express = require("express")
const { check } = require("express-validator")
const resourceController = require("../controllers/resourceController")
const auth = require("../middleware/auth")
const resourceUpload = require("../middleware/resourceUpload")

const router = express.Router()

// @route   GET /api/resources
// @desc    Get all resources with optional filtering and sorting
// @access  Public
router.get("/", resourceController.getResources)

// @route   GET /api/resources/recommendations
// @desc    Get recommended resources based on user's skills and interests
// @access  Private
router.get("/recommendations", auth, resourceController.getRecommendations)

// @route   GET /api/resources/user-skills
// @desc    Get resources for skills that the user has added to their profile
// @access  Private
router.get("/user-skills", auth, resourceController.getResourcesByUserSkills)

// @route   GET /api/resources/created-skills
// @desc    Get resources for skills that the user has created
// @access  Private
router.get("/created-skills", auth, resourceController.getResourcesByCreatedSkills)

// @route   GET /api/resources/by-user-categories
// @desc    Get resources based on user's favorite categories
// @access  Private
router.get("/by-user-categories", auth, resourceController.getResourcesByUserCategories)

// @route   GET /api/resources/skill/:skillId
// @desc    Get resources by skill ID
// @access  Public
router.get("/skill/:skillId", resourceController.getResourcesBySkill)

// @route   GET /api/resources/:id
// @desc    Get resource by ID
// @access  Public
router.get("/:id", resourceController.getResourceById)

// @route   POST /api/resources
// @desc    Create a resource
// @access  Private
router.post(
  "/",
  [
    auth,
    resourceUpload.single("file"),
    [
      check("title", "Title is required").not().isEmpty(),
      check("description", "Description is required").not().isEmpty(),
      check("type", "Type is required").not().isEmpty(),
      check("skill", "Skill is required").not().isEmpty(),
      check("category", "Category is required").not().isEmpty(),
    ],
  ],
  resourceController.createResource
)

// @route   POST /api/resources/upload
// @desc    Upload a resource file
// @access  Private
router.post(
  "/upload",
  [
    auth,
    resourceUpload.single('file'),
    [
      check("title", "Title is required").not().isEmpty(),
      check("description", "Description is required").not().isEmpty(),
      check("skillId", "Skill ID is required").not().isEmpty(),
      check("category", "Category is required").not().isEmpty(),
    ],
  ],
  resourceController.uploadResource,
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
      check("type", "Type must be Article, Video, Course, Book, Image, PDF, or Other")
        .optional()
        .isIn(["Article", "Video", "Course", "Book", "Image", "PDF", "Other"]),
      check("category", "Category cannot be empty if provided").optional().not().isEmpty(),
    ],
  ],
  resourceController.updateResource,
)

// @route   DELETE /api/resources/:id
// @desc    Delete a resource
// @access  Private
router.delete("/:id", auth, resourceController.deleteResource)

// @route   POST /api/resources/:id/review
// @desc    Add a review to a resource
// @access  Private
router.post(
  "/:id/review",
  [auth, [check("rating", "Rating is required and must be between 1 and 5").isInt({ min: 1, max: 5 })]],
  resourceController.addReview,
)

// @route   POST /api/resources/:id/view
// @desc    Increment view count for a resource
// @access  Public
router.post("/:id/view", resourceController.incrementViewCount)

// @route   POST /api/resources/:id/complete
// @desc    Mark a resource as completed
// @access  Private
router.post("/:id/complete", auth, resourceController.markAsCompleted)

// @route   PATCH /api/resources/:id/flag
// @desc    Flag a resource for moderation
// @access  Private
router.patch("/:id/flag", auth, resourceController.flagResource)

// @route   DELETE /api/resources/:id/force
// @desc    Force delete a resource (admin only)
// @access  Private/Admin
router.delete("/:id/force", auth, resourceController.forceDeleteResource)

module.exports = router

