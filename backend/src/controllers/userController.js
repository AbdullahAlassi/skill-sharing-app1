const User = require("../models/User");
const { validationResult } = require('express-validator');
const fs = require('fs');
const path = require('path');

// @route   GET /api/users/me
// @desc    Get current user
// @access  Private
exports.getCurrentUser = async (req, res) => {
  try {
    console.log('[DEBUG] Starting getCurrentUser for user ID:', req.user.id);

    // Get fresh user data from database with populated createdSkills and skills
    const user = await User.findById(req.user.id)
      .select('-password')
      .populate('createdSkills', '_id')
      .populate({
        path: 'skills.skill',
        select: '_id',
      })
      .lean();

    if (!user) {
      console.log('[DEBUG] User not found');
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    console.log('[DEBUG] Raw user data:', {
      createdSkills: user.createdSkills,
      skills: user.skills
    });

    // Ensure createdSkills is always a list of strings
    if (user.createdSkills && Array.isArray(user.createdSkills)) {
      user.createdSkills = user.createdSkills.map(skill => {
        if (typeof skill === 'string') return skill;
        if (typeof skill === 'object' && skill._id) return String(skill._id);
        return '';
      }).filter(Boolean);
    } else {
      user.createdSkills = [];
    }

    // Process skills array to extract IDs
    console.log('[DEBUG] Processing skills array');
    if (user.skills && Array.isArray(user.skills)) {
      console.log('[DEBUG] Raw skills array:', user.skills);
      
      user.skills = user.skills.map(entry => {
        console.log('[DEBUG] Processing skill entry:', entry);
        
        // Case 1: Direct string ID
        if (typeof entry === 'string') {
          console.log('[DEBUG] Found string ID:', entry);
          return entry;
        }
        
        // Case 2: Complex object with skill._id
        if (typeof entry === 'object' && entry.skill?._id) {
          const skillId = String(entry.skill._id);
          console.log('[DEBUG] Extracted ID from complex object:', skillId);
          return skillId;
        }
        
        console.log('[DEBUG] Invalid skill entry format:', entry);
        return null;
      }).filter(Boolean);
      
      console.log('[DEBUG] Final processed skills array:', user.skills);
    } else {
      console.log('[DEBUG] No skills array found, initializing empty array');
      user.skills = [];
    }

    console.log('[DEBUG] Final user data:', {
      createdSkills: user.createdSkills,
      skills: user.skills
    });

    return res.status(200).json({
      success: true,
      data: user
    });
  } catch (error) {
    console.error('[ERROR] Error in getCurrentUser:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user data'
    });
  }
};

// @route   GET /api/users/:id
// @desc    Get public user profile by ID
// @access  Public
exports.getPublicProfile = async (req, res) => {
  try {
    const userId = req.params.id;
    console.log('[DEBUG] Fetching public profile for user ID:', userId);

    // First, check if user exists without population
    const userExists = await User.findById(userId);
    if (!userExists) {
      console.log('[DEBUG] User not found for public profile:', userId);
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    console.log('[DEBUG] User exists, createdSkills count:', userExists.createdSkills?.length);

    // Fetch user and populate createdSkills
    const user = await User.findById(userId)
      .select('name profilePicture bio createdSkills')
      .populate({
        path: 'createdSkills',
        select: 'name category description difficultyLevel',
        options: { lean: true }
      })
      .lean();

    console.log('[DEBUG] User object after population and lean():', user);
    console.log('[DEBUG] Created skills count:', user?.createdSkills?.length);

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    console.error('Error in getPublicProfile:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Update user profile
// @route   PUT /api/users/me
// @access  Private
exports.updateProfile = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array()
    });
  }

  try {
    const { name, bio } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user.id,
      { name, bio },
      { new: true }
    ).select('-password');

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    console.error('Error in updateProfile:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Update user profile photo
// @route   PUT /api/users/me/photo
// @access  Private
exports.updateProfilePhoto = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    // Delete old photo if exists
    const user = await User.findById(req.user.id);
    if (user.photo && user.photo.startsWith('uploads/')) {
      const oldPhotoPath = path.join(process.cwd(), user.photo);
      if (fs.existsSync(oldPhotoPath)) {
        fs.unlinkSync(oldPhotoPath);
      }
    }

    // Update user with new photo path
    const updatedUser = await User.findByIdAndUpdate(
      req.user.id,
      { photo: req.file.path },
      { new: true }
    ).select('-password');

    res.json({
      success: true,
      data: updatedUser
    });
  } catch (error) {
    console.error('Error in updateProfilePhoto:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Get user skills
// @route   GET /api/users/me/skills
// @access  Private
exports.getUserSkills = async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .select('skills')
      .populate('skills.skill', 'name category description proficiency difficultyLevel');

    res.json({
      success: true,
      data: user.skills
    });
  } catch (error) {
    console.error('Error in getUserSkills:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @route   PUT /api/users/preferences
// @desc    Update user preferences (favorite categories)
// @access  Private
exports.updatePreferences = async (req, res) => {
  try {
    const { favoriteCategories } = req.body;

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { favoriteCategories },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: user.favoriteCategories
    });
  } catch (error) {
    console.error('Error in updatePreferences:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @route   GET /api/users/preferences
// @desc    Get user preferences
// @access  Private
exports.getPreferences = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('preferences');
    res.json({
      success: true,
      data: user.preferences
    });
  } catch (error) {
    console.error('Error in getPreferences:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @route   PUT /api/users/me/skills/:skillId/proficiency
// @desc    Update skill proficiency level
// @access  Private
exports.updateSkillProficiency = async (req, res) => {
  try {
    const { skillId } = req.params;
    const { level } = req.body;

    // Validate proficiency level
    if (!['Beginner', 'Intermediate', 'Advanced'].includes(level)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid proficiency level. Must be Beginner, Intermediate, or Advanced'
      });
    }

    // Find user and update skill proficiency
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Find the skill in user's skills array
    const skillIndex = user.skills.findIndex(s => s.skill.toString() === skillId);
    if (skillIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Skill not found in user profile'
      });
    }

    // Update proficiency level
    user.skills[skillIndex].proficiency = level;
    await user.save();

    res.json({
      success: true,
      data: user.skills[skillIndex]
    });
  } catch (error) {
    console.error('Error in updateSkillProficiency:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @route   PUT /api/users/me/password
// @desc    Change user password
// @access  Private
exports.changePassword = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array()
    });
  }

  try {
    const { oldPassword, newPassword } = req.body;
    const user = await User.findById(req.user.id);

    // Check if old password matches
    const isMatch = await user.comparePassword(oldPassword);
    if (!isMatch) {
      return res.status(400).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    // Update password
    user.password = newPassword;
    await user.save();

    res.json({
      success: true,
      message: 'Password updated successfully'
    });
  } catch (error) {
    console.error('Error in changePassword:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
}; 