require("dotenv").config();
const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");

const app = express();
app.use(express.json());
app.use(cors());

const PORT = process.env.PORT || 5001;
// ✅ Ensure DB_URI is Correctly Loaded
console.log("Connecting to MongoDB at:", process.env.DB_URI);

// Connect to MongoDB
mongoose.connect(process.env.DB_URI)
  .then(() => console.log("MongoDB Connected"))
  .catch(err => console.log("MongoDB Connection Error:",err));

// Default Route
app.get("/", (req, res) => {
  res.send("Skill Sharing API Running...");
});

const authRoutes = require("./routes/auth");
app.use("/api/auth", authRoutes);

const skillRoutes = require("./routes/skills");
app.use("/api/skills", skillRoutes);

const resourceRoutes = require("./routes/resources");
app.use("/api/resources", resourceRoutes);

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
