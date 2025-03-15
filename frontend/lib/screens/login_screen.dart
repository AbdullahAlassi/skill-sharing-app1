import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      bool success = await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).login(emailController.text, passwordController.text);
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid credentials. Try again.")),
        );
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
                SizedBox(height: 100),
                Center(
                  child: Text(
                    "Access Account",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    "Please log in to continue",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                SizedBox(height: 30),
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
                SizedBox(height: 20),
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
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Forgot your password?",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                SizedBox(height: 10),
                _buildButton(
                  "Log In",
                  const Color.fromRGBO(99, 106, 232, 1),
                  Colors.white,
                  () {
                    _login();
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
                          MaterialPageRoute(builder: (_) => SignupScreen()),
                        ),
                    child: Text(
                      "Need to create an account? Sign Up",
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
