const { validationResult } = require("express-validator")
const Skill = require("../models/Skill")
const User = require("../models/User")
const SkillCategory = require('../models/skillCategory');
const NotificationService = require('../services/notificationService')
const mongoose = require('mongoose');

// @route   GET /api/skills
// @desc    Get all skills
// @access  Public
exports.getSkills = async (req, res) => {
  try {
    const skills = await Skill.find()
      .populate('createdBy', 'name profilePicture')
      .populate('relatedSkills', 'name category');
    res.json(skills);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
}

// @route   GET /api/skills/search
// @desc    Search skills with filters
// @access  Public
exports.searchSkills = async (req, res) => {
  try {
    const { query, category, level } = req.query
    const searchQuery = {}

    if (query) {
      searchQuery.$or = [
        { name: { $regex: query, $options: 'i' } },
        { description: { $regex: query, $options: 'i' } }
      ]
    }

    if (category) {
      searchQuery.category = category
    }

    if (level) {
      searchQuery.proficiency = level
    }

    const skills = await Skill.find(searchQuery)
      .sort({ name: 1 })
      .limit(50)

    res.json(skills)
  } catch (error) {
    console.error('Error searching skills:', error)
    res.status(500).json({ message: 'Failed to search skills' })
  }
}

// @route   GET /api/skills/:id
// @desc    Get skill by ID
// @access  Public
exports.getSkillById = async (req, res) => {
  console.log('[DEBUG] Entering getSkillById function for skill ID:', req.params.id);
  try {
    console.log('[DEBUG] Finding skill in database...');
    const skill = await Skill.findById(req.params.id)
      .populate("relatedSkills", "name category description")
      .populate("createdBy", "_id name profilePicture")
      .populate("resources", "name description category")
      .lean();

    console.log('[DEBUG] Skill object after population and lean():', skill);
    console.log('[DEBUG] Skill createdBy after population:', skill?.createdBy);
    console.log('[DEBUG] Skill resources after population:', skill?.resources);

    if (!skill) {
      console.log('[DEBUG] Skill not found with ID:', req.params.id);
      return res.status(404).json({ message: "Skill not found" });
    }

    console.log('[DEBUG] Successfully retrieved skill:', skill.name);
    res.json(skill);
  } catch (err) {
    console.error("[DEBUG] Get skill error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
}

// @route   POST /api/skills
// @desc    Create a new skill
// @access  Private
exports.createSkill = async (req, res) => {
  console.log('\n=== Starting Skill Creation ===');
  console.log('Request body:', req.body);
  console.log('User ID:', req.user.id);

  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    console.log('Validation errors:', errors.array());
    return res.status(400).json({ errors: errors.array() })
  }

  // Support both old and new category formats
  let { name, description, categoryId, category, difficultyLevel, relatedSkills } = req.body;
  
  // If categoryId is not provided, try to extract from category object
  if (!categoryId && category) {
    if (typeof category === 'string') {
      categoryId = category;
    } else if (typeof category === 'object' && category._id) {
      categoryId = category._id;
    }
  }

  console.log('Creating skill with category:', category, 'categoryId:', categoryId);

  try {
    // Fetch the category
    const categoryDoc = await SkillCategory.findById(categoryId);
    if (!categoryDoc) {
      console.log('Category not found:', categoryId);
      return res.status(404).json({ message: "Category not found" });
    }
    console.log('Fetched category:', categoryDoc.name);

    // Create new skill with embedded category object
    console.log('Creating new skill...');
    const skill = new Skill({
      name,
      description,
      category: {
        _id: categoryDoc._id,
        name: categoryDoc.name
      },
      difficultyLevel,
      relatedSkills,
      createdBy: req.user.id,
    })

    console.log('Saving skill...');
    await skill.save()
    console.log('Skill saved with ID:', skill._id);

    // Update skill count for the category
    await categoryDoc.updateSkillCount();
    console.log(`Updated skill count for category ${categoryDoc.name}`);

    // Add skill to user's createdSkills array
    console.log('Updating user\'s createdSkills array...');
    const user = await User.findById(req.user.id);
    if (!user) {
      console.error('User not found:', req.user.id);
      return res.status(404).json({ message: "User not found" });
    }

    // Check if skill is already in createdSkills
    if (!user.createdSkills.includes(skill._id)) {
      user.createdSkills.push(skill._id);
      await user.save();
      console.log('[DEBUG] User createdSkills after update:', user.createdSkills);
    } else {
      console.log('[DEBUG] Skill already in user\'s createdSkills');
    }

    // Verify the update
    const updatedUser = await User.findById(req.user.id)
      .select('createdSkills')
      .populate('createdSkills', '_id')
      .lean();
    console.log('[DEBUG] User createdSkills after verification:', updatedUser.createdSkills);

    // Notify users with related skills
    if (relatedSkills && relatedSkills.length > 0) {
      await NotificationService.notifyUsersWithSkills(relatedSkills, {
        title: 'New Related Skill Available',
        message: `${name} has been added to the platform. It might interest you based on your skills.`,
        type: 'skill',
        referenceId: skill._id,
        referenceType: 'Skill'
      });
    }

    // Create notification for the creator
    await NotificationService.createNotification({
      user: req.user.id,
      title: 'Skill Created Successfully',
      message: `You've successfully created the skill: ${name}`,
      type: 'skill',
      referenceId: skill._id,
      referenceType: 'Skill'
    });

    // Populate the skill with related skills and creator info
    console.log('Populating related skills and createdBy...');
    await skill.populate("relatedSkills", "name category description");
    await skill.populate("createdBy", "name");
    console.log('Skill populated successfully');

    console.log('=== Skill Creation Completed ===\n');
    res.status(201).json(skill)
  } catch (err) {
    console.error('Error in createSkill:', err);
    console.log('=== Skill Creation Failed ===\n');
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

  const { name, description, categoryId, difficultyLevel, relatedSkills } = req.body
  const skillId = req.params.id

  try {
    const skill = await Skill.findById(skillId)

    if (!skill) {
      return res.status(404).json({ message: "Skill not found" })
    }

    // If category is being updated, fetch the new category
    if (categoryId) {
      const category = await SkillCategory.findById(categoryId);
      if (!category) {
        console.log('New category not found:', categoryId);
        return res.status(404).json({ message: "New category not found" });
      }
      skill.category = {
        id: category._id,
        name: category.name
      };
       console.log('Category updated to:', skill.category.name);
    }

    // Update fields
    if (name) skill.name = name
    if (description) skill.description = description
    if (relatedSkills) skill.relatedSkills = relatedSkills
    if (difficultyLevel) skill.difficultyLevel = difficultyLevel

    // Update skill counts if the category changed
    const oldCategoryId = skill.category ? skill.category.id : null;
    if (oldCategoryId) {
       const oldCategoryObj = await SkillCategory.findById(oldCategoryId);
       if (oldCategoryObj) {
         await oldCategoryObj.updateSkillCount();
         console.log(`Updated skill count for old category ${oldCategoryObj.name}`);
       }
    }
    // Increase count for the new category
     await skill.category.updateSkillCount();
     console.log(`Updated skill count for new category ${skill.category.name}`);

    await skill.save()
    console.log('Skill updated with ID:', skill._id);

    res.json(skill)
  } catch (err) {
    console.error("Update skill error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   DELETE /api/skills/:id
// @desc    Delete a skill
// @access  Private
exports.deleteSkill = async (req, res) => {
  try {
    const skill = await Skill.findById(req.params.id)
    if (!skill) {
      return res.status(404).json({ message: "Skill not found" })
    }

    // Check if user is the creator of the skill
    if (skill.createdBy.toString() !== req.user.id) {
      return res.status(401).json({ message: "Not authorized to delete this skill" })
    }

    // Store the category ID before deleting
    const categoryId = skill.category ? skill.category.id : null;

    await skill.remove()

    // Update skill count for the category
    const categoryObj = await SkillCategory.findById(categoryId);
    if (categoryObj) {
      await categoryObj.updateSkillCount();
      console.log(`Updated skill count for category ${categoryObj.name} after skill deletion.`);
    }

    res.json({ message: "Skill deleted successfully" })
  } catch (err) {
    console.error("Delete skill error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   GET /api/skills/categories
// @desc    Get all skill categories
// @access  Public
exports.getCategories = async (req, res) => {
  try {
    const categories = await SkillCategory.find();
    res.json(categories);
  } catch (err) {
    console.error("Get categories error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
}

// @route   GET /api/skills/category/:categoryName
// @desc    Get skills by category
// @access  Public
exports.getSkillsByCategory = async (req, res) => {
  try {
    const categoryId = req.params.categoryName; // actually an ID
    console.log('[DEBUG] Fetching skills for category ID:', categoryId);

    if (!mongoose.Types.ObjectId.isValid(categoryId)) {
      return res.status(400).json({ message: "Invalid category ID" });
    }

    const skills = await Skill.find({ 'category._id': categoryId })
      .select('name category description proficiency difficultyLevel createdBy createdAt')
      .sort({ name: 1 });

    console.log('[DEBUG] Found skills in category:', skills.length);
    res.json(skills);
  } catch (err) {
    console.error("Get skills by category error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
}

// @route   GET /api/skills/recommendations
// @desc    Get skill recommendations for user
// @access  Private
exports.getRecommendations = async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .populate("skills.skill")
      .populate("favoriteCategories");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    let recommendations = [];
    let recommendationReason = "Based on your current skills";

    // Get skills created by the user to exclude them
    const userCreatedSkills = await Skill.find({ createdBy: req.user.id }).select('_id');
    const userCreatedSkillIds = userCreatedSkills.map(s => s._id);

    // Option 1: Recommend based on user's current skills
    if (user.skills && user.skills.length > 0) {
      const userSkillIds = user.skills
        .filter(s => s.skill)
        .map(s => s.skill._id);

      const userCategories = user.skills
        .filter(s => s.skill && s.skill.category)
        .map(s => s.skill.category.name);

      // Get skills in the same categories but not already learned or created by user
      recommendations = await Skill.find({
        _id: { $nin: [...userSkillIds, ...userCreatedSkillIds] },
        'category.name': { $in: userCategories },
      })
      .sort({ popularity: -1, createdAt: -1 })
      .limit(10);

      // If not enough recommendations, get related skills
      if (recommendations.length < 5) {
        const userSkills = user.skills
          .filter(s => s.skill)
          .map(s => s.skill);

        const relatedSkillIds = userSkills
          .flatMap(s => s.relatedSkills || [])
          .filter(id => !userSkillIds.includes(id) && !userCreatedSkillIds.includes(id));

        if (relatedSkillIds.length > 0) {
          const additional = await Skill.find({
            _id: { $in: relatedSkillIds },
            _id: { $nin: recommendations.map(r => r._id) }
          })
          .sort({ popularity: -1 })
          .limit(5);

          recommendations.push(...additional);
          recommendationReason = "Based on your skills and related skills";
        }
      }
    }

    // Option 2: Recommend based on favorite categories
    if (recommendations.length < 5 && user.favoriteCategories?.length > 0) {
      const additional = await Skill.find({
        'category.name': { $in: user.favoriteCategories },
        _id: { $nin: [...recommendations.map(r => r._id), ...userCreatedSkillIds] }
      })
      .sort({ popularity: -1, createdAt: -1 })
      .limit(5);

      recommendations.push(...additional);
      recommendationReason = "Based on your favorite categories";
    }

    // Option 3: Fallback to popular skills
    if (recommendations.length === 0) {
      recommendations = await Skill.find({
        _id: { $nin: userCreatedSkillIds }
      })
        .sort({ popularity: -1, createdAt: -1 })
        .limit(10);
      recommendationReason = "Popular skills in the community";
    }

    // Add recommendation reason to each skill
    recommendations = recommendations.map(skill => ({
      ...skill.toObject(),
      recommendationReason
    }));

    res.json({
      recommendations,
      total: recommendations.length,
      reason: recommendationReason
    });
  } catch (err) {
    console.error("Recommendation error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// @route   GET /api/skills/my
// @desc    Get all skills created by the current user
// @access  Private
exports.getSkillsByCreator = async (req, res) => {
  try {
    console.log('Fetching skills created by user:', req.user.id);
    const { category } = req.query; // Get category from query parameters
    
    const filter = { createdBy: req.user.id };
    if (category) {
      filter.category = category; // Add category to filter if provided
    }

    const skills = await Skill.find(filter)
      .populate("relatedSkills", "name category description")
      .sort({ createdAt: -1 });
    
    console.log('Found skills:', skills.length);
    res.json(skills);
  } catch (err) {
    console.error("Get skills by creator error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
};

// @route   GET /api/skills/:id/roadmap
// @desc    Get skill roadmap
// @access  Public
exports.getSkillRoadmap = async (req, res) => {
  try {
    const skill = await Skill.findById(req.params.id)
      .populate({
        path: 'roadmap.subskillId',
        select: 'name description proficiency category',
        populate: {
          path: 'roadmap.subskillId',
          select: 'name description proficiency category'
        }
      });

    if (!skill) {
      return res.status(404).json({ message: 'Skill not found' });
    }

    // Transform the data to include completion status if user is authenticated
    const roadmap = skill.roadmap.map(item => ({
      subskill: {
        _id: item.subskillId._id,
        name: item.subskillId.name,
        description: item.subskillId.description,
        proficiency: item.subskillId.proficiency,
        category: item.subskillId.category,
        roadmap: item.subskillId.roadmap
      },
      description: item.description,
      required: item.required,
      order: item.order
    }));

    res.json({
      skillId: skill._id,
      name: skill.name,
      roadmap: roadmap
    });
  } catch (error) {
    console.error('Error getting skill roadmap:', error);
    res.status(500).json({ message: 'Failed to get skill roadmap' });
  }
};

