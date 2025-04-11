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
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const {
      title,
      description,
      date,
      endDate,
      location,
      isVirtual,
      meetingLink,
      relatedSkills,
      maxParticipants,
    } = req.body;

    // Validate date
    if (new Date(date) < new Date()) {
      return res.status(400).json({ message: "Event date must be in the future" });
    }

    // Validate endDate if provided
    if (endDate && new Date(endDate) < new Date(date)) {
      return res.status(400).json({ message: "End date must be after start date" });
    }

    // Validate maxParticipants if provided
    if (maxParticipants && maxParticipants < 1) {
      return res.status(400).json({ message: "Max participants must be at least 1" });
    }

    // Create new event
    const event = new Event({
      title,
      description,
      date: new Date(date),
      endDate: endDate ? new Date(endDate) : undefined,
      location,
      isVirtual: isVirtual ?? true,
      meetingLink,
      relatedSkills: relatedSkills || [],
      maxParticipants,
      organizer: req.user.id,
    });

    await event.save();

    // Populate the event with organizer and skills
    const populatedEvent = await Event.findById(event._id)
      .populate("organizer", "name profilePicture")
      .populate("relatedSkills", "name category");

    res.status(201).json(populatedEvent);
  } catch (err) {
    console.error("Create event error:", err);
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: err.message });
    }
    res.status(500).json({ message: "Server error" });
  }
};

// @route   PUT /api/events/:id
// @desc    Update an event
// @access  Private
exports.updateEvent = async (req, res) => {
  try {
    const {
      title,
      description,
      date,
      endDate,
      location,
      isVirtual,
      meetingLink,
      relatedSkills,
      maxParticipants,
    } = req.body;

    // Find event and check if user is organizer
    const event = await Event.findById(req.params.id);
    if (!event) {
      return res.status(404).json({ message: "Event not found" });
    }

    if (event.organizer.toString() !== req.user.id) {
      return res.status(403).json({ message: "Not authorized" });
    }

    // Update event fields
    event.title = title ?? event.title;
    event.description = description ?? event.description;
    event.date = date ? new Date(date) : event.date;
    event.endDate = endDate ? new Date(endDate) : event.endDate;
    event.location = location ?? event.location;
    event.isVirtual = isVirtual ?? event.isVirtual;
    event.meetingLink = meetingLink ?? event.meetingLink;
    event.relatedSkills = relatedSkills ?? event.relatedSkills;
    event.maxParticipants = maxParticipants ?? event.maxParticipants;

    await event.save();

    // Populate the updated event
    const populatedEvent = await Event.findById(event._id)
      .populate("organizer", "name profilePicture")
      .populate("relatedSkills", "name category")
      .populate("participants.user", "name profilePicture");

    res.json(populatedEvent);
  } catch (err) {
    console.error("Update event error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
};

// @route   DELETE /api/events/:id
// @desc    Delete an event
// @access  Private
exports.deleteEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) {
      return res.status(404).json({ message: "Event not found" });
    }

    if (event.organizer.toString() !== req.user.id) {
      return res.status(403).json({ message: "Not authorized" });
    }

    await event.remove();
    res.json({ message: "Event deleted" });
  } catch (err) {
    console.error("Delete event error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
};

// @route   POST /api/events/:id/register
// @desc    Register for an event
// @access  Private
exports.registerForEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) {
      return res.status(404).json({ message: "Event not found" });
    }

    // Check if event is full
    if (event.maxParticipants && event.participants.length >= event.maxParticipants) {
      return res.status(400).json({ message: "Event is full" });
    }

    // Check if user is already registered
    const isRegistered = event.participants.some(
      (p) => p.user.toString() === req.user.id
    );
    if (isRegistered) {
      return res.status(400).json({ message: "Already registered for this event" });
    }

    // Add user to participants
    event.participants.push({
      user: req.user.id,
      registeredAt: Date.now(),
    });

    await event.save();

    // Populate the updated event
    const populatedEvent = await Event.findById(event._id)
      .populate("organizer", "name profilePicture")
      .populate("relatedSkills", "name category")
      .populate("participants.user", "name profilePicture");

    res.json(populatedEvent);
  } catch (err) {
    console.error("Register for event error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
};

// @route   DELETE /api/events/:id/register
// @desc    Unregister from an event
// @access  Private
exports.unregisterFromEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) {
      return res.status(404).json({ message: "Event not found" });
    }

    // Remove user from participants
    event.participants = event.participants.filter(
      (p) => p.user.toString() !== req.user.id
    );

    await event.save();

    // Populate the updated event
    const populatedEvent = await Event.findById(event._id)
      .populate("organizer", "name profilePicture")
      .populate("relatedSkills", "name category")
      .populate("participants.user", "name profilePicture");

    res.json(populatedEvent);
  } catch (err) {
    console.error("Unregister from event error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
};

// @route   GET /api/events/user/events
// @desc    Get events user is registered for
// @access  Private
exports.getUserEvents = async (req, res) => {
  try {
    const events = await Event.find({
      "participants.user": req.user.id,
    })
      .populate("organizer", "name profilePicture")
      .populate("relatedSkills", "name category")
      .populate("participants.user", "name profilePicture")
      .sort({ date: 1 });

    res.json(events);
  } catch (err) {
    console.error("Get user events error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
};

