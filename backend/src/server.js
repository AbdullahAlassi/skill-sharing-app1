const express = require("express")
const cors = require("cors")
const connectDB = require("./config/db")
require('dotenv').config({ path: './.env' });

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
app.use("/api/skills", require("./routes/skills"))
app.use("/api/resources", require("./routes/resources"))
app.use("/api/progress", require("./routes/progress"))
app.use("/api/events", require("./routes/event"))
app.use("/api/social", require("./routes/social"))

// Serve static files from the uploads directory
app.use("/uploads", express.static("uploads"))

// Default route
app.get("/", (req, res) => {
  res.json({ message: "Welcome to Skill Sharing API" })
})

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack)
  res.status(500).json({ message: "Something went wrong!" })
})

// Start server
const PORT = process.env.PORT || 5001
app.listen(PORT, () => console.log(`Server running on port ${PORT}`))

