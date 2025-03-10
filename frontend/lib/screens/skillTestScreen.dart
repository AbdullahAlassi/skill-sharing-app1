import 'package:flutter/material.dart';
import '../services/skill_service.dart';

class SkillTestScreen extends StatefulWidget {
  @override
  _SkillTestScreenState createState() => _SkillTestScreenState();
}

class _SkillTestScreenState extends State<SkillTestScreen> {
  List<Map<String, dynamic>> _skills = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _difficultyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSkills();
  }

  Future<void> _fetchSkills() async {
    List<Map<String, dynamic>> skills = await SkillService.getSkills();
    setState(() {
      _skills = skills;
    });
  }

  Future<void> _addSkill() async {
    bool success = await SkillService.addSkill(
      _nameController.text,
      _descriptionController.text,
      _categoryController.text,
      _difficultyController.text,
    );
    if (success) {
      _fetchSkills();
      _clearFields();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to add skill")));
    }
  }

  Future<void> _updateSkill(String id) async {
    bool success = await SkillService.updateSkill(
      id,
      _nameController.text,
      _descriptionController.text,
      _categoryController.text,
      _difficultyController.text,
    );
    if (success) {
      _fetchSkills();
      _clearFields();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update skill")));
    }
  }

  Future<void> _deleteSkill(String id) async {
    bool success = await SkillService.deleteSkill(id);
    if (success) {
      _fetchSkills();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete skill")));
    }
  }

  void _clearFields() {
    _nameController.clear();
    _descriptionController.clear();
    _categoryController.clear();
    _difficultyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Skill Management Test")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text("Name")),
                    DataColumn(label: Text("Description")),
                    DataColumn(label: Text("Category")),
                    DataColumn(label: Text("Difficulty")),
                    DataColumn(label: Text("Actions")),
                  ],
                  rows:
                      _skills
                          .map(
                            (skill) => DataRow(
                              cells: [
                                DataCell(Text(skill["name"])),
                                DataCell(Text(skill["description"])),
                                DataCell(Text(skill["category"])),
                                DataCell(Text(skill["difficulty"])),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          _nameController.text = skill["name"];
                                          _descriptionController.text =
                                              skill["description"];
                                          _categoryController.text =
                                              skill["category"];
                                          _difficultyController.text =
                                              skill["difficulty"];
                                          _updateSkill(skill["_id"]);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _deleteSkill(skill["_id"]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Add New Skill",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Skill Name"),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(labelText: "Category"),
            ),
            TextField(
              controller: _difficultyController,
              decoration: InputDecoration(labelText: "Difficulty"),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: _addSkill, child: Text("Add Skill")),
          ],
        ),
      ),
    );
  }
}
