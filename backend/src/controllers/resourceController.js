const { validationResult } = require("express-validator")
const Resource = require("../models/Resource")
const Skill = require("../models/Skill")

// @route   GET /api/resources
// @desc    Get all resources
// @access  Public
exports.getResources = async (req, res) => {
  try {
    const resources = await Resource.find()
      .populate("skill", "name category")
      .populate("addedBy", "name")
      .sort({ createdAt: -1 })

    res.json(resources)
  } catch (err) {
    console.error("Get resources error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   GET /api/resources/:id
// @desc    Get resource by ID
// @access  Public
exports.getResourceById = async (req, res) => {
  try {
    const resource = await Resource.findById(req.params.id)
      .populate("skill", "name category description")
      .populate("addedBy", "name")
      .populate("reviews.user", "name profilePicture")

    if (!resource) {
      return res.status(404).json({ message: "Resource not found" })
    }

    res.json(resource)
  } catch (err) {
    console.error("Get resource error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/resources
// @desc    Create a new resource
// @access  Private
exports.createResource = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { title, description, link, type, skillId } = req.body

  try {
    // Check if skill exists
    const skill = await Skill.findById(skillId)
    if (!skill) {
      return res.status(404).json({ message: "Skill not found" })
    }

    // Create new resource
    const resource = new Resource({
      title,
      description,
      link,
      type: type || "Article",
      skill: skillId,
      addedBy: req.user.id,
    })

    await resource.save()

    // Populate references before sending response
    await resource.populate("skill", "name category")
    await resource.populate("addedBy", "name")

    res.status(201).json(resource)
  } catch (err) {
    console.error("Create resource error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   PUT /api/resources/:id
// @desc    Update a resource
// @access  Private
exports.updateResource = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { title, description, link, type } = req.body

  try {
    const resource = await Resource.findById(req.params.id)

    if (!resource) {
      return res.status(404).json({ message: "Resource not found" })
    }

    // Check if user is the creator of the resource
    if (resource.addedBy.toString() !== req.user.id) {
      return res.status(401).json({ message: "Not authorized to update this resource" })
    }

    // Update fields
    if (title) resource.title = title
    if (description) resource.description = description
    if (link) resource.link = link
    if (type) resource.type = type

    await resource.save()

    res.json(resource)
  } catch (err) {
    console.error("Update resource error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   DELETE /api/resources/:id
// @desc    Delete a resource
// @access  Private
exports.deleteResource = async (req, res) => {
  try {
    const resource = await Resource.findById(req.params.id)

    if (!resource) {
      return res.status(404).json({ message: "Resource not found" })
    }

    // Check if user is the creator of the resource
    if (resource.addedBy.toString() !== req.user.id) {
      return res.status(401).json({ message: "Not authorized to delete this resource" })
    }

    await resource.remove()

    res.json({ message: "Resource removed" })
  } catch (err) {
    console.error("Delete resource error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   GET /api/resources/skill/:skillId
// @desc    Get resources by skill ID
// @access  Public
exports.getResourcesBySkill = async (req, res) => {
  try {
    const resources = await Resource.find({ skill: req.params.skillId })
      .populate("skill", "name category")
      .populate("addedBy", "name")
      .sort({ createdAt: -1 })

    res.json(resources)
  } catch (err) {
    console.error("Get resources by skill error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/resources/:id/review
// @desc    Add a review to a resource
// @access  Private
exports.addReview = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { rating, comment } = req.body

  try {
    const resource = await Resource.findById(req.params.id)

    if (!resource) {
      return res.status(404).json({ message: "Resource not found" })
    }

    // Check if user already reviewed this resource
    const alreadyReviewed = resource.reviews.some((review) => review.user.toString() === req.user.id)

    if (alreadyReviewed) {
      return res.status(400).json({ message: "Resource already reviewed" })
    }

    // Add review
    const review = {
      user: req.user.id,
      rating: Number(rating),
      comment,
    }

    resource.reviews.push(review)

    // Update overall rating
    resource.rating = resource.reviews.reduce((acc, item) => item.rating + acc, 0) / resource.reviews.length

    await resource.save()

    // Populate user details before sending response
    await resource.populate("reviews.user", "name profilePicture")

    res.status(201).json(resource.reviews)
  } catch (err) {
    console.error("Add review error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

