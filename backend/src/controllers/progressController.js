const { validationResult } = require("express-validator")
const Progress = require("../models/Progress")
const Skill = require("../models/Skill")

// @route   GET /api/progress
// @desc    Get all progress for current user
// @access  Private
exports.getUserProgress = async (req, res) => {
  try {
    const progress = await Progress.find({ user: req.user.id })
      .populate("skill", "name category")
      .sort({ createdAt: -1 })

    res.json(progress)
  } catch (err) {
    console.error("Get progress error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   GET /api/progress/:id
// @desc    Get progress by ID
// @access  Private
exports.getProgressById = async (req, res) => {
  try {
    const progress = await Progress.findById(req.params.id).populate("skill", "name category description")

    if (!progress) {
      return res.status(404).json({ message: "Progress not found" })
    }

    // Check if progress belongs to current user
    if (progress.user.toString() !== req.user.id) {
      return res.status(401).json({ message: "Not authorized to view this progress" })
    }

    res.json(progress)
  } catch (err) {
    console.error("Get progress error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/progress
// @desc    Create a new progress tracking
// @access  Private
exports.createProgress = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { skillId, goal, targetDate, milestones } = req.body

  try {
    // Check if skill exists
    const skill = await Skill.findById(skillId)
    if (!skill) {
      return res.status(404).json({ message: "Skill not found" })
    }

    // Check if progress for this skill already exists
    const existingProgress = await Progress.findOne({
      user: req.user.id,
      skill: skillId,
    })

    if (existingProgress) {
      return res.status(400).json({ message: "Progress for this skill already exists" })
    }

    // Create new progress
    const progress = new Progress({
      user: req.user.id,
      skill: skillId,
      goal,
      targetDate: targetDate || null,
      milestones: milestones || [],
    })

    await progress.save()

    // Populate skill details before sending response
    await progress.populate("skill", "name category")

    res.status(201).json(progress)
  } catch (err) {
    console.error("Create progress error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   PUT /api/progress/:id
// @desc    Update progress
// @access  Private
exports.updateProgress = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { goal, targetDate, progress: progressValue } = req.body

  try {
    const progressRecord = await Progress.findById(req.params.id)

    if (!progressRecord) {
      return res.status(404).json({ message: "Progress not found" })
    }

    // Check if progress belongs to current user
    if (progressRecord.user.toString() !== req.user.id) {
      return res.status(401).json({ message: "Not authorized to update this progress" })
    }

    // Update fields
    if (goal) progressRecord.goal = goal
    if (targetDate !== undefined) progressRecord.targetDate = targetDate
    if (progressValue !== undefined) progressRecord.progress = progressValue

    // Update the updatedAt field
    progressRecord.updatedAt = Date.now()

    await progressRecord.save()

    res.json(progressRecord)
  } catch (err) {
    console.error("Update progress error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   DELETE /api/progress/:id
// @desc    Delete progress
// @access  Private
exports.deleteProgress = async (req, res) => {
  try {
    const progress = await Progress.findById(req.params.id)

    if (!progress) {
      return res.status(404).json({ message: "Progress not found" })
    }

    // Check if progress belongs to current user
    if (progress.user.toString() !== req.user.id) {
      return res.status(401).json({ message: "Not authorized to delete this progress" })
    }

    await progress.remove()

    res.json({ message: "Progress removed" })
  } catch (err) {
    console.error("Delete progress error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/progress/:id/milestone
// @desc    Add milestone to progress
// @access  Private
exports.addMilestone = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { title, description } = req.body

  try {
    const progress = await Progress.findById(req.params.id)

    if (!progress) {
      return res.status(404).json({ message: "Progress not found" })
    }

    // Check if progress belongs to current user
    if (progress.user.toString() !== req.user.id) {
      return res.status(401).json({ message: "Not authorized to update this progress" })
    }

    // Add milestone
    progress.milestones.push({
      title,
      description,
      completed: false,
    })

    // Update the updatedAt field
    progress.updatedAt = Date.now()

    await progress.save()

    res.status(201).json(progress.milestones)
  } catch (err) {
    console.error("Add milestone error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   PUT /api/progress/:id/milestone/:milestoneId
// @desc    Update milestone
// @access  Private
exports.updateMilestone = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { title, description, completed } = req.body

  try {
    const progress = await Progress.findById(req.params.id)

    if (!progress) {
      return res.status(404).json({ message: "Progress not found" })
    }

    // Check if progress belongs to current user
    if (progress.user.toString() !== req.user.id) {
      return res.status(401).json({ message: "Not authorized to update this progress" })
    }

    // Find milestone
    const milestone = progress.milestones.id(req.params.milestoneId)

    if (!milestone) {
      return res.status(404).json({ message: "Milestone not found" })
    }

    // Update milestone fields
    if (title) milestone.title = title
    if (description !== undefined) milestone.description = description
    if (completed !== undefined) {
      milestone.completed = completed
      if (completed) {
        milestone.completedAt = Date.now()
      } else {
        milestone.completedAt = undefined
      }
    }

    // Update the updatedAt field
    progress.updatedAt = Date.now()

    await progress.save()

    res.json(progress.milestones)
  } catch (err) {
    console.error("Update milestone error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

