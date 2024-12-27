import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bismillah/service/auth_provider.dart';

class SubmitRecruitmentPage extends StatefulWidget {
  @override
  _SubmitRecruitmentPageState createState() => _SubmitRecruitmentPageState();
}

class _SubmitRecruitmentPageState extends State<SubmitRecruitmentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _teamSizeController = TextEditingController();
  final TextEditingController _benefitsController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();

  List<String> _skills = [];

  DateTime? _startDate;
  DateTime? _endDate;

  String formatDate(DateTime? date) {
    return date != null ? DateFormat('yyyy-MM-dd').format(date) : "Select Date";
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty) {
      setState(() {
        _skills.add(skill);
      });
      _skillController.clear();
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one skill')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProv>(context, listen: false);
    final user = authProvider.user;
    if (user == null || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('open_recruitments').add({
        'projectName': _projectNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'teamSize': int.tryParse(_teamSizeController.text.trim()) ?? 0,
        'benefits': _benefitsController.text.trim(),
        'startDate': _startDate,
        'endDate': _endDate,
        'skills': _skills,
        'createdBy': user.uid,
        'creatorName': authProvider.username,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recruitment submitted successfully!')),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/view_profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit recruitment: $e')),
      );
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
        title: Text('Submit Recruitment', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/homepage2.png'), // Keep this image
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken), // Add overlay for better contrast
          ),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                buildTextField(
                  'Project Name',
                  _projectNameController,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Project Name is required'
                      : null,
                ),
                buildTextField(
                  'Description',
                  _descriptionController,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Description is required'
                      : null,
                ),
                buildTextField(
                  'Team Size',
                  _teamSizeController,
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || int.tryParse(value) == null
                      ? 'Enter a valid number'
                      : null,
                ),
                buildTextField('Benefits', _benefitsController),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skills:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _skillController,
                              decoration: InputDecoration(
                                labelText: 'Enter skill',
                                filled: true,
                                fillColor: Colors.grey[900],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
                              ),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.white),
                            onPressed: _addSkill,
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: _skills.map((skill) {
                          return Chip(
                            label: Text(skill, style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.grey[700],
                            deleteIcon: Icon(Icons.close, color: Colors.white),
                            onDeleted: () {
                              setState(() {
                                _skills.remove(skill);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date:',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          ListTile(
                            title: Text(formatDate(_startDate), style: TextStyle(color: Colors.white)),
                            onTap: () async {
                              DateTime? date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() {
                                  _startDate = date;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Date:',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          ListTile(
                            title: Text(formatDate(_endDate), style: TextStyle(color: Colors.white)),
                            onTap: () async {
                              DateTime? date = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: _startDate ?? DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() {
                                  _endDate = date;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: Text('Submit Recruitment'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Color(0xA8A790D8),
                      minimumSize: Size(double.infinity, 50),
                      foregroundColor: Colors.white,
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

  Widget buildTextField(String label, TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
        ),
        style: TextStyle(color: Colors.white),
        validator: validator,
      ),
    );
  }
}
