const mongoose = require('mongoose');
const SkillCategory = require('../models/skillCategory');
require('dotenv').config({ path: './.env' });

const categories = [
  {
    name: 'Programming',
    icon: '💻',
    description: 'Learn various programming languages and frameworks',
    skillCount: 0
  },
  {
    name: 'Design',
    icon: '🎨',
    description: 'Master design tools and principles',
    skillCount: 0
  },
  {
    name: 'Music',
    icon: '🎵',
    description: 'Learn instruments and music theory',
    skillCount: 0
  },
  {
    name: 'Languages',
    icon: '🌍',
    description: 'Learn new languages and improve communication',
    skillCount: 0
  },
  {
    name: 'Business',
    icon: '💼',
    description: 'Develop business and entrepreneurship skills',
    skillCount: 0
  },
  {
    name: 'Cooking',
    icon: '👨‍🍳',
    description: 'Master culinary arts and cooking techniques',
    skillCount: 0
  }
];

const seedCategories = async () => {
  try {
    console.log('MongoDB URI:', process.env.MONGODB_URI); // Debug log
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Clear existing categories
    await SkillCategory.deleteMany({});
    console.log('Cleared existing categories');

    // Insert new categories
    const result = await SkillCategory.insertMany(categories);
    console.log('Added categories:', result);

    mongoose.connection.close();
  } catch (error) {
    console.error('Error seeding categories:', error);
    process.exit(1);
  }
};

seedCategories(); 