import 'package:bismillah/view_profile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SubmitProjectPage extends StatefulWidget {
  @override
  _SubmitProjectPageState createState() => _SubmitProjectPageState();
}

class _SubmitProjectPageState extends State<SubmitProjectPage> {
  DateTime? createdDate;
  DateTime? untilDate;

  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectDescriptionController = TextEditingController();
  final TextEditingController _documentLinkController = TextEditingController();
  final TextEditingController _createdByController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();

  List<String> skills = [];
  String? major;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        var data = userSnapshot.data() as Map<String, dynamic>;

        setState(() {
          _createdByController.text = data['email'] ?? 'Unknown';
          major = data['major'] ?? 'Unknown';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  String formatDate(DateTime? date) {
    return date != null ? DateFormat('yyyy-MM-dd').format(date) : "Select Date";
  }

  bool validateInputs() {
    if (_projectNameController.text.isEmpty ||
        _projectDescriptionController.text.isEmpty ||
        _createdByController.text.isEmpty ||
        major == null ||
        createdDate == null ||
        untilDate == null ||
        skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields")),
      );
      return false;
    }

    if (untilDate!.isBefore(createdDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Until Date cannot be earlier than Created Date")),
      );
      return false;
    }

    return true;
  }

  void submitProject() async {
    if (!validateInputs()) return;

    final CollectionReference projects = FirebaseFirestore.instance.collection('projects');
    String userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      await projects.add({
        'projectName': _projectNameController.text.trim(),
        'projectDescription': _projectDescriptionController.text.trim(),
        'documentLink': _documentLinkController.text.trim(),
        'createdBy': _createdByController.text.trim(),
        'userId': userId,
        'major': major,
        'createdDate': createdDate,
        'untilDate': untilDate,
        'skills': skills,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Project Submitted Successfully")));
      resetForm();

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ViewProfilePage()));
    } catch (e) {
      print("Error submitting project: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void resetForm() {
    _projectNameController.clear();
    _projectDescriptionController.clear();
    _documentLinkController.clear();
    _skillController.clear();

    setState(() {
      createdDate = null;
      untilDate = null;
      skills.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Submit Project', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/login2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              buildTextField('Project Name', _projectNameController),
              buildTextField('Description', _projectDescriptionController),
              buildTextField('Document Link (e.g., GitHub)', _documentLinkController),
              buildTextField('Created By', _createdByController, readOnly: true),
              buildTextField('Major', TextEditingController(text: major), readOnly: true),

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
                          onPressed: () {
                            if (_skillController.text.isNotEmpty) {
                              final skill = _skillController.text.trim();
                              if (!skills.contains(skill)) {
                                setState(() {
                                  skills.add(skill);
                                  _skillController.clear();
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Skill already added")),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: skills.map((skill) {
                        return Chip(
                          label: Text(skill, style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.grey[700],
                          deleteIcon: Icon(Icons.close, color: Colors.white),
                          onDeleted: () {
                            setState(() {
                              skills.remove(skill);
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
                          'Create Date:',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        ListTile(
                          title: Text('Start Date: ${formatDate(createdDate)}', style: TextStyle(color: Colors.white)),
                          onTap: () async {
                            DateTime? date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() {
                                createdDate = date;
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
                          'Until Date:',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        ListTile(
                          title: Text('End Date: ${formatDate(untilDate)}', style: TextStyle(color: Colors.white)),
                          onTap: () async {
                            DateTime? date = await showDatePicker(
                              context: context,
                              initialDate: createdDate ?? DateTime.now(),
                              firstDate: createdDate ?? DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() {
                                untilDate = date;
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
                  onPressed: submitProject,
                  child: Text('Submit Project'),
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
    );
  }

  Widget buildTextField(String label, TextEditingController controller, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
        ),
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
