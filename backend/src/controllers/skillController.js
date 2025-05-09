const { validationResult } = require("express-validator")
const Skill = require("../models/Skill")
const User = require("../models/User")

// @route   GET /api/skills
// @desc    Get all skills
// @access  Public
exports.getSkills = async (req, res) => {
  try {
    const skills = await Skill.find().sort({ name: 1 })
    res.json(skills)
  } catch (err) {
    console.error("Get skills error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   GET /api/skills/:id
// @desc    Get skill by ID
// @access  Public
exports.getSkillById = async (req, res) => {
  try {
    const skill = await Skill.findById(req.params.id)
      .populate("relatedSkills", "name category description")
      .populate("createdBy", "name")

    if (!skill) {
      return res.status(404).json({ message: "Skill not found" })
    }

    res.json(skill)
  } catch (err) {
    console.error("Get skill error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/skills
// @desc    Create a new skill
// @access  Private
exports.createSkill = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { name, category, description, relatedSkills, proficiency } = req.body

  try {
    // Check if skill already exists
    let skill = await Skill.findOne({ name: { $regex: new RegExp(`^${name}$`, "i") } })
    if (skill) {
      return res.status(400).json({ message: "Skill already exists" })
    }

    // Create new skill
    skill = new Skill({
      name,
      category,
      description,
      relatedSkills: relatedSkills || [],
      proficiency: proficiency || 'Beginner',
      createdBy: req.user.id,
    })

    await skill.save()

    // Add skill to user's createdSkills array
    await User.findByIdAndUpdate(
      req.user.id,
      { $push: { createdSkills: skill._id } }
    )

    // Populate the skill with related skills and creator info
    await skill.populate("relatedSkills", "name category description")
    await skill.populate("createdBy", "name")

    res.status(201).json(skill)
  } catch (err) {
    console.error("Create skill error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   PUT /api/skills/:id
// @desc    Update a skill
// @access  Private
exports.updateSkill = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { name, category, description, relatedSkills, proficiency } = req.body
  const skillId = req.params.id

  try {
    const skill = await Skill.findById(skillId)

    if (!skill) {
      return res.status(404).json({ message: "Skill not found" })
    }

    // Check if user is the creator of the skill
    if (skill.createdBy.toString() !== req.user.id) {
      return res.status(401).json({ message: "Not authorized to update this skill" })
    }

    // Update fields
    if (name) skill.name = name
    if (category) skill.category = category
    if (description) skill.description = description
    if (relatedSkills) skill.relatedSkills = relatedSkills
    if (proficiency) skill.proficiency = proficiency

    await skill.save()

    res.json(skill)
  } catch (err) {
    console.error("Update skill error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   GET /api/skills/categories
// @desc    Get all skill categories
// @access  Public
exports.getCategories = async (req, res) => {
  try {
    const categories = await Skill.distinct("category")
    res.json(categories)
  } catch (err) {
    console.error("Get categories error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   GET /api/skills/recommendations
// @desc    Get skill recommendations for user
// @access  Private
exports.getRecommendations = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).populate("skills.skill");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    let recommendations = [];

    // If user has skills, get recommendations based on their skills
    if (user.skills && user.skills.length > 0) {
      // Get user's current skill IDs, filtering out any null skill references
      const userSkillIds = user.skills
        .filter(s => s.skill && s.skill._id)
        .map(s => s.skill._id.toString());

      // Get user's skill categories, filtering out any null skill references
      const userCategories = user.skills
        .filter(s => s.skill && s.skill.category)
        .map(s => s.skill.category);

      recommendations = await Skill.find({
        _id: { $nin: userSkillIds },
        category: { $in: userCategories },
      }).limit(10);
    }
    // If user has no skills but has favorite categories, use those
    else if (user.favoriteCategories && user.favoriteCategories.length > 0) {
      recommendations = await Skill.find({
        category: { $in: user.favoriteCategories },
      }).limit(10);
    }

    // If not enough recommendations, add popular skills
    if (recommendations.length < 5) {
      const additionalSkills = await Skill.find({
        _id: { $nin: recommendations.map((r) => r._id) },
      })
        .sort({ createdAt: -1 })
        .limit(5 - recommendations.length);

      recommendations.push(...additionalSkills);
    }

    // If still no recommendations, get some default skills
    if (recommendations.length === 0) {
      recommendations = await Skill.find()
        .sort({ createdAt: -1 })
        .limit(5);
    }

    res.json(recommendations);
  } catch (err) {
    console.error("Get recommendations error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
};

