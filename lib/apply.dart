import 'package:bismillah/service/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class ApplyPage extends StatefulWidget {
  final String recruitmentId;
  final String projectName;

  const ApplyPage({Key? key, required this.recruitmentId, required this.projectName}) : super(key: key);

  @override
  _ApplyPageState createState() => _ApplyPageState();
}

class _ApplyPageState extends State<ApplyPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _portfolioController = TextEditingController();
  final TextEditingController _motivationController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();

  bool _isSubmitting = false;
  List<String> _skills = [];

  @override
  void initState() {
    super.initState();
    _populateEmailField();
  }

  // Automatically populate email field with the user's email
  void _populateEmailField() {
    final userEmail = Provider.of<AuthProv>(context, listen: false).email;
    if (userEmail != null) {
      _emailController.text = userEmail;
    }
  }

  // Add skill to the skills list
  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty) {
      setState(() {
        _skills.add(skill);
      });
      _skillController.clear();
    }
  }

  // Submit application to Firestore
  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one skill')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Add the application data to Firestore
      await FirebaseFirestore.instance.collection('team_applications').add({
        'recruitmentId': widget.recruitmentId,  // ID of the recruiter
        'userId': Provider.of<AuthProv>(context, listen: false).user!.uid,  // ID of the applicant
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'portfolio': _portfolioController.text.trim(),
        'motivation': _motivationController.text.trim(),
        'skills': _skills,
        'status': 'pending',  // Set the application status to "pending"
        'projectName': widget.projectName,  // Name of the project
        'submittedAt': FieldValue.serverTimestamp(),  // Timestamp of submission
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully!')),
      );

      Navigator.pushNamed(context, '/notif');  // Redirect to notifications page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit application: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Apply Team', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/login2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Join Our Team!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Please fill in the details below to apply.",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _nameController,
                  label: 'Name',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r"^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}").hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _portfolioController,
                  label: 'Portfolio URL',
                  icon: Icons.link,
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Portfolio URL is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _motivationController,
                  label: 'Motivation',
                  icon: Icons.text_fields,
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Motivation is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _skillController,
                  label: 'Enter Skill',
                  icon: Icons.star,
                  validator: (value) {
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addSkill,
                  child: const Text('Add Skill'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: _skills.map((skill) => Chip(
                    label: Text(skill, style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.grey[700],
                    deleteIcon: Icon(Icons.close, color: Colors.white),
                    onDeleted: () {
                      setState(() {
                        _skills.remove(skill);
                      });
                    },
                  )).toList(),
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Color(0xA8A790D8),
                      minimumSize: Size(double.infinity, 50),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isSubmitting ? null : _submitApplication,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87),
      validator: validator,
      maxLines: maxLines,
    );
  }
}
