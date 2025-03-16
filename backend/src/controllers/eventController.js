const { validationResult } = require("express-validator")
const Event = require("../models/Event")
const Skill = require("../models/Skill")

// @route   GET /api/events
// @desc    Get all events
// @access  Public
exports.getEvents = async (req, res) => {
  try {
    const events = await Event.find({ date: { $gte: new Date() } })
      .populate("organizer", "name")
      .populate("relatedSkills", "name category")
      .sort({ date: 1 })

    res.json(events)
  } catch (err) {
    console.error("Get events error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   GET /api/events/:id
// @desc    Get event by ID
// @access  Public
exports.getEventById = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)
      .populate("organizer", "name profilePicture")
      .populate("relatedSkills", "name category")
      .populate("participants.user", "name profilePicture")

    if (!event) {
      return res.status(404).json({ message: "Event not found" })
    }

    res.json(event)
  } catch (err) {
    console.error("Get event error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/events
// @desc    Create a new event
// @access  Private
exports.createEvent = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { title, description, date, endDate, location, isVirtual, meetingLink, relatedSkills, maxParticipants } =
    req.body

  try {
    // Check if related skills exist
    if (relatedSkills && relatedSkills.length > 0) {
      const skillCount = await Skill.countDocuments({
        _id: { $in: relatedSkills },
      })

      if (skillCount !== relatedSkills.length) {
        return res.status(400).json({ message: "One or more skills not found" })
      }
    }

    // Create new event
    const event = new Event({
      title,
      description,
      date,
      endDate: endDate || null,
      location: location || "Online",
      isVirtual: isVirtual !== undefined ? isVirtual : true,
      meetingLink,
      relatedSkills: relatedSkills || [],
      organizer: req.user.id,
      maxParticipants: maxParticipants || null,
    })

    await event.save()

    // Populate references before sending response
    await event.populate("organizer", "name")
    await event.populate("relatedSkills", "name category")

    res.status(201).json(event)
  } catch (err) {
    console.error("Create event error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   PUT /api/events/:id
// @desc    Update an event
// @access  Private
exports.updateEvent = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { title, description, date, endDate, location, isVirtual, meetingLink, relatedSkills, maxParticipants } =
    req.body

  try {
    const event = await Event.findById(req.params.id)

    if (!event) {
      return res.status(404).json({ message: "Event not found" })
    }

    // Check if user is the organizer
    if (event.organizer.toString() !== req.user.id) {
      return res.status(401).json({ message: "Not authorized to update this event" })
    }

    // Update fields
    if (title) event.title = title
    if (description) event.description = description
    if (date) event.date = date
    if (endDate !== undefined) event.endDate = endDate
    if (location) event.location = location
    if (isVirtual !== undefined) event.isVirtual = isVirtual
    if (meetingLink !== undefined) event.meetingLink = meetingLink
    if (relatedSkills) event.relatedSkills = relatedSkills
    if (maxParticipants !== undefined) event.maxParticipants = maxParticipants

    await event.save()

    res.json(event)
  } catch (err) {
    console.error("Update event error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   DELETE /api/events/:id
// @desc    Delete an event
// @access  Private
exports.deleteEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)

    if (!event) {
      return res.status(404).json({ message: "Event not found" })
    }

    // Check if user is the organizer
    if (event.organizer.toString() !== req.user.id) {
      return res.status(401).json({ message: "Not authorized to delete this event" })
    }

    await event.remove()

    res.json({ message: "Event removed" })
  } catch (err) {
    console.error("Delete event error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/events/:id/register
// @desc    Register for an event
// @access  Private
exports.registerForEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)

    if (!event) {
      return res.status(404).json({ message: "Event not found" })
    }

    // Check if event date has passed
    if (new Date(event.date) < new Date()) {
      return res.status(400).json({ message: "Cannot register for past events" })
    }

    // Check if user is already registered
    const alreadyRegistered = event.participants.some((participant) => participant.user.toString() === req.user.id)

    if (alreadyRegistered) {
      return res.status(400).json({ message: "Already registered for this event" })
    }

    // Check if event is full
    if (event.maxParticipants && event.participants.length >= event.maxParticipants) {
      return res.status(400).json({ message: "Event is full" })
    }

    // Add user to participants
    event.participants.push({
      user: req.user.id,
      registeredAt: Date.now(),
    })

    await event.save()

    res.json({ message: "Successfully registered for event" })
  } catch (err) {
    console.error("Register for event error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   DELETE /api/events/:id/register
// @desc    Unregister from an event
// @access  Private
exports.unregisterFromEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)

    if (!event) {
      return res.status(404).json({ message: "Event not found" })
    }

    // Check if event date has passed
    if (new Date(event.date) < new Date()) {
      return res.status(400).json({ message: "Cannot unregister from past events" })
    }

    // Remove user from participants
    event.participants = event.participants.filter((participant) => participant.user.toString() !== req.user.id)

    await event.save()

    res.json({ message: "Successfully unregistered from event" })
  } catch (err) {
    console.error("Unregister from event error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   GET /api/events/user
// @desc    Get events user is registered for
// @access  Private
exports.getUserEvents = async (req, res) => {
  try {
    const events = await Event.find({
      "participants.user": req.user.id,
    })
      .populate("organizer", "name")
      .populate("relatedSkills", "name category")
      .sort({ date: 1 })

    res.json(events)
  } catch (err) {
    console.error("Get user events error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

