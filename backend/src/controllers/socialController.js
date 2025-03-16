const { validationResult } = require("express-validator")
const User = require("../models/User")
const Group = require("../models/Group")
const Discussion = require("../models/Discussion")
const Skill = require("../models/Skill")

// @route   GET /api/social/groups
// @desc    Get all groups
// @access  Public
exports.getGroups = async (req, res) => {
  try {
    const groups = await Group.find({ isPublic: true })
      .populate("creator", "name")
      .populate("relatedSkills", "name category")
      .sort({ createdAt: -1 })

    res.json(groups)
  } catch (err) {
    console.error("Get groups error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   GET /api/social/groups/:id
// @desc    Get group by ID
// @access  Public
exports.getGroupById = async (req, res) => {
  try {
    const group = await Group.findById(req.params.id)
      .populate("creator", "name profilePicture")
      .populate("relatedSkills", "name category")
      .populate("members.user", "name profilePicture")

    if (!group) {
      return res.status(404).json({ message: "Group not found" })
    }

    // If group is private, check if user is a member
    if (!group.isPublic) {
      // If not authenticated, deny access
      if (!req.user) {
        return res.status(401).json({ message: "Not authorized to view this group" })
      }

      const isMember = group.members.some((member) => member.user._id.toString() === req.user.id)

      if (!isMember) {
        return res.status(401).json({ message: "Not authorized to view this group" })
      }
    }

    res.json(group)
  } catch (err) {
    console.error("Get group error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/social/groups
// @desc    Create a new group
// @access  Private
exports.createGroup = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { name, description, relatedSkills, isPublic } = req.body

  try {
    // Check if related skills exist
    if (relatedSkills && relatedSkills.length > 0) {
      const skillCount = await Skill.countDocuments({
        _id: { $in: relatedSkills },
      })

      if (skillCount !== relatedSkills.length) {
        return res.status(400).json({ message: "One or more skills not found" })
      }
    }

    // Create new group
    const group = new Group({
      name,
      description,
      relatedSkills: relatedSkills || [],
      creator: req.user.id,
      isPublic: isPublic !== undefined ? isPublic : true,
      members: [
        {
          user: req.user.id,
          role: "Admin",
          joinedAt: Date.now(),
        },
      ],
    })

    await group.save()

    // Add group to user's groups
    await User.findByIdAndUpdate(req.user.id, {
      $push: { groups: group._id },
    })

    // Populate references before sending response
    await group.populate("creator", "name")
    await group.populate("relatedSkills", "name category")

    res.status(201).json(group)
  } catch (err) {
    console.error("Create group error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   PUT /api/social/groups/:id
// @desc    Update a group
// @access  Private
exports.updateGroup = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { name, description, relatedSkills, isPublic } = req.body

  try {
    const group = await Group.findById(req.params.id)

    if (!group) {
      return res.status(404).json({ message: "Group not found" })
    }

    // Check if user is an admin
    const member = group.members.find((member) => member.user.toString() === req.user.id)

    if (!member || member.role !== "Admin") {
      return res.status(401).json({ message: "Not authorized to update this group" })
    }

    // Update fields
    if (name) group.name = name
    if (description) group.description = description
    if (relatedSkills) group.relatedSkills = relatedSkills
    if (isPublic !== undefined) group.isPublic = isPublic

    await group.save()

    res.json(group)
  } catch (err) {
    console.error("Update group error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/social/groups/:id/join
// @desc    Join a group
// @access  Private
exports.joinGroup = async (req, res) => {
  try {
    const group = await Group.findById(req.params.id)

    if (!group) {
      return res.status(404).json({ message: "Group not found" })
    }

    // Check if group is public
    if (!group.isPublic) {
      return res.status(400).json({ message: "Cannot join private groups directly" })
    }

    // Check if user is already a member
    const isMember = group.members.some((member) => member.user.toString() === req.user.id)

    if (isMember) {
      return res.status(400).json({ message: "Already a member of this group" })
    }

    // Add user to group members
    group.members.push({
      user: req.user.id,
      role: "Member",
      joinedAt: Date.now(),
    })

    await group.save()

    // Add group to user's groups
    await User.findByIdAndUpdate(req.user.id, {
      $push: { groups: group._id },
    })

    res.json({ message: "Successfully joined group" })
  } catch (err) {
    console.error("Join group error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   DELETE /api/social/groups/:id/leave
// @desc    Leave a group
// @access  Private
exports.leaveGroup = async (req, res) => {
  try {
    const group = await Group.findById(req.params.id)

    if (!group) {
      return res.status(404).json({ message: "Group not found" })
    }

    // Check if user is a member
    const memberIndex = group.members.findIndex((member) => member.user.toString() === req.user.id)

    if (memberIndex === -1) {
      return res.status(400).json({ message: "Not a member of this group" })
    }

    // Check if user is the creator/admin
    if (group.creator.toString() === req.user.id) {
      return res.status(400).json({ message: "Group creator cannot leave the group" })
    }

    // Remove user from group members
    group.members.splice(memberIndex, 1)

    await group.save()

    // Remove group from user's groups
    await User.findByIdAndUpdate(req.user.id, {
      $pull: { groups: group._id },
    })

    res.json({ message: "Successfully left group" })
  } catch (err) {
    console.error("Leave group error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   GET /api/social/discussions/group/:groupId
// @desc    Get discussions for a group
// @access  Private
exports.getGroupDiscussions = async (req, res) => {
  try {
    const group = await Group.findById(req.params.groupId)

    if (!group) {
      return res.status(404).json({ message: "Group not found" })
    }

    // Check if user is a member of the group
    const isMember = group.members.some((member) => member.user.toString() === req.user.id)

    if (!group.isPublic && !isMember) {
      return res.status(401).json({ message: "Not authorized to view discussions" })
    }

    const discussions = await Discussion.find({ group: req.params.groupId })
      .populate("author", "name profilePicture")
      .populate("replies.author", "name profilePicture")
      .sort({ createdAt: -1 })

    res.json(discussions)
  } catch (err) {
    console.error("Get discussions error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/social/discussions
// @desc    Create a new discussion
// @access  Private
exports.createDiscussion = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { groupId, title, content } = req.body

  try {
    const group = await Group.findById(groupId)

    if (!group) {
      return res.status(404).json({ message: "Group not found" })
    }

    // Check if user is a member of the group
    const isMember = group.members.some((member) => member.user.toString() === req.user.id)

    if (!isMember) {
      return res.status(401).json({ message: "Not authorized to create discussions" })
    }

    // Create new discussion
    const discussion = new Discussion({
      group: groupId,
      title,
      content,
      author: req.user.id,
    })

    await discussion.save()

    // Populate author details before sending response
    await discussion.populate("author", "name profilePicture")

    res.status(201).json(discussion)
  } catch (err) {
    console.error("Create discussion error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/social/discussions/:id/reply
// @desc    Add a reply to a discussion
// @access  Private
exports.addReply = async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { content } = req.body

  try {
    const discussion = await Discussion.findById(req.params.id)

    if (!discussion) {
      return res.status(404).json({ message: "Discussion not found" })
    }

    // Check if user is a member of the group
    const group = await Group.findById(discussion.group)

    if (!group) {
      return res.status(404).json({ message: "Group not found" })
    }

    const isMember = group.members.some((member) => member.user.toString() === req.user.id)

    if (!isMember) {
      return res.status(401).json({ message: "Not authorized to reply to discussions" })
    }

    // Add reply
    discussion.replies.push({
      content,
      author: req.user.id,
    })

    await discussion.save()

    // Populate author details before sending response
    await discussion.populate("replies.author", "name profilePicture")

    res.status(201).json(discussion.replies)
  } catch (err) {
    console.error("Add reply error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   GET /api/social/friends
// @desc    Get user's friends
// @access  Private
exports.getFriends = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).populate("friends", "name profilePicture bio")

    if (!user) {
      return res.status(404).json({ message: "User not found" })
    }

    res.json(user.friends)
  } catch (err) {
    console.error("Get friends error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   POST /api/social/friends/:userId
// @desc    Add a friend
// @access  Private
exports.addFriend = async (req, res) => {
  try {
    if (req.params.userId === req.user.id) {
      return res.status(400).json({ message: "Cannot add yourself as a friend" })
    }

    const user = await User.findById(req.user.id)
    const friend = await User.findById(req.params.userId)

    if (!user || !friend) {
      return res.status(404).json({ message: "User not found" })
    }

    // Check if already friends
    const alreadyFriends = user.friends.some((f) => f.toString() === req.params.userId)

    if (alreadyFriends) {
      return res.status(400).json({ message: "Already friends with this user" })
    }

    // Add friend to both users
    user.friends.push(req.params.userId)
    friend.friends.push(req.user.id)

    await user.save()
    await friend.save()

    res.json({ message: "Friend added successfully" })
  } catch (err) {
    console.error("Add friend error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

// @route   DELETE /api/social/friends/:userId
// @desc    Remove a friend
// @access  Private
exports.removeFriend = async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
    const friend = await User.findById(req.params.userId)

    if (!user || !friend) {
      return res.status(404).json({ message: "User not found" })
    }

    // Remove friend from both users
    user.friends = user.friends.filter((f) => f.toString() !== req.params.userId)

    friend.friends = friend.friends.filter((f) => f.toString() !== req.user.id)

    await user.save()
    await friend.save()

    res.json({ message: "Friend removed successfully" })
  } catch (err) {
    console.error("Remove friend error:", err.message)
    res.status(500).json({ message: "Server error" })
  }
}

