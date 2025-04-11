import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import 'package:frontend/widget/custome_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController.text = userProvider.user?.name ?? '';
    _bioController.text = userProvider.user?.bio ?? '';
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profileService = ProfileService();
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Update profile information
      final response = await profileService.updateProfile(
        _nameController.text.trim(),
        _bioController.text.trim(),
      );

      if (response.success) {
        // If profile picture was changed, upload it
        if (_imageFile != null) {
          // TODO: Implement image upload functionality
          // This would require adding a method to upload the image file
          // For now, we'll skip this part
        }

        // Reload user data to reflect changes
        await userProvider.loadUser();

        // Return to profile screen
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt),
                                      title: const Text('Take a picture'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _pickImage(ImageSource.camera);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.image),
                                      title: const Text('Choose from gallery'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _pickImage(ImageSource.gallery);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage:
                                    _imageFile != null
                                        ? FileImage(_imageFile!)
                                            as ImageProvider
                                        : NetworkImage(
                                          Provider.of<UserProvider>(
                                                context,
                                              ).user?.profilePicture ??
                                              'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
                                        ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name field
                      const Text(
                        "Name",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Bio field
                      const Text(
                        "Bio",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your bio',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),

                      CustomButton(
                        text: "Save Profile",
                        onPressed: _saveProfile,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
