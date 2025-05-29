const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  email: {
    type: String,
    required: true,
    unique: true
  },
  password: {
    type: String,
    required: true
  },
  profilePicture: {
    type: String,
    default: ''
  },
  bio: {
    type: String,
    default: ''
  },
  skills: [{
    skill: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Skill'
    },
    proficiency: {
      type: String,
      enum: ['Beginner', 'Intermediate', 'Advanced'],
      default: 'Beginner'
    },
    addedAt: {
      type: Date,
      default: Date.now
    }
  }],
  favoriteCategories: [{
    type: String,
  }],
  friends: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  groups: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Group'
  }],
  createdSkills: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Skill',
    required: true
  }],
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Add index for faster queries
UserSchema.index({ email: 1 });
UserSchema.index({ createdSkills: 1 });

// Add method to compare password
UserSchema.methods.comparePassword = async function(candidatePassword) {
  try {
    const bcrypt = require('bcryptjs');
    console.log('\n=== Password Comparison in User Model ===');
    console.log('Candidate password:', candidatePassword);
    console.log('Candidate password length:', candidatePassword.length);
    console.log('Stored hash:', this.password);
    
    // Ensure candidate password is trimmed
    const trimmedPassword = candidatePassword.trim();
    console.log('Trimmed password:', trimmedPassword);
    console.log('Trimmed password length:', trimmedPassword.length);
    
    const isMatch = await bcrypt.compare(trimmedPassword, this.password);
    console.log('Password comparison result:', isMatch);
    console.log('=== End Password Comparison ===\n');
    return isMatch;
  } catch (error) {
    console.error('Error in comparePassword:', error);
    return false;
  }
};

// Add pre-save middleware to hash password
UserSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const bcrypt = require('bcryptjs');
    console.log('Hashing password in pre-save hook:');
    console.log('Password length before hashing:', this.password.length);
    
    // Check if password is already hashed
    if (this.password.startsWith('$2')) {
      console.log('Password appears to be already hashed, skipping hashing');
      return next();
    }
    
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password.trim(), salt);
    console.log('Password hashed successfully in pre-save hook');
    next();
  } catch (error) {
    console.error('Error in pre-save hook:', error);
    next(error);
  }
});

module.exports = mongoose.model('User', UserSchema);
