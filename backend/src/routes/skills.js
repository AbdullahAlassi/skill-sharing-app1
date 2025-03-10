const express = require("express");
const router = express.Router();
const Skill = require("../models/Skill");
const User = require("../models/User");
const authMiddleware = require("../middleware/authmiddleware");
const authmiddleware = require("../middleware/authmiddleware");

//Add a new skill
router.post("/add", authMiddleware, async (req, res) => {
    try {
        console.log("Decoded User From Token:", req.user); // Debugging

        const { name, description, category, difficulty } = req.body;
        const userId = req.user.id; // Correctly extract user ID

        if (!userId) {
            return res.status(400).json({ error: "User ID not found in token" });
        }

        // Check if skill already exists for this user
        const existingSkill = await Skill.findOne({ name, user: userId });
        if (existingSkill) {
            return res.status(400).json({ error: "Skill already exists" });
        }

        // Create and save the new skill
        const newSkill = new Skill({ name, description, category, difficulty, user: userId });
        await newSkill.save();

        // Add skill to user's skills array
        await User.findByIdAndUpdate(userId, { $push: { skills: newSkill._id } });

        res.status(201).json({ message: "Skill added successfully", skill: newSkill });
    } catch (error) {
        console.error("Error Adding Skill:", error);
        res.status(500).json({ error: error.message });
    }
});


//Get All skills
router.get("/", authmiddleware, async (req,res) =>{
    try {
        const userId = req.user.id; // Get logged-in user ID from token
        const skills = await Skill.find({ user: userId});

        res.status(200).json(skills);
    } catch (error) {
        res.status(500).json({ error: "Server error"});
    }
});

//  Update a skill (Only by the user who added it)
router.put("/:id", authMiddleware, async (req, res) => {
  try {
    const { name, description, category, difficulty } = req.body;
    const userId = req.user.id;

    // Find skill and check ownership
    const skill = await Skill.findById(req.params.id);
    if (!skill) return res.status(404).json({ error: "Skill not found" });

    if (skill.user.toString() !== userId) {
      return res.status(403).json({ error: "Unauthorized" });
    }

    // Update skill
    skill.name = name;
    skill.description = description;
    skill.category = category;
    skill.difficulty = difficulty;
    await skill.save();

    res.status(200).json({ message: "Skill updated", skill });
  } catch (error) {
    res.status(500).json({ error: "Server error" });
  }
});

// Delete a skill (Only by the user who added it)
router.delete("/:id", authMiddleware, async (req, res) => {
    try {
      const userId = req.user.id;
  
      // Find skill and check ownership
      const skill = await Skill.findById(req.params.id);
      if (!skill) return res.status(404).json({ error: "Skill not found" });
  
      if (skill.user.toString() !== userId) {
        return res.status(403).json({ error: "Unauthorized" });
      }
  
      // Delete skill
      await skill.deleteOne();
      
      // Remove skill from user's skills array
      await User.findByIdAndUpdate(userId, { $pull: { skills: req.params.id } });
  
      res.status(200).json({ message: "Skill deleted successfully" });
    } catch (error) {
      res.status(500).json({ error: "Server error" });
    }
  });
  

module.exports = router;