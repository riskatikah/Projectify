import 'package:bismillah/service/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class Signup extends StatefulWidget {
  @override
  State<Signup> createState() => _SignUpState();
}

class _SignUpState extends State<Signup> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _majorController.dispose();
    _batchController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text == _confirmPasswordController.text) {
        try {
          // Ambil instance dari AuthProv
          AuthProv authProvider = Provider.of<AuthProv>(context, listen: false);

          // Panggil metode register dari AuthProv
          await authProvider.register(
            _usernameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _majorController.text.trim(),
            _descriptionController.text.trim(),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registration successful")),
          );

          _usernameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          _majorController.clear();
          _descriptionController.clear();

          Navigator.pushReplacementNamed(context, '/login_page');
        } on FirebaseAuthException catch (e) {
          String message;
          if (e.code == 'weak-password') {
            message = "Password is too weak.";
          } else if (e.code == 'email-already-in-use') {
            message = "Account already exists.";
          } else {
            message = "An error occurred: ${e.message}";
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/login2.png'), // Replace with your image path
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 5),
              const Text(
                "Sign up",
                style: TextStyle(
                  color: Color(0xFF9090D8),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _usernameController,
                      icon: Icons.person,
                      hint: 'Username',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please Enter Username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _emailController,
                      icon: Icons.email,
                      hint: 'Email',
                      validator: (value) {
                        print("Input Email: '${value?.trim()}'");
                        print("Regex Match: ${RegExp(r'^[a-zA-Z0-9._%+-]+@(president\.ac\.id|student\.president\.ac\.id)$').hasMatch(value?.trim() ?? '')}");

                        if (value == null || value.isEmpty) {
                          return 'Please Enter Email';
                        } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@(president\.ac\.id|student\.president\.ac\.id)$').hasMatch(value.trim())) {
                          return 'Email must be president.ac.id or student.president.ac.id';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildPasswordField(
                      controller: _passwordController,
                      hint: 'Password',
                    ),
                    const SizedBox(height: 10),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      hint: 'Confirm Password',
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _majorController,
                      icon: Icons.school,
                      hint: 'Lecture/Student Major',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please Enter Lecture/Student Major';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _descriptionController,
                      icon: Icons.description,
                      hint: 'Description',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please Enter Description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9090D8),
                        padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Register",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: 350,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            blurRadius: 5,
            spreadRadius: 1,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9090D8)),
          prefixIcon: Icon(icon, color: const Color(0xFF9090D8)),
        ),
        style: const TextStyle(color: Color(0xFF9090D8)),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: 350,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !_isPasswordVisible,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9090D8)),
          prefixIcon: const Icon(Icons.lock, color: Color(0xFF9090D8)),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFF9090D8),
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
        style: const TextStyle(color: Color(0xFF9090D8)),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please Enter Password';
          } else if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
    );
  }
}
