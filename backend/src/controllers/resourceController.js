const { validationResult } = require("express-validator")
const Resource = require("../models/Resource")
const Skill = require("../models/Skill")
const path = require("path")
const fs = require("fs")
const User = require("../models/User")

// Helper function to delete file
const deleteFile = (filePath) => {
  try {
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath)
    }
  } catch (err) {
    console.error("Error deleting file:", err)
  }
}

// @route   GET /api/resources
// @desc    Get all resources with optional filtering and sorting
// @access  Public
exports.getResources = async (req, res) => {
  try {
    const { type, category, tags, visibility, page = 1, limit = 10 } = req.query;
    let query = {};
    let sortOption = { createdAt: -1 }; // Default sort by recent

    // Build query based on filters
    if (type) query.type = type;
    if (category) query.category = category;
    if (tags) query.tags = { $in: tags.split(',') };
    if (visibility) query.visibility = visibility;

    // Calculate pagination
    const skip = (page - 1) * limit;

    const resources = await Resource.find(query)
      .populate("skill", "name category")
      .populate("addedBy", "name")
      .sort(sortOption)
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Resource.countDocuments(query);

    res.json({
      resources,
      currentPage: page,
      totalPages: Math.ceil(total / limit),
      totalResources: total
    });
  } catch (err) {
    console.error("Get resources error:", err.message);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

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
      return res.status(404).json({ success: false, message: "Resource not found" })
    }

    res.json({
      success: true,
      data: resource
    });
  } catch (err) {
    console.error("Get resource error:", err.message)
    res.status(500).json({ success: false, message: "Server error" })
  }
}

// @route   POST /api/resources
// @desc    Create a new resource
// @access  Private
exports.createResource = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() })
  }

  const { title, description, link, type, skill, category } = req.body

  try {
    // Check if skill exists
    const skillDoc = await Skill.findById(skill)
    if (!skillDoc) {
      return res.status(404).json({ success: false, message: "Skill not found" })
    }

    // Create new resource
    const resource = new Resource({
      title,
      description,
      link,
      type: type || "Article",
      skill: skill,
      category: category || "Learning",
      addedBy: req.user.id,
    })

    await resource.save()

    // Populate references before sending response
    await resource.populate("skill", "name category")
    await resource.populate("addedBy", "name")

    res.status(201).json({ success: true, data: resource })
  } catch (err) {
    console.error("Create resource error:", err.message)
    res.status(500).json({ success: false, message: "Server error" })
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
      return res.status(401).json({ success: false, message: "Not authorized to update this resource" })
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
// @desc    Delete a resource and its associated file
// @access  Private
exports.deleteResource = async (req, res) => {
  try {
    const resource = await Resource.findById(req.params.id)

    if (!resource) {
      return res.status(404).json({ message: "Resource not found" })
    }

    // Check if user is the creator of the resource
    if (resource.addedBy.toString() !== req.user.id) {
      return res.status(401).json({ success: false, message: "Not authorized to delete this resource" })
    }

    // Delete associated file if it exists
    if (resource.fileUrl) {
      const filePath = path.join(__dirname, '..', '..', resource.fileUrl)
      deleteFile(filePath)
    }

    await Resource.findByIdAndDelete(req.params.id)

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
      return res.status(400).json({ success: false, message: "Resource already reviewed" })
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

    res.status(201).json(resource.reviews[resource.reviews.length - 1])
  } catch (err) {
    console.error("Add review error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/resources/upload
// @desc    Upload a resource file
// @access  Private
exports.uploadResource = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  if (!req.file) {
    return res.status(400).json({ message: "No file uploaded" });
  }

  const { title, description, skillId } = req.body;
  const file = req.file;

  try {
    // Check if skill exists
    const skill = await Skill.findById(skillId);
    if (!skill) {
      return res.status(404).json({ message: "Skill not found" });
    }

    // Determine file type
    let fileType = null;
    let resourceType = "Other";
    const ext = path.extname(file.originalname).toLowerCase();

    if (['.jpg', '.jpeg', '.png'].includes(ext)) {
      fileType = "image";
      resourceType = "Image";
    } else if (ext === '.pdf') {
      fileType = "pdf";
      resourceType = "PDF";
    } else if (ext === '.mp4') {
      fileType = "video";
      resourceType = "Video";
    }

    // Create new resource
    const resource = new Resource({
      title,
      description,
      link: `/uploads/resources/${file.filename}`,
      type: resourceType,
      fileUrl: `/uploads/resources/${file.filename}`,
      fileType,
      skill: skillId,
      addedBy: req.user.id,
    });

    await resource.save();

    // Populate references before sending response
    await resource.populate("skill", "name category");
    await resource.populate("addedBy", "name");

    res.status(201).json({
      success: true,
      message: "Resource uploaded successfully",
      resource,
    });
  } catch (err) {
    console.error("Upload resource error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
};

// @route   PATCH /api/resources/:id/flag
// @desc    Flag a resource for moderation
// @access  Private
exports.flagResource = async (req, res) => {
  try {
    const resource = await Resource.findById(req.params.id)

    if (!resource) {
      return res.status(404).json({ message: "Resource not found" })
    }

    resource.isFlagged = true
    await resource.save()

    res.json({ message: "Resource flagged for moderation" })
  } catch (err) {
    console.error("Flag resource error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   DELETE /api/resources/:id/force
// @desc    Force delete a resource (admin only)
// @access  Private/Admin
exports.forceDeleteResource = async (req, res) => {
  try {
    // Check if user is admin
    if (!req.user.isAdmin) {
      return res.status(401).json({ message: "Not authorized to force delete resources" })
    }

    const resource = await Resource.findById(req.params.id)

    if (!resource) {
      return res.status(404).json({ message: "Resource not found" })
    }

    // Delete associated file if it exists
    if (resource.fileUrl) {
      const filePath = path.join(__dirname, '..', '..', resource.fileUrl)
      deleteFile(filePath)
    }

    await resource.remove()

    res.json({ message: "Resource force deleted" })
  } catch (err) {
    console.error("Force delete resource error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/resources/:id/view
// @desc    Increment view count for a resource
// @access  Public
exports.incrementViewCount = async (req, res) => {
  try {
    const resource = await Resource.findById(req.params.id);
    
    if (!resource) {
      return res.status(404).json({ message: "Resource not found" });
    }

    resource.views += 1;
    await resource.save();

    res.json({ views: resource.views });
  } catch (err) {
    console.error("Increment view count error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
};

// @route   POST /api/resources/:id/complete
// @desc    Mark a resource as completed
// @access  Private
exports.markAsCompleted = async (req, res) => {
  try {
    const resource = await Resource.findById(req.params.id);
    
    if (!resource) {
      return res.status(404).json({ message: "Resource not found" });
    }

    resource.completions += 1;
    await resource.save();

    res.json({ completions: resource.completions });
  } catch (err) {
    console.error("Mark as completed error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
};

// @route   GET /api/resources/recommendations
// @desc    Get recommended resources based on user's skills and interests
// @access  Private
exports.getRecommendations = async (req, res) => {
  try {
    const userId = req.user.id;
    const { limit = 10 } = req.query;

    // Get user's skills and categories from their profile
    const userSkills = await Skill.find({ users: userId }).select('category');
    const userCategories = [...new Set(userSkills.map(skill => skill.category))];

    // Find resources that match user's interests
    const recommendations = await Resource.find({
      $or: [
        { category: { $in: userCategories } },
        { skill: { $in: userSkills.map(skill => skill._id) } }
      ],
      visibility: 'public'
    })
    .populate("skill", "name category")
    .populate("addedBy", "name")
    .sort({ rating: -1, views: -1 })
    .limit(parseInt(limit));

    res.json(recommendations);
  } catch (err) {
    console.error("Get recommendations error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
};

// @route   GET /api/resources/user-skills
// @desc    Get resources for skills that the user has added to their profile
// @access  Private
exports.getResourcesByUserSkills = async (req, res) => {
  try {
    const { type, sort } = req.query;
    const userId = req.user.id;

    // Get user's skills
    const user = await User.findById(userId).populate('skills.skill');
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    // Get skill IDs from user's skills
    const skillIds = user.skills.map(skill => skill.skill._id);

    // Build query
    let query = { skill: { $in: skillIds } };
    if (type) query.type = type;

    // Build sort option
    let sortOption = { createdAt: -1 }; // Default sort by recent
    if (sort === 'rating') sortOption = { rating: -1 };
    else if (sort === 'views') sortOption = { views: -1 };

    const resources = await Resource.find(query)
      .populate("skill", "name category")
      .populate("addedBy", "name")
      .sort(sortOption);

    res.json(resources);
  } catch (err) {
    console.error("Get resources by user skills error:", err.message);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// @route   GET /api/resources/created-skills
// @desc    Get resources for skills that the user has created
// @access  Private
exports.getResourcesByCreatedSkills = async (req, res) => {
  try {
    const { type, sort } = req.query;
    const userId = req.user.id;

    // Get skills created by the user
    const createdSkills = await Skill.find({ createdBy: userId });
    if (!createdSkills) {
      return res.status(404).json({ success: false, message: "No created skills found" });
    }

    // Get skill IDs
    const skillIds = createdSkills.map(skill => skill._id);

    // Build query
    let query = { skill: { $in: skillIds } };
    if (type) query.type = type;

    // Build sort option
    let sortOption = { createdAt: -1 }; // Default sort by recent
    if (sort === 'rating') sortOption = { rating: -1 };
    else if (sort === 'views') sortOption = { views: -1 };

    const resources = await Resource.find(query)
      .populate("skill", "name category")
      .populate("addedBy", "name")
      .sort(sortOption);

    res.json(resources);
  } catch (err) {
    console.error("Get resources by created skills error:", err.message);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// @route   GET /api/resources/by-user-categories
// @desc    Get resources based on user's favorite categories
// @access  Private
exports.getResourcesByUserCategories = async (req, res) => {
  try {
    // Get user with favorite categories
    const user = await User.findById(req.user.id).select('favoriteCategories');

    console.log('[DEBUG Backend] Fetched user in getResourcesByUserCategories:', user);
    console.log('[DEBUG Backend] User favorite categories:', user?.favoriteCategories);

    // Check if user and favoriteCategories exist and favoriteCategories is a non-empty array
    if (!user || !Array.isArray(user.favoriteCategories) || user.favoriteCategories.length === 0) {
      console.log('[DEBUG Backend] No user or empty/invalid favorite categories found, returning empty.');
      return res.json({
        success: true,
        data: [],
        message: 'No favorite categories found'
      });
    }

    console.log('[DEBUG Backend] User has favorite categories:', user.favoriteCategories);

    // Find resources where the skill's category matches user's favorite categories
    const resources = await Resource.find()
      .populate({
        path: 'skill',
        match: { 'category.name': { $in: user.favoriteCategories } },
        select: 'name category'
      })
      .populate('addedBy', 'name')
      .sort({ createdAt: -1 });

    // Filter out resources where skill is null (due to no category match)
    const filteredResources = resources.filter(resource => resource.skill != null);

    // Add debug logging
    console.log('User favorite categories:', user.favoriteCategories);
    console.log('Found resources:', filteredResources.length);

    res.json({
      success: true,
      data: filteredResources,
      message: 'Resources loaded successfully'
    });
  } catch (err) {
    console.error('Get resources by user categories error:', err.message);
    res.status(500).json({
      success: false,
      error: err.message,
      message: 'Failed to load resources'
    });
  }
};

