const mongoose = require('mongoose');

const skillCategorySchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  icon: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  skillCount: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Virtual for getting skills in this category
skillCategorySchema.virtual('skills', {
  ref: 'Skill',
  localField: '_id',
  foreignField: 'category'
});

// Method to update skill count
skillCategorySchema.methods.updateSkillCount = async function() {
  const Skill = mongoose.model('Skill');
  const count = await Skill.countDocuments({ category: this._id });
  this.skillCount = count;
  return this.save();
};

const SkillCategory = mongoose.model('SkillCategory', skillCategorySchema);

module.exports = SkillCategory; 