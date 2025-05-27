const mongoose = require('mongoose');

const learningGoalSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  skill: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Skill',
    required: true
  },
  targetDate: {
    type: Date,
    required: true
  },
  currentProgress: {
    type: Number,
    required: true,
    min: 0,
    max: 100,
    default: 0
  },
  status: {
    type: String,
    enum: ['in_progress', 'completed', 'expired'],
    default: 'in_progress'
  },
  achievedAt: {
    type: Date
  }
}, {
  timestamps: true
});

// Update status based on progress and target date
learningGoalSchema.methods.updateStatus = function() {
  const now = new Date();
  
  if (this.currentProgress >= 100) {
    this.status = 'completed';
    this.achievedAt = now;
  } else if (now > this.targetDate) {
    this.status = 'expired';
  } else {
    this.status = 'in_progress';
  }
};

// Pre-save middleware to update status
learningGoalSchema.pre('save', function(next) {
  this.updateStatus();
  next();
});

const LearningGoal = mongoose.model('LearningGoal', learningGoalSchema);

module.exports = LearningGoal; 