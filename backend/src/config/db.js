// src/config/db.js
const mongoose = require("mongoose");

const connectDB = async () => {
  try {
    // Log the URI to debug (remove in production)
    console.log("MongoDB URI:", process.env.MONGODB_URI);
    
    if (!process.env.MONGODB_URI) {
      throw new Error("MONGODB_URI environment variable is not defined");
    }
    
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
     
    });

    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`Error connecting to MongoDB: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;