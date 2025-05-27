const express = require("express")
const cors = require("cors")
const connectDB = require("./config/db")
require('dotenv').config({ path: './.env' });
require('./config/cron'); // Initialize cron jobs

// Initialize Express
const app = express()

// Connect to Database
connectDB()

// Middleware
app.use(express.json({ extended: false }))
app.use(cors())

// Define Routes
app.use("/api/auth", require("./routes/authRoutes"))
app.use("/api/profile", require("./routes/profile"))
app.use("/api/users", require("./routes/users"))
app.use("/api/resources", require("./routes/resources"))
app.use("/api/social", require("./routes/social"))
app.use("/api/skills", require("./routes/skills"))
app.use("/api/events", require("./routes/event"))
app.use("/api/progress", require("./routes/progress"))
app.use("/api/groups", require("./routes/groupRoutes"))
app.use("/api/notifications", require("./routes/notificationRoutes"))
app.use("/api/skill-categories", require("./routes/skillCategoryRoutes"))
const friendRoutes = require('./routes/friend.routes');
const chatRoutes = require('./routes/chat.routes');

// Serve static files from the uploads directory
app.use("/uploads", express.static("uploads"))

// Default route
app.get("/", (req, res) => {
  res.json({ message: "Welcome to Skill Sharing API" })
})

// Routes
app.use('/api/social', friendRoutes);
app.use('/api/social/chat', chatRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack)
  res.status(500).json({ message: "Something went wrong!" })
})

// Start server
const PORT = process.env.PORT || 5000
app.listen(PORT, () => console.log(`Server running on port ${PORT}`))

