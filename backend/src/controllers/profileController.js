const { validationResult } = require("express-validator")
const User = require("../models/User")
const Skill = require("../models/Skill")
const LearningGoal = require("../models/LearningGoal")
const Notification = require("../models/Notification")

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
  console.log('\n=== Starting Add Skill to Profile ===');
  console.log('Request body:', req.body);
  console.log('User ID:', req.user.id);

  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    console.log('Validation errors:', errors.array());
    return res.status(400).json({ errors: errors.array() })
  }

  const { skillId, proficiency } = req.body

  try {
    console.log('Finding user...');
    const user = await User.findById(req.user.id)

    if (!user) {
      console.log('User not found');
      return res.status(404).json({ message: "User not found" })
    }

    // Check if skill exists
    console.log('Checking if skill exists:', skillId);
    const skill = await Skill.findById(skillId)
    if (!skill) {
      console.log('Skill not found');
      return res.status(404).json({ message: "Skill not found" })
    }

    // Check if user already has this skill
    console.log('Checking if user already has skill...');
    const skillExists = user.skills.some((s) => s.skill.toString() === skillId)
    if (skillExists) {
      console.log('Skill already exists in user profile');
      return res.status(400).json({ message: "Skill already added to profile" })
    }

    // Add skill to user profile
    console.log('Adding skill to user profile...');
    user.skills.push({
      skill: skillId,
      proficiency: proficiency || "Beginner",
    })

    console.log('Saving user...');
    await user.save()

    // Check if a goal already exists for this skill
    console.log('Checking for existing goal...');
    const existingGoal = await LearningGoal.findOne({
      user: req.user.id,
      skill: skillId,
    })

    if (!existingGoal) {
      console.log('Creating new goal...');
      // Create a new goal with default values
      const goal = new LearningGoal({
        user: req.user.id,
        skill: skillId,
        targetDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
        currentProgress: 0,
        status: 'in_progress',
      })

      await goal.save()

      // Create notification for goal creation
      console.log('Creating goal notification...');
      const notification = new Notification({
        user: req.user.id,
        title: 'New Learning Goal Created',
        message: `A new goal has been created for ${skill.name}. Target date: ${goal.targetDate.toLocaleDateString()}`,
        type: 'goal',
        read: false,
        referenceId: goal._id,
        referenceType: 'LearningGoal'
      })
      await notification.save()
    }

    // Create notification for skill addition
    console.log('Creating skill addition notification...');
    const skillNotification = new Notification({
      user: req.user.id,
      title: 'New Skill Added',
      message: `You've added ${skill.name} to your skills list`,
      type: 'skill',
      read: false,
      referenceId: skill._id,
      referenceType: 'Skill'
    })
    await skillNotification.save()

    // Populate skill details before sending response
    console.log('Populating skill details...');
    await user.populate("skills.skill", "name category description")

    console.log('=== Add Skill to Profile Completed ===\n');
    res.json(user.skills)
  } catch (err) {
    console.error('Error in addSkill:', err);
    console.error('Error stack:', err.stack);
    console.log('=== Add Skill to Profile Failed ===\n');
    res.status(500).json({ message: "Server error" })
  }
}

// @route   DELETE /api/profile/skills/:skillId
// @desc    Remove skill from user profile
// @access  Private
exports.removeSkill = async (req, res) => {
  console.log('\n=== Starting Remove Skill from Profile ===');
  console.log('Skill ID:', req.params.skillId);
  console.log('User ID:', req.user.id);

  try {
    const user = await User.findById(req.user.id)

    if (!user) {
      console.log('User not found');
      return res.status(404).json({ message: "User not found" })
    }

    // Find the skill before removing it to get its name for the notification
    const skill = await Skill.findById(req.params.skillId);
    if (!skill) {
      console.log('Skill not found');
      return res.status(404).json({ message: "Skill not found" })
    }

    // Remove skill from user profile
    console.log('Removing skill from user profile...');
    user.skills = user.skills.filter((s) => s.skill.toString() !== req.params.skillId)
    await user.save()

    // Remove associated learning goal
    console.log('Removing associated learning goal...');
    const deletedGoal = await LearningGoal.findOneAndDelete({
      user: req.user.id,
      skill: req.params.skillId
    });

    // Create notification for skill removal
    console.log('Creating skill removal notification...');
    const notification = new Notification({
      user: req.user.id,
      title: 'Skill Removed',
      message: `You've removed ${skill.name} from your skills list`,
      type: 'skill',
      read: false,
      referenceId: skill._id,
      referenceType: 'Skill'
    });
    await notification.save();

    console.log('=== Remove Skill from Profile Completed ===\n');
    res.json(user.skills)
  } catch (err) {
    console.error('Error in removeSkill:', err);
    console.error('Error stack:', err.stack);
    console.log('=== Remove Skill from Profile Failed ===\n');
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

