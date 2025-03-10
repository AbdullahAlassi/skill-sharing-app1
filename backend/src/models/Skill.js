const mongoose = require("mongoose");

const SkillSchema = new mongoose.Schema({
    name: { type: String, required:true, unique: true},
    description: {type: String, required: true},
    category: {type: String, required: true},
    difficulty: {type: String, enum: ["Beginner", "Intermediate", "Advanced"], required: true},
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", require: true},
}, {timestamps: true});

module.exports = mongoose.model("Skill", SkillSchema);