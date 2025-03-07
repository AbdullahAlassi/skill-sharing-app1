const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/User");

const router = express.Router();

router.post("/signup", async (req, res) => {
    try {
        const {name, email, password} = req.body;
        const hashedPassword = await bcrypt.hash(password, 10);
        const newUser = new User({name, email, password: hashedPassword});
        await newUser.save();
        res.json({ message: "User registered successfully"});
    } catch (error) {
        res.status(500).json({ error: "Server error"});
    }
});

router.post("/login", async (req, res) => {
    try {
      const { email, password } = req.body;
      const user = await User.findOne({ email });

      if (!user || !await bcrypt.compare(password, user.password)) {
        return res.status(400).json({ error: "Invalid credentials" });
      }
      
      const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: "48h" });
      res.json({ token, user: {id: user._id, name: user.name, email: user.email} });
    } catch (error) {
      res.status(500).json({ error: "Server error" });
    }
  });
  
  module.exports = router;