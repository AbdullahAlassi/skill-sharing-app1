const User = require("../models/User");

// @route   GET /api/users/me
// @desc    Get current user
// @access  Private
exports.getCurrentUser = async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .select("-password")
      .populate("skills.skill", "name category")
      .populate("friends", "name profilePicture")
      .populate("groups", "name description");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json(user);
  } catch (err) {
    console.error("Get current user error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
};

// @route   PUT /api/users/preferences
// @desc    Update user preferences (favorite categories)
// @access  Private
exports.updatePreferences = async (req, res) => {
  try {
    const { favoriteCategories } = req.body;

    // Validate categories
    if (!Array.isArray(favoriteCategories) || favoriteCategories.length < 3 || favoriteCategories.length > 5) {
      return res.status(400).json({ message: "Please select 3-5 categories" });
    }

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    user.favoriteCategories = favoriteCategories;
    await user.save();

    res.json({ message: "Preferences updated successfully" });
  } catch (err) {
    console.error("Update preferences error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
};

// @route   GET /api/users/preferences
// @desc    Get user preferences
// @access  Private
exports.getPreferences = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({ favoriteCategories: user.favoriteCategories });
  } catch (err) {
    console.error("Get preferences error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
}; 