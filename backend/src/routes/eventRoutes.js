const express = require("express")
const router = express.Router()
const eventController = require("../controllers/eventController")
const auth = require("../middleware/auth")

// @route   POST /api/events
// @desc    Create a new event
// @access  Private
router.post("/", auth, eventController.createEvent)

// @route   GET /api/events
// @desc    Get all events with filtering and pagination
// @access  Public
router.get("/", eventController.getEvents)

// @route   GET /api/events/popular
// @desc    Get popular events
// @access  Public
router.get("/popular", eventController.getPopularEvents)

// @route   GET /api/events/upcoming
// @desc    Get upcoming events
// @access  Public
router.get("/upcoming", eventController.getUpcomingEvents)

// @route   GET /api/events/:id
// @desc    Get event by ID
// @access  Public
router.get("/:id", eventController.getEventById)

// @route   PUT /api/events/:id
// @desc    Update event
// @access  Private (Organizer only)
router.put("/:id", auth, eventController.updateEvent)

// @route   DELETE /api/events/:id
// @desc    Delete event
// @access  Private (Organizer only)
router.delete("/:id", auth, eventController.deleteEvent)

// @route   POST /api/events/:id/register
// @desc    Register for event
// @access  Private
router.post("/:id/register", auth, eventController.registerForEvent)

// @route   DELETE /api/events/:id/register
// @desc    Unregister from event
// @access  Private
router.delete("/:id/register", auth, eventController.unregisterFromEvent)

// @route   POST /api/events/:id/rate
// @desc    Rate event
// @access  Private
router.post("/:id/rate", auth, eventController.rateEvent)

// @route   POST /api/events/:id/generate-code
// @desc    Generate attendance code for registered user
// @access  Private
router.post("/:id/generate-code", auth, eventController.generateAttendanceCode)

// @route   GET /api/events/:id/my-code
// @desc    Get user's attendance code for an event
// @access  Private
router.get("/:id/my-code", auth, eventController.getMyAttendanceCode)

// @route   POST /api/events/:id/validate-code
// @desc    Validate attendance code
// @access  Private
router.post("/:id/validate-code", auth, eventController.validateAttendanceCode)

// @route   GET /api/events/:id/attendance-stats
// @desc    Get attendance statistics for an event
// @access  Private (Organizer only)
router.get("/:id/attendance-stats", auth, eventController.getAttendanceStats)

module.exports = router 