const mongoose = require('mongoose');
const Skill = require('../models/Skill');

async function dropNameIndex() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/othmans_backend');
    console.log('Connected to MongoDB');

    // Drop the unique index on the name field
    await Skill.collection.dropIndex('name_1');
    console.log('Successfully dropped the unique index on the name field');

    // Close the connection
    await mongoose.connection.close();
    console.log('MongoDB connection closed');
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

dropNameIndex(); 