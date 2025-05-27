const jwt = require("jsonwebtoken");
const User = require("../models/User");

module.exports = async (req, res, next) => {
  try {
    const authHeader = req.header("Authorization");
    console.log('\n=== Auth Middleware Debug ===');
    console.log('Auth header:', authHeader);

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      console.log('No valid auth header found');
      return res.status(401).json({ 
        success: false,
        message: "No token, authorization denied" 
      });
    }

    const token = authHeader.split(" ")[1];
    console.log('Extracted token:', token);

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      console.log('Decoded token:', decoded);
      console.log('Decoded user ID:', decoded.user.id);
      
      // Fetch latest user data from database
      const user = await User.findById(decoded.user.id)
        .select('-password')
        .populate('skills.skill')
        .populate('friends')
        .populate('groups')
        .populate('createdSkills');
        
      if (!user) {
        console.log('User not found for ID:', decoded.user.id);
        return res.status(401).json({ 
          success: false,
          message: "User no longer exists" 
        });
      }

      console.log('Found user:', {
        id: user._id,
        email: user.email,
        name: user.name
      });
      
      // Attach user info to request
      req.user = user;
      console.log('=== Auth Middleware Complete ===\n');
      next();
    } catch (error) {
      console.error('Token verification error:', error);
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({ 
          success: false,
          message: "Token expired" 
        });
      }
      return res.status(401).json({ 
        success: false,
        message: "Invalid token" 
      });
    }
  } catch (error) {
    console.error("Auth middleware error:", error);
    return res.status(500).json({ 
      success: false,
      message: "Server error" 
    });
  }
};
