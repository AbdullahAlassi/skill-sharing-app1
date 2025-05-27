const express = require('express');
const router = express.Router();
const skillCategoryController = require('../controllers/skillCategoryController');
const auth = require('../middleware/auth');

// Get all categories
router.get('/', skillCategoryController.getAllCategories);

// Get a single category
router.get('/:id', skillCategoryController.getCategoryById);

// Create a new category (protected route)
router.post('/', auth, skillCategoryController.createCategory);

// Update a category (protected route)
router.patch('/:id', auth, skillCategoryController.updateCategory);

// Delete a category (protected route)
router.delete('/:id', auth, skillCategoryController.deleteCategory);

module.exports = router; 