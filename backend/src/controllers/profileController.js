const { validationResult } = require("express-validator")
const User = require("../models/User")
const Skill = require("../models/Skill")

// @route   GET /api/profile
// @desc    Get current user's profile
// @access  Private
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .select("-password")
      .populate("skills.skill", "name category description")
      .populate("interests", "name category")
      .populate("friends", "name profilePicture")
      .populate("groups", "name description")
      .populate("createdSkills", "name category description")

    if (!user) {
      return res.status(404).json({ message: "User not found" })
    }

    res.json(user)
  } catch (err) {
    console.error("Get profile error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   PUT /api/profile
// @desc    Update user profile
// @access  Private
exports.updateProfile = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { name, bio } = req.body

  try {
    const user = await User.findById(req.user.id)

    if (!user) {
      return res.status(404).json({ message: "User not found" })
    }

    // Update fields
    if (name) user.name = name
    if (bio !== undefined) user.bio = bio

    await user.save()

    res.json(user)
  } catch (err) {
    console.error("Update profile error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/profile/skills
// @desc    Add skill to user profile
// @access  Private
exports.addSkill = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { skillId, proficiency } = req.body

  try {
    const user = await User.findById(req.user.id)

    if (!user) {
      return res.status(404).json({ message: "User not found" })
    }

    // Check if skill exists
    const skill = await Skill.findById(skillId)
    if (!skill) {
      return res.status(404).json({ message: "Skill not found" })
    }

    // Check if user already has this skill
    const skillExists = user.skills.some((s) => s.skill.toString() === skillId)
    if (skillExists) {
      return res.status(400).json({ message: "Skill already added to profile" })
    }

    // Add skill to user profile
    user.skills.push({
      skill: skillId,
      proficiency: proficiency || "Beginner",
    })

    await user.save()

    // Populate skill details before sending response
    await user.populate("skills.skill", "name category description")

    res.json(user.skills)
  } catch (err) {
    console.error("Add skill error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   DELETE /api/profile/skills/:skillId
// @desc    Remove skill from user profile
// @access  Private
exports.removeSkill = async (req, res) => {
  try {
    const user = await User.findById(req.user.id)

    if (!user) {
      return res.status(404).json({ message: "User not found" })
    }

    // Remove skill from user profile
    user.skills = user.skills.filter((s) => s.skill.toString() !== req.params.skillId)

    await user.save()

    res.json(user.skills)
  } catch (err) {
    console.error("Remove skill error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/profile/interests
// @desc    Add interest to user profile
// @access  Private
exports.addInterest = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { skillId } = req.body

  try {
    const user = await User.findById(req.user.id)

    if (!user) {
      return res.status(404).json({ message: "User not found" })
    }

    // Check if skill exists
    const skill = await Skill.findById(skillId)
    if (!skill) {
      return res.status(404).json({ message: "Skill not found" })
    }

    // Check if user already has this interest
    const interestExists = user.interests.some((i) => i.toString() === skillId)
    if (interestExists) {
      return res.status(400).json({ message: "Interest already added to profile" })
    }

    // Add interest to user profile
    user.interests.push(skillId)

    await user.save()

    // Populate interest details before sending response
    await user.populate("interests", "name category description")

    res.json(user.interests)
  } catch (err) {
    console.error("Add interest error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   DELETE /api/profile/interests/:skillId
// @desc    Remove interest from user profile
// @access  Private
exports.removeInterest = async (req, res) => {
  try {
    const user = await User.findById(req.user.id)

    if (!user) {
      return res.status(404).json({ message: "User not found" })
    }

    // Remove interest from user profile
    user.interests = user.interests.filter((i) => i.toString() !== req.params.skillId)

    await user.save()

    res.json(user.interests)
  } catch (err) {
    console.error("Remove interest error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/profile/picture
// @desc    Upload profile picture
// @access  Private
exports.uploadProfilePicture = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "No file uploaded" })
    }

    const user = await User.findById(req.user.id)

    if (!user) {
      return res.status(404).json({ message: "User not found" })
    }

    // Update profile picture
    user.profilePicture = `/uploads/${req.file.filename}`

    await user.save()

    res.json({ profilePicture: user.profilePicture })
  } catch (err) {
    console.error("Upload profile picture error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

