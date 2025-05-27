const mongoose = require("mongoose")

const ProgressSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  skill: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Skill",
    required: true,
  },
  goal: {
    type: String,
    required: true,
  },
  targetDate: {
    type: Date,
  },
  progress: {
    type: Number,
    min: 0,
    max: 100,
    default: 0,
  },
  resourcesCompleted: [{
    resource: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Resource'
    },
    completedAt: {
      type: Date,
      default: Date.now
    }
  }],
  practiceHours: {
    type: Number,
    default: 0, // in minutes
  },
  assessmentScores: [{
    quizId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Quiz'
    },
    score: Number,
    date: {
      type: Date,
      default: Date.now
    }
  }],
  learningPathProgress: [{
    subskillId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Skill'
    },
    completed: {
      type: Boolean,
      default: false
    },
    completedAt: {
      type: Date
    }
  }],
  milestones: [
    {
      title: {
        type: String,
        required: true,
      },
      description: {
        type: String,
      },
      completed: {
        type: Boolean,
        default: false,
      },
      completedAt: {
        type: Date,
      },
    },
  ],
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
})

// Index for faster querying of progress by user and skill
ProgressSchema.index({ user: 1, skill: 1 }, { unique: true });

module.exports = mongoose.model("Progress", ProgressSchema)

