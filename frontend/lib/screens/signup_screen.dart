import 'package:flutter/material.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SignupScreen extends StatefulWidget {
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final TextEditingController repasswordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      bool success = await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).signup(
        nameController.text,
        emailController.text,
        passwordController.text,
      );
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Signup failed. Try again.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 60),
                Center(
                  child: Text(
                    "Create Account",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    "Create your account to start learning.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                SizedBox(height: 30),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.account_circle_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  validator:
                      (value) => value!.isEmpty ? "Enter your name" : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  validator:
                      (value) => value!.isEmpty ? "Enter a valid email" : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  obscureText: true,
                  validator:
                      (value) =>
                          value!.length < 6 ? " Password too short" : null,
                ),
                Row(
                  children: [
                    Checkbox(value: true, onChanged: (val) {}),
                    Text("I agree with Terms & Conditions"),
                  ],
                ),
                SizedBox(height: 10),
                _buildButton(
                  "Sign Up",
                  const Color.fromRGBO(99, 106, 232, 1),
                  Colors.white,
                  () {
                    _signup();
                  },
                ),
                SizedBox(height: 20),
                Center(child: Text("Or", style: TextStyle(color: Colors.grey))),
                SizedBox(height: 10),
                _buildSocialButton(
                  FontAwesomeIcons.apple,
                  "Continue with Apple",
                  Colors.black12,
                ),
                _buildSocialButton(
                  FontAwesomeIcons.google,
                  "Continue with Google",
                  Colors.redAccent,
                ),
                _buildSocialButton(
                  FontAwesomeIcons.facebook,
                  "Continue with Facebook",
                  Colors.blue,
                ),
                SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SignInScreen()),
                        ),
                    child: Text(
                      "Already registered? Log In",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildTextField(
  IconData icon,
  String hintText, {
  bool isPassword = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    ),
  );
}

Widget _buildButton(
  String text,
  Color bgColor,
  Color textColor,
  VoidCallback onPressed,
) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(vertical: 15),
      ),
      onPressed: onPressed,
      child: Text(text, style: TextStyle(color: textColor, fontSize: 18)),
    ),
  );
}

Widget _buildSocialButton(IconData icon, String text, Color color) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(5.0),
      child: SizedBox(
        width: 300,
        height: 40,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {},
          icon: FaIcon(icon, color: Colors.white),
          label: Text(
            text,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    ),
  );
}
