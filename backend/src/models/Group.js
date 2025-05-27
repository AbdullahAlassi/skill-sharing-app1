const mongoose = require("mongoose")

const GroupSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
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
  creator: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  members: [
    {
      user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
      role: {
        type: String,
        enum: ["Admin", "Moderator", "Member"],
        default: "Member",
      },
      joinedAt: {
        type: Date,
        default: Date.now,
      },
    },
  ],
  isPublic: {
    type: Boolean,
    default: true,
  },
  announcements: [{
    title: {
      type: String,
      required: true
    },
    content: {
      type: String,
      required: true
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],
  chat: [{
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },
    message: {
      type: String,
      required: true
    },
    attachments: [{
      type: String // URLs to attached files
    }],
    readBy: [{
      user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User"
      },
      readAt: {
        type: Date,
        default: Date.now
      }
    }],
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],
  chatEnabled: {
    type: Boolean,
    default: true
  },
  chatPermissions: {
    canSendMessages: {
      type: Boolean,
      default: true
    },
    canSendMedia: {
      type: Boolean,
      default: true
    },
    canCreatePolls: {
      type: Boolean,
      default: false
    }
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

// Index for faster querying of groups by members
GroupSchema.index({ 'members.user': 1 });
// Index for faster querying of public groups
GroupSchema.index({ isPublic: 1 });
// Index for faster querying of chat messages
GroupSchema.index({ 'chat.createdAt': -1 });

module.exports = mongoose.model("Group", GroupSchema)

