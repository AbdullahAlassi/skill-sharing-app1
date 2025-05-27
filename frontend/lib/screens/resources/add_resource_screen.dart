import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:provider/provider.dart';
import '../../models/resource_model.dart' as rm;
import '../../models/skill_model.dart';
import '../../services/resource_service.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/api_response.dart';
import 'dart:io';

class AddResourceScreen extends StatefulWidget {
  final String? skillId;
  final Skill? skill;

  const AddResourceScreen({
    Key? key,
    this.skillId,
    this.skill,
  })  : assert(skillId != null || skill != null,
            'Either skillId or skill must be provided'),
        super(key: key);

  @override
  _AddResourceScreenState createState() => _AddResourceScreenState();
}

class _AddResourceScreenState extends State<AddResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  String _selectedType = 'Article';
  File? _selectedFile;
  XFile? _pickedXFile;
  String? _pickedFilePath;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _resourceTypes = [
    'Article',
    'Video',
    'Course',
    'Book',
    'Image',
    'PDF',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      if (_selectedType == 'Image' || _selectedType == 'Video') {
        final ImagePicker picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (pickedFile != null) {
          setState(() {
            _pickedXFile = pickedFile;
            _pickedFilePath = pickedFile.path;
            _selectedFile = File(pickedFile.path);
          });
        }
      } else if (_selectedType == 'PDF' || _selectedType == 'Other') {
        final typeGroup = XTypeGroup(
          label: 'files',
          extensions: _selectedType == 'PDF' ? ['pdf'] : null,
        );
        final XFile? pickedFile =
            await openFile(acceptedTypeGroups: [typeGroup]);
        if (pickedFile != null) {
          setState(() {
            _pickedXFile = pickedFile;
            _pickedFilePath = pickedFile.path;
            _selectedFile = File(pickedFile.path);
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Resource'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Skill field (only show if skill is not provided)
              if (widget.skill == null)
                TextFormField(
                  initialValue: widget.skill?.name ?? '',
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Skill',
                    border: OutlineInputBorder(),
                  ),
                )
              else
                const SizedBox.shrink(),
              const SizedBox(height: 16),

              // Resource type dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Resource Type',
                  border: OutlineInputBorder(),
                ),
                items: _resourceTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                      _selectedFile = null;
                      _pickedXFile = null;
                      _pickedFilePath = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // File upload section
              if (_selectedType == 'Image' ||
                  _selectedType == 'PDF' ||
                  _selectedType == 'Video' ||
                  _selectedType == 'Other')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_selectedFile == null
                          ? 'Choose File'
                          : 'Change File'),
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Selected file: ${_selectedFile!.path.split('/').last}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                )
              else
                // Link field for non-file resources
                TextFormField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Link',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a link';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Add Resource',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resourceService = ResourceService();
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (userProvider.user == null) {
        setState(() {
          _errorMessage = 'Please sign in to add resources';
          _isLoading = false;
        });
        return;
      }

      final skillId = widget.skill?.id ?? widget.skillId!;
      ApiResponse<rm.Resource> response;
      if (_selectedFile != null) {
        response = await resourceService.uploadResource(
          title: _titleController.text,
          description: _descriptionController.text,
          type: _selectedType,
          skillId: skillId,
          file: _selectedFile!,
        );
      } else {
        response = await resourceService.createResource(
          _titleController.text,
          _descriptionController.text,
          _linkController.text,
          _selectedType,
          skillId,
        );
      }

      if (response.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resource added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, response.data);
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to add resource';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
