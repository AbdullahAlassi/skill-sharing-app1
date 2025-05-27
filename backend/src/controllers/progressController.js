const { validationResult } = require("express-validator")
const Progress = require("../models/Progress")
const Skill = require("../models/Skill")
const mongoose = require('mongoose')
const LearningGoal = require("../models/LearningGoal")
const Notification = require("../models/Notification")
const Resource = require("../models/Resource")

// @route   GET /api/progress
// @desc    Get all progress for current user
// @access  Private
exports.getUserProgress = async (req, res) => {
  try {
    // Get all progress for the current user
    const progress = await Progress.find({ user: req.user.id })
      .populate('skill', 'name category')
      .populate('resourcesCompleted.resource', 'title type')
      .populate('learningPathProgress.subskillId', 'name');

    if (!progress || progress.length === 0) {
      return res.status(404).json({ message: 'No progress found' });
    }

    // Calculate total progress
    const totalProgress = progress.reduce((acc, curr) => acc + (curr.progress || 0), 0) / progress.length;

    // Format the response
    const response = {
      totalProgress,
      skillProgress: progress.map(p => ({
        skillId: p.skill._id,
        skillName: p.skill.name,
        difficultyLevel: p.skill.difficultyLevel || 'beginner',
        completionPercentage: p.progress || 0,
        practiceTimeMinutes: p.practiceHours * 60 || 0,
        completedResources: p.resourcesCompleted?.length || 0,
        assessmentScore: p.assessmentScores?.length > 0 
          ? p.assessmentScores.reduce((acc, curr) => acc + curr.score, 0) / p.assessmentScores.length 
          : null
      })),
      completedResources: progress.flatMap(p => 
        p.resourcesCompleted?.map(rc => ({
          ...rc.resource.toObject(),
          completedAt: rc.completedAt
        })) || []
      ),
      practiceHistory: progress.flatMap(p => 
        p.practiceHistory?.map(ph => ({
          date: ph.date,
          minutes: ph.minutes
        })) || []
      )
    };

    res.json(response);
  } catch (error) {
    console.error('Error in getUserProgress:', error);
    res.status(500).json({ message: 'Server error' });
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

    res.json({
      success: true,
      data: progress,
      message: "Progress retrieved successfully"
    });
  } catch (err) {
    console.error("Get progress error:", err.message)
    res.status(500).json({ success: false, message: "Server error" })
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

// Mark a learning resource as completed
exports.completeResource = async (req, res) => {
  try {
    const { skillId } = req.params;
    const { resourceId } = req.body;
    const userId = req.user.id;

    console.log('[DEBUG] Marking resource as completed:', { userId, skillId, resourceId });

    if (!mongoose.Types.ObjectId.isValid(resourceId)) {
      return res.status(400).json({ message: 'Invalid resource ID' });
    }

    // Get the skill to find its creator
    const skill = await Skill.findById(skillId);
    if (!skill) {
      return res.status(404).json({ message: 'Skill not found' });
    }

    // Get the resource to check completions
    const resource = await Resource.findById(resourceId);
    if (!resource) {
      return res.status(404).json({ message: 'Resource not found' });
    }

    // Handle legacy completions field (migration)
    if (typeof resource.completions === 'number') {
      console.log('[DEBUG] Migrating legacy completions field for resource:', resourceId);
      resource.completions = [];
      await resource.save();
    }

    // Ensure completions is an array
    if (!Array.isArray(resource.completions)) {
      console.log('[DEBUG] Initializing completions array for resource:', resourceId);
      resource.completions = [];
    }

    // Check if user has already completed this resource
    const alreadyCompleted = resource.completions.some(
      (entry) => entry.user?.toString() === userId
    );
    if (alreadyCompleted) {
      console.log('[DEBUG] Resource already completed by user:', userId);
      return res.status(400).json({ message: 'Already marked as completed' });
    }

    // Add completion to resource
    resource.completions.push({
      user: userId,
      completedAt: new Date()
    });
    await resource.save();
    console.log('[DEBUG] Resource completions count:', resource.completions.length);

    // Calculate progress based on total resources
    const totalResources = await Resource.countDocuments({ skill: skillId });
    console.log('[DEBUG] Total resources for skill:', totalResources);

    const completedResources = await Resource.countDocuments({
      skill: skillId,
      completions: { $elemMatch: { user: userId } }
    });
    console.log('[DEBUG] Completed resources for user:', completedResources);

    // Calculate progress percentage, ensuring it doesn't exceed 100%
    const progress = Math.min((completedResources / totalResources) * 100, 100);
    console.log('[DEBUG] Calculated progress before goal update:', progress);

    // Update progress
    const progressDoc = await Progress.findOneAndUpdate(
      { user: userId, skill: skillId },
      {
        $push: {
          resourcesCompleted: {
            resource: resourceId,
            completedAt: new Date()
          }
        },
        $set: { progress: progress }
      },
      { new: true, upsert: true }
    );

    // Update learning goal
    const goal = await LearningGoal.findOneAndUpdate(
      { user: userId, skill: skillId },
      {
        $set: { 
          currentProgress: progress,
          status: progress >= 100 ? 'completed' : 'in_progress',
          achievedAt: progress >= 100 ? new Date() : undefined
        }
      },
      { new: true }
    );

    console.log('[DEBUG] Goal after update:', goal);

    // Create notification for the user who completed the resource
    const userNotification = new Notification({
      user: userId,
      title: 'Resource Completed',
      message: `You've completed a resource in ${skill.name}. Your progress is now ${progress.toFixed(1)}%`,
      type: 'skill',
      read: false
    });
    await userNotification.save();

    // Create notification for the skill creator if different from the user
    if (skill.createdBy.toString() !== userId) {
      const creatorNotification = new Notification({
        user: skill.createdBy,
        title: 'Resource Completion',
        message: `A user has completed a resource in your skill "${skill.name}"`,
        type: 'skill',
        read: false
      });
      await creatorNotification.save();
    }

    res.json({
      progress: progressDoc,
      goal,
      message: 'Resource marked as completed successfully'
    });
  } catch (error) {
    console.error('[DEBUG] Error in completeResource:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Add practice time
exports.addPracticeTime = async (req, res) => {
  try {
    const { skillId } = req.params;
    const { minutes } = req.body;
    const userId = req.user.id;

    if (!minutes || minutes <= 0) {
      return res.status(400).json({ message: 'Invalid practice time' });
    }

    const progress = await Progress.findOneAndUpdate(
      { user: userId, skill: skillId },
      {
        $inc: { 
          practiceHours: minutes,
          progress: Math.min(5, Math.floor(minutes / 60)) // Increment progress based on hours practiced
        }
      },
      { new: true, upsert: true }
    );

    res.json(progress);
  } catch (error) {
    console.error('Error in addPracticeTime:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Submit assessment score
exports.submitAssessment = async (req, res) => {
  try {
    const { skillId } = req.params;
    const { quizId, score } = req.body;
    const userId = req.user.id;

    if (!mongoose.Types.ObjectId.isValid(quizId)) {
      return res.status(400).json({ message: 'Invalid quiz ID' });
    }

    if (score < 0 || score > 100) {
      return res.status(400).json({ message: 'Invalid score' });
    }

    const progress = await Progress.findOneAndUpdate(
      { user: userId, skill: skillId },
      {
        $push: {
          assessmentScores: {
            quizId,
            score,
            date: new Date()
          }
        },
        $inc: { progress: Math.min(10, Math.floor(score / 10)) } // Increment progress based on score
      },
      { new: true, upsert: true }
    );

    res.json(progress);
  } catch (error) {
    console.error('Error in submitAssessment:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Update learning path progress
exports.updateLearningPath = async (req, res) => {
  try {
    const { skillId } = req.params;
    const { subskillId, completed } = req.body;
    const userId = req.user.id;

    if (!mongoose.Types.ObjectId.isValid(subskillId)) {
      return res.status(400).json({ message: 'Invalid subskill ID' });
    }

    const progress = await Progress.findOneAndUpdate(
      { user: userId, skill: skillId },
      {
        $set: {
          'learningPathProgress.$[elem].completed': completed,
          'learningPathProgress.$[elem].completedAt': completed ? new Date() : null
        }
      },
      {
        arrayFilters: [{ 'elem.subskillId': subskillId }],
        new: true,
        upsert: true
      }
    );

    res.json(progress);
  } catch (error) {
    console.error('Error in updateLearningPath:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Unmark a resource as completed
exports.unmarkResourceComplete = async (req, res) => {
  const { skillId, resourceId } = req.params;
  const userId = req.user.id;

  try {
    const resource = await Resource.findById(resourceId);
    if (!resource) return res.status(404).json({ message: 'Resource not found' });

    const userObjectId = new mongoose.Types.ObjectId(userId);

    // Remove the user's completion from the resource
    resource.completions = resource.completions.filter(
      (entry) => !entry.user.equals(userObjectId)
    );

    await resource.save();

    console.log('[DEBUG] Remaining completions after filter:', resource.completions.length);

    // Calculate progress based on total resources
    const totalResources = await Resource.countDocuments({ skill: skillId });
    console.log('[DEBUG] Total resources for skill:', totalResources);

    const completedResources = await Resource.countDocuments({
      skill: skillId,
      completions: { $elemMatch: { user: userId } }
    });
    console.log('[DEBUG] Completed resources for user:', completedResources);

    // Calculate progress percentage, ensuring it doesn't exceed 100%
    const progress = Math.min((completedResources / totalResources) * 100, 100);
    console.log('[DEBUG] Calculated progress before goal update:', progress);

    // Find and update the progress document
    const progressDoc = await Progress.findOneAndUpdate(
      { user: userId, skill: skillId },
      {
        $pull: {
          resourcesCompleted: { resource: resourceId }
        },
        $set: { progress: progress }
      },
      { new: true }
    );

    if (!progressDoc) {
      console.log('[DEBUG] Progress not found for user:', userId);
      return res.status(404).json({ 
        success: false,
        message: 'Progress not found for user.' 
      });
    }

    // Update learning goal if exists
    const goal = await LearningGoal.findOneAndUpdate(
      { user: userId, skill: skillId },
      {
        $set: { 
          currentProgress: progress,
          status: progress >= 100 ? 'completed' : 'in_progress',
          achievedAt: progress >= 100 ? new Date() : undefined
        }
      },
      { new: true }
    );

    console.log('[DEBUG] Goal after update:', goal);

    return res.status(200).json({ 
      success: true, 
      message: 'Completion removed',
      progress: progressDoc,
      goal
    });
  } catch (err) {
    console.error('[ERROR] Failed to unmark resource completion:', err);
    return res.status(500).json({ success: false, error: 'Server error' });
  }
};

// Update learning goal
exports.updateGoal = async (req, res) => {
  try {
    const { goalId } = req.params;
    const { currentProgress } = req.body;
    const userId = req.user.id;

    if (!goalId || currentProgress === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Goal ID and current progress are required'
      });
    }

    // Find and update the goal
    const goal = await LearningGoal.findOneAndUpdate(
      { _id: goalId, user: userId },
      {
        $set: {
          currentProgress: Math.min(currentProgress, 100),
          status: currentProgress >= 100 ? 'completed' : 'in_progress',
          achievedAt: currentProgress >= 100 ? new Date() : undefined
        }
      },
      { new: true }
    );

    if (!goal) {
      return res.status(404).json({
        success: false,
        message: 'Goal not found'
      });
    }

    return res.status(200).json({
      success: true,
      data: goal,
      message: 'Goal updated successfully'
    });
  } catch (error) {
    console.error('[ERROR] Failed to update goal:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// Get skill progress for current user
exports.getSkillProgress = async (req, res) => {
  try {
    const { skillId } = req.params;
    const userId = req.user.id;

    console.log('[DEBUG] Getting skill progress:', { userId, skillId });

    // Get total resources count
    const totalResources = await Resource.countDocuments({ skill: skillId });
    console.log('[DEBUG] Total resources:', totalResources);

    // Get completed resources count
    const completedResources = await Resource.countDocuments({
      skill: skillId,
      completions: { $elemMatch: { user: userId } }
    });
    console.log('[DEBUG] Completed resources:', completedResources);

    // Calculate completion percentage
    const completionPercentage = totalResources === 0 ? 0 : Math.round((completedResources / totalResources) * 100);
    console.log('[DEBUG] Completion percentage:', completionPercentage);

    // Get practice time
    const progress = await Progress.findOne({ user: userId, skill: skillId });
    const practiceTimeMinutes = progress?.practiceHours ? progress.practiceHours * 60 : 0;

    // Get assessment scores if any
    const assessmentScore = progress?.assessmentScores?.length > 0
      ? progress.assessmentScores.reduce((acc, curr) => acc + curr.score, 0) / progress.assessmentScores.length
      : null;

    // Always return a consistent response structure
    return res.status(200).json({
      success: true,
      data: {
        skillId,
        completionPercentage,
        completedResources,
        totalResources,
        practiceTimeMinutes,
        assessmentScore,
        lastUpdated: progress?.updatedAt || new Date()
      }
    });
  } catch (err) {
    console.error('[ERROR] getSkillProgress:', err);
    // Return a consistent error response structure
    return res.status(500).json({
      success: false,
      data: {
        skillId: req.params.skillId,
        completionPercentage: 0,
        completedResources: 0,
        totalResources: 0,
        practiceTimeMinutes: 0,
        assessmentScore: null,
        lastUpdated: new Date()
      },
      message: 'Failed to get skill progress',
      error: err.message
    });
  }
};

