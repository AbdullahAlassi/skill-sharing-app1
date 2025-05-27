const { validationResult } = require('express-validator');
const SkillReview = require('../models/SkillReview');
const Skill = require('../models/Skill');
const Notification = require('../models/Notification');

// @route   POST /api/skills/:skillId/reviews
// @desc    Add a review to a skill
// @access  Private
exports.addReview = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { rating, comment } = req.body;
    const skillId = req.params.skillId;
    const userId = req.user.id;

    // Check if skill exists
    const skill = await Skill.findById(skillId);
    if (!skill) {
      return res.status(404).json({ message: 'Skill not found' });
    }

    // Check if user has already reviewed this skill
    const existingReview = await SkillReview.findOne({ skill: skillId, user: userId });
    if (existingReview) {
      return res.status(400).json({ message: 'You have already reviewed this skill.' });
    }

    // Create review
    const review = new SkillReview({
      skill: skillId,
      user: userId,
      rating,
      comment
    });

    await review.save();

    // Create notification for skill creator
    if (skill.createdBy.toString() !== userId) {
      const notification = new Notification({
        user: skill.createdBy,
        title: 'New Skill Review',
        message: `${req.user.name} has reviewed your skill "${skill.name}"`,
        type: 'skill_review',
        read: false
      });
      await notification.save();
    }

    // Populate user details
    await review.populate('user', 'name');

    res.status(201).json(review);
  } catch (error) {
    console.error('Error in addReview:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @route   GET /api/skills/:skillId/reviews
// @desc    Get all reviews for a skill
// @access  Public
exports.getReviews = async (req, res) => {
  console.log('=== Backend: GET /api/skills/:skillId/reviews ===');
  console.log('Fetching reviews for skill ID:', req.params.skillId);
  try {
    const skillId = req.params.skillId;
    const reviews = await SkillReview.find({ skill: skillId })
      .populate('user', 'name')
      .sort({ createdAt: -1 });

    res.json(reviews);
  } catch (error) {
    console.error('Error in getReviews:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @route   PUT /api/skills/:skillId/reviews/:reviewId
// @desc    Update a review
// @access  Private
exports.updateReview = async (req, res) => {
  console.log('=== Backend: PUT /api/skills/:skillId/reviews/:reviewId ===');
  console.log('Updating review ID:', req.params.reviewId);
  console.log('Skill ID:', req.params.skillId);
  console.log('User ID:', req.user.id);
  console.log('Request Body:', req.body);

  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    console.log('Validation Errors:', errors.array());
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { rating, comment } = req.body;
    const reviewId = req.params.reviewId;
    const userId = req.user.id;

    console.log('Finding review...');
    const review = await SkillReview.findById(reviewId);
    if (!review) {
      console.log('Review not found');
      return res.status(404).json({ message: 'Review not found' });
    }
    console.log('Review found:', review);

    // Check if user owns the review
    console.log('Checking review ownership...');
    if (review.user.toString() !== userId) {
      console.log('Not authorized to update this review');
      return res.status(403).json({ message: 'Not authorized' });
    }
    console.log('User owns the review');

    review.rating = rating;
    review.comment = comment;
    review.updatedAt = Date.now();
    console.log('Review updated in memory:', review);

    console.log('Saving review...');
    await review.save();
    console.log('Review saved successfully');

    res.json(review);
  } catch (error) {
    console.error('Error in updateReview:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({ message: 'Server error' });
  }
};

// @route   DELETE /api/skills/:skillId/reviews/:reviewId
// @desc    Delete a review
// @access  Private
exports.deleteReview = async (req, res) => {
  console.log('=== Backend: DELETE /api/skills/:skillId/reviews/:reviewId ===');
  console.log('Deleting review ID:', req.params.reviewId);
  console.log('Skill ID:', req.params.skillId);
  console.log('User ID:', req.user.id);

  try {
    const reviewId = req.params.reviewId;
    const userId = req.user.id;

    console.log('Finding review for deletion...');
    const review = await SkillReview.findById(reviewId);
    if (!review) {
      console.log('Review not found for deletion');
      return res.status(404).json({ message: 'Review not found' });
    }
    console.log('Review found for deletion:', review);

    // Check if user owns the review
    console.log('Checking review ownership for deletion...');
    if (review.user.toString() !== userId) {
      console.log('Not authorized to delete this review');
      return res.status(403).json({ message: 'Not authorized' });
    }
    console.log('User owns the review for deletion');

    console.log('Removing review...');
    await review.deleteOne();
    console.log('Review removed successfully');

    res.json({ message: 'Review removed' });
  } catch (error) {
    console.error('Error in deleteReview:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({ message: 'Server error' });
  }
}; 