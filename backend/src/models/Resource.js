const mongoose = require("mongoose")

// Define Completion Schema
const CompletionSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  completedAt: {
    type: Date,
    default: Date.now
  }
});

const ResourceSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  link: {
    type: String,
    required: false,
  },
  type: {
    type: String,
    enum: ["Article", "Video", "Course", "Book", "Other", "Image", "PDF"],
    default: "Article",
  },
  fileUrl: {
    type: String,
  },
  fileType: {
    type: String,
    enum: ["image", "pdf", "video", null],
    default: null,
  },
  previewUrl: {
    type: String,
  },
  category: {
    type: String,
    required: true,
  },
  tags: [{
    type: String,
  }],
  visibility: {
    type: String,
    enum: ['public', 'private'],
    default: 'public'
  },
  isFlagged: {
    type: Boolean,
    default: false,
  },
  views: {
    type: Number,
    default: 0,
  },
  completions: {
    type: [CompletionSchema],
    default: []
  },
  skill: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Skill",
    required: true,
  },
  addedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  rating: {
    type: Number,
    min: 0,
    max: 5,
    default: 0,
  },
  reviews: [
    {
      user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
      rating: {
        type: Number,
        min: 1,
        max: 5,
        required: true,
      },
      comment: {
        type: String,
      },
      date: {
        type: Date,
        default: Date.now,
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
  }
})

// Indexes for faster querying
ResourceSchema.index({ category: 1 });
ResourceSchema.index({ tags: 1 });
ResourceSchema.index({ type: 1 });
ResourceSchema.index({ visibility: 1 });
ResourceSchema.index({ skill: 1 });
ResourceSchema.index({ addedBy: 1 });
ResourceSchema.index({ 'reviews.user': 1 });

// Update the updatedAt timestamp before saving
ResourceSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model("Resource", ResourceSchema)

