const mongoose = require("mongoose")

const EventSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  category: {
    type: String,
    required: true,
  },
  date: {
    type: Date,
    required: true,
  },
  endDate: {
    type: Date,
  },
  location: {
    type: String,
    default: "Online",
  },
  isVirtual: {
    type: Boolean,
    default: true,
  },
  meetingLink: {
    type: String,
  },
  image: {
    type: String,
  },
  relatedSkills: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Skill",
    },
  ],
  organizer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  participants: [
    {
      user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
      registeredAt: {
        type: Date,
        default: Date.now,
      },
      attendanceCode: {
        type: String,
        unique: true,
        sparse: true,
      },
      codeGeneratedAt: {
        type: Date,
      },
      codeExpiresAt: {
        type: Date,
      },
      attended: {
        type: Boolean,
        default: false,
      },
      attendanceVerifiedAt: {
        type: Date,
      },
    },
  ],
  maxParticipants: {
    type: Number,
  },
  ratings: [
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
  popularity: {
    type: Number,
    default: 0,
  },
  views: {
    type: Number,
    default: 0,
  },
  visibility: {
    type: String,
    enum: ['public', 'private'],
    default: 'public',
  },
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
EventSchema.index({ category: 1 });
EventSchema.index({ date: 1 });
EventSchema.index({ popularity: -1 });
EventSchema.index({ visibility: 1 });
EventSchema.index({ organizer: 1 });
EventSchema.index({ 'participants.user': 1 });
EventSchema.index({ 'ratings.user': 1 });
EventSchema.index({ 'participants.attendanceCode': 1 }, { unique: true, sparse: true });

// Update the updatedAt timestamp before saving
EventSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model("Event", EventSchema)

