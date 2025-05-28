const { validationResult } = require("express-validator")
const Event = require("../models/Event")
const Skill = require("../models/Skill")
const mongoose = require("mongoose")
const crypto = require('crypto')
const NotificationService = require('../services/notificationService')
const Notification = require('../models/Notification')

// Utility function to generate a secure 6-character alphanumeric code
const generateAttendanceCode = () => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  let code = ''
  for (let i = 0; i < 6; i++) {
    const randomIndex = crypto.randomInt(0, chars.length)
    code += chars[randomIndex]
  }
  return code
}

// Utility function to check if a code is expired
const isCodeExpired = (expiresAt) => {
  return expiresAt && new Date() > new Date(expiresAt)
}

// @route   GET /api/events
// @desc    Get all events
// @access  Public
exports.getEvents = async (req, res) => {
  try {
    const {
      category,
      date,
      isVirtual,
      visibility,
      page = 1,
      limit = 10,
      sortBy = "date",
      sortOrder = "asc",
    } = req.query

    const query = {}
    if (category) query.category = category
    if (date) query.date = { $gte: new Date(date) }
    if (isVirtual !== undefined) query.isVirtual = isVirtual === "true"
    if (visibility) query.visibility = visibility

    const sort = {}
    sort[sortBy] = sortOrder === "asc" ? 1 : -1

    const events = await Event.find(query)
      .sort(sort)
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .populate("organizer", "name email")
      .populate("relatedSkills", "name")
      .populate("participants.user", "name email")

    const total = await Event.countDocuments(query)

    res.json({
      events,
      currentPage: page,
      totalPages: Math.ceil(total / limit),
      totalEvents: total,
    })
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

// @route   GET /api/events/:id
// @desc    Get event by ID
// @access  Public
exports.getEventById = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)
      .populate("organizer", "name email")
      .populate("relatedSkills", "name")
      .populate("participants.user", "name email")
      .populate("ratings.user", "name email")

    if (!event) {
      return res.status(404).json({ message: "Event not found" })
    }

    // Increment views
    event.views += 1
    await event.save()

    res.json(event)
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

// @route   POST /api/events
// @desc    Create a new event
// @access  Private
exports.createEvent = async (req, res) => {
  try {
    const {
      title,
      description,
      category,
      date,
      endDate,
      location,
      isVirtual,
      meetingLink,
      image,
      relatedSkills,
      maxParticipants,
      visibility,
    } = req.body

    const event = new Event({
      title,
      description,
      category,
      date,
      endDate,
      location,
      isVirtual,
      meetingLink,
      image,
      relatedSkills,
      organizer: req.user._id,
      maxParticipants,
      visibility,
    })

    await event.save()

    // Notify users with related skills
    if (relatedSkills && relatedSkills.length > 0) {
      await NotificationService.notifyUsersWithSkills(relatedSkills, {
        title: 'New Event for Your Skills',
        message: `${title} has been created and might interest you based on your skills.`,
        type: 'event',
        referenceId: event._id,
        referenceType: 'Event'
      });
    }

    res.status(201).json(event)
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

// @route   PUT /api/events/:id
// @desc    Update an event
// @access  Private
exports.updateEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)

    if (!event) {
      return res.status(404).json({ message: "Event not found" })
    }

    if (event.organizer.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: "Not authorized to update this event" })
    }

    const updatedEvent = await Event.findByIdAndUpdate(
      req.params.id,
      { $set: req.body },
      { new: true }
    )

    res.json(updatedEvent)
  } catch (error) {
    res.status(500).json({ message: error.message })
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

    if (event.organizer.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: "Not authorized to delete this event" })
    }

    await Event.findByIdAndDelete(req.params.id)
    res.json({ message: "Event deleted successfully" })
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

// @route   POST /api/events/:id/register
// @desc    Register for an event
// @access  Private
exports.registerForEvent = async (req, res) => {
  console.log('\n=== Starting Event Registration ===');
  console.log('Event ID:', req.params.id);
  console.log('User ID:', req.user.id);

  try {
    const eventId = req.params.id;
    const userId = req.user.id;

    console.log('Finding event...');
    const event = await Event.findById(eventId);
    if (!event) {
      console.log('Event not found with ID:', eventId);
      return res.status(404).json({ message: 'Event not found' });
    }
    console.log('Event found:', {
      id: event._id,
      title: event.title,
      participants: event.participants.length
    });

    // Check if user is already registered
    console.log('Checking if user is already registered...');
    const isRegistered = event.participants.some(p => p.user.toString() === userId);
    if (isRegistered) {
      console.log('User already registered');
      return res.status(400).json({ message: 'Already registered for this event' });
    }
    console.log('User not registered yet');

    // Generate a random 4-digit code
    const registrationCode = Math.floor(1000 + Math.random() * 9000).toString();
    console.log('Generated registration code:', registrationCode);

    // Add user to participants with registration code
    console.log('Adding user to participants...');
    event.participants.push({
      user: userId,
      registrationCode: registrationCode,
      registeredAt: new Date()
    });

    console.log('Saving event...');
    await event.save();
    console.log('Event saved successfully');

    // Create notification with registration code
    console.log('Creating notification...');
    const notification = new Notification({
      user: userId,
      title: 'Event Registration Successful',
      message: `You've successfully registered for ${event.title}. Your registration code is: ${registrationCode}. Please keep this code for event check-in.`,
      type: 'event',
      read: false,
      referenceId: event._id,
      referenceType: 'Event'
    });
    await notification.save();
    console.log('Notification created successfully');

    console.log('=== Event Registration Completed ===\n');
    res.json({ 
      message: 'Successfully registered for event',
      registrationCode: registrationCode
    });
  } catch (error) {
    console.error('Error in registerForEvent:', error);
    console.error('Error stack:', error.stack);
    console.log('=== Event Registration Failed ===\n');
    res.status(500).json({ message: 'Server error' });
  }
};

// @route   DELETE /api/events/:id/register
// @desc    Unregister from an event
// @access  Private
exports.unregisterFromEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)

    if (!event) {
      return res.status(404).json({ message: "Event not found" })
    }

    event.participants = event.participants.filter(
      (p) => p.user.toString() !== req.user._id.toString()
    )

    await event.save()
    res.json(event)
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

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

// Rate event
exports.rateEvent = async (req, res) => {
  try {
    const { rating, comment } = req.body
    const event = await Event.findById(req.params.id)

    if (!event) {
      return res.status(404).json({ message: "Event not found" })
    }

    // Check if user has already rated
    const existingRating = event.ratings.find(
      (r) => r.user.toString() === req.user._id.toString()
    )

    if (existingRating) {
      existingRating.rating = rating
      existingRating.comment = comment
      existingRating.date = Date.now()
    } else {
      event.ratings.push({
        user: req.user._id,
        rating,
        comment,
      })
    }

    // Update popularity based on ratings
    const totalRatings = event.ratings.length
    const averageRating =
      event.ratings.reduce((acc, curr) => acc + curr.rating, 0) / totalRatings
    event.popularity = (averageRating * totalRatings) / 10

    await event.save()
    res.json(event)
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

// Get popular events
exports.getPopularEvents = async (req, res) => {
  try {
    const { limit = 5 } = req.query

    const events = await Event.find()
      .sort({ popularity: -1 })
      .limit(parseInt(limit))
      .populate("organizer", "name email")
      .populate("relatedSkills", "name")

    res.json(events)
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

// Get upcoming events
exports.getUpcomingEvents = async (req, res) => {
  try {
    const { limit = 5 } = req.query

    const events = await Event.find({
      date: { $gte: new Date() },
    })
      .sort({ date: 1 })
      .limit(parseInt(limit))
      .populate("organizer", "name email")
      .populate("relatedSkills", "name")

    res.json(events)
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

// Generate attendance code for a registered user
exports.generateAttendanceCode = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)

    if (!event) {
      return res.status(404).json({ message: "Event not found" })
    }

    // Find the participant
    const participant = event.participants.find(
      (p) => p.user.toString() === req.user._id.toString()
    )

    if (!participant) {
      return res.status(400).json({ message: "You are not registered for this event" })
    }

    // Generate new code
    const code = generateAttendanceCode()
    const now = new Date()
    const expiresAt = new Date(now.getTime() + 2 * 60 * 60 * 1000) // 2 hours from now

    // Update participant's code
    participant.attendanceCode = code
    participant.codeGeneratedAt = now
    participant.codeExpiresAt = expiresAt
    participant.attended = false
    participant.attendanceVerifiedAt = null

    await event.save()

    res.json({
      code,
      expiresAt,
      message: "Attendance code generated successfully"
    })
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

// Get user's attendance code for an event
exports.getMyAttendanceCode = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)

    if (!event) {
      return res.status(404).json({ message: "Event not found" })
    }

    const participant = event.participants.find(
      (p) => p.user.toString() === req.user._id.toString()
    )

    if (!participant) {
      return res.status(400).json({ message: "You are not registered for this event" })
    }

    if (!participant.attendanceCode) {
      return res.status(404).json({ message: "No attendance code generated yet" })
    }

    if (isCodeExpired(participant.codeExpiresAt)) {
      return res.status(400).json({ message: "Attendance code has expired" })
    }

    res.json({
      code: participant.attendanceCode,
      expiresAt: participant.codeExpiresAt,
      attended: participant.attended
    })
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

// Validate attendance code
exports.validateAttendanceCode = async (req, res) => {
  try {
    const { code } = req.body

    if (!code) {
      return res.status(400).json({ message: "Attendance code is required" })
    }

    const event = await Event.findById(req.params.id)

    if (!event) {
      return res.status(404).json({ message: "Event not found" })
    }

    // Find participant with matching code
    const participant = event.participants.find(
      (p) => p.attendanceCode === code
    )

    if (!participant) {
      return res.status(400).json({ message: "Invalid attendance code" })
    }

    if (isCodeExpired(participant.codeExpiresAt)) {
      return res.status(400).json({ message: "Attendance code has expired" })
    }

    if (participant.attended) {
      return res.status(400).json({ message: "Attendance already verified" })
    }

    // Mark attendance
    participant.attended = true
    participant.attendanceVerifiedAt = new Date()

    await event.save()

    // Get user details for response
    const user = await mongoose.model('User').findById(participant.user)
      .select('name email')

    res.json({
      message: "Attendance verified successfully",
      user: {
        name: user.name,
        email: user.email
      },
      verifiedAt: participant.attendanceVerifiedAt
    })
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

// Get attendance statistics for an event
exports.getAttendanceStats = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)

    if (!event) {
      return res.status(404).json({ message: "Event not found" })
    }

    // Check if user is organizer
    if (event.organizer.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: "Not authorized to view attendance stats" })
    }

    const totalParticipants = event.participants.length
    const attendedParticipants = event.participants.filter(p => p.attended).length
    const attendanceRate = totalParticipants > 0 ? (attendedParticipants / totalParticipants) * 100 : 0

    res.json({
      totalParticipants,
      attendedParticipants,
      attendanceRate: attendanceRate.toFixed(2),
      participants: event.participants.map(p => ({
        user: p.user,
        attended: p.attended,
        attendanceVerifiedAt: p.attendanceVerifiedAt
      }))
    })
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

