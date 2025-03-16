const express = require("express")
const { check } = require("express-validator")
const eventController = require("../controllers/eventController")
const auth = require("../middleware/auth")

const router = express.Router()

// @route   GET /api/events
// @desc    Get all events
// @access  Public
router.get("/", eventController.getEvents)


// @route   POST /api/events
// @desc    Create a new event
// @access  Private
router.post(
  "/",
  [
    auth,
    [
      check("title", "Title is required").not().isEmpty(),
      check("description", "Description is required").not().isEmpty(),
      check("date", "Date is required").not().isEmpty(),
    ],
  ],
  eventController.createEvent,
)

// @route   PUT /api/events/:id
// @desc    Update an event
// @access  Private
router.put(
  "/:id",
  [
    auth,
    [
      check("title", "Title cannot be empty if provided").optional().not().isEmpty(),
      check("description", "Description cannot be empty if provided").optional().not().isEmpty(),
      check("date", "Date cannot be empty if provided").optional().not().isEmpty(),
    ],
  ],
  eventController.updateEvent,
)

// @route   DELETE /api/events/:id
// @desc    Delete an event
// @access  Private
router.delete("/:id", auth, eventController.deleteEvent)

// @route   POST /api/events/:id/register
// @desc    Register for an event
// @access  Private
router.post("/:id/register", auth, eventController.registerForEvent)

// @route   DELETE /api/events/:id/register
// @desc    Unregister from an event
// @access  Private
router.delete("/:id/register", auth, eventController.unregisterFromEvent)

// @route   GET /api/events/user
// @desc    Get events user is registered for
// @access  Private
router.get("/user", auth, eventController.getUserEvents)

// @route   GET /api/events/:id
// @desc    Get event by ID
// @access  Public
router.get("/:id", eventController.getEventById)

module.exports = router

