import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widget/custome_button.dart';
import '../auth/favorite_categories_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  File? _imageFile;
  bool _isLoading = false;
  bool _isChangingPassword = false;
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _nameController = TextEditingController(text: user?.name);
    _bioController = TextEditingController(text: user?.bio);
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    // Dispose password controllers safely
    try {
      _oldPasswordController.dispose();
    } catch (e) {
      // Ignore if not initialized
    }
    try {
      _newPasswordController.dispose();
    } catch (e) {
      // Ignore if not initialized
    }
    super.dispose();
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Update name and bio
      await context.read<UserProvider>().updateProfile(
            name: _nameController.text,
            bio: _bioController.text,
          );

      // If changing password, update password
      if (_isChangingPassword) {
        // Validate password fields again if they are visible
        if (_oldPasswordController.text.isEmpty ||
            _newPasswordController.text.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Please enter both old and new passwords to change password.')),
            );
          }
          setState(() => _isLoading = false);
          return; // Stop the update process if password fields are empty
        }
        if (_newPasswordController.text.length < 6) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('New password must be at least 6 characters long.')),
            );
          }
          setState(() => _isLoading = false);
          return; // Stop the update process if new password is too short
        }

        // Use the updatePassword method from UserProvider
        final passwordUpdateResponse =
            await context.read<UserProvider>().updatePassword(
                  oldPassword: _oldPasswordController.text,
                  newPassword: _newPasswordController.text,
                );

        if (!passwordUpdateResponse.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(passwordUpdateResponse.error ??
                      'Failed to update password')),
            );
          }
          setState(() => _isLoading = false);
          return; // Stop if password update failed
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
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
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!) as ImageProvider
                                  : (Provider.of<UserProvider>(context)
                                                  .user
                                                  ?.profilePicture !=
                                              null &&
                                          Provider.of<UserProvider>(context)
                                              .user!
                                              .profilePicture!
                                              .isNotEmpty)
                                      ? NetworkImage(
                                          Provider.of<UserProvider>(context)
                                              .user!
                                              .profilePicture!)
                                      : null,
                              child: _imageFile == null &&
                                      (Provider.of<UserProvider>(context)
                                                  .user
                                                  ?.profilePicture ==
                                              null ||
                                          Provider.of<UserProvider>(context)
                                              .user!
                                              .profilePicture!
                                              .isEmpty)
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your bio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Edit Favorite Categories Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const FavoriteCategoriesScreen(),
                            ),
                          );
                        },
                        child: const Text('Edit Favorite Categories'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Password Change Section
                    Row(
                      children: [
                        Checkbox(
                          value: _isChangingPassword,
                          onChanged: (bool? value) {
                            setState(() {
                              _isChangingPassword = value ?? false;
                            });
                          },
                        ),
                        const Text('Change Password'),
                      ],
                    ),
                    if (_isChangingPassword)
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          const Text(
                            "Old Password",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _oldPasswordController,
                            decoration: const InputDecoration(
                              hintText: 'Enter your old password',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (_isChangingPassword &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter your old password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "New Password",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: const InputDecoration(
                              hintText: 'Enter your new password',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (_isChangingPassword &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter your new password';
                              }
                              if (_isChangingPassword &&
                                  value != null &&
                                  value.length < 6) {
                                return 'Password must be at least 6 characters long';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    CustomButton(
                      text: "Save Profile",
                      onPressed: _isLoading ? () {} : () => _updateProfile(),
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
