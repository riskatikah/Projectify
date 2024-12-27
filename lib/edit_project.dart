import 'package:bismillah/view_profile.dart';
import 'package:bismillah/view_project.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditProjectPage extends StatefulWidget {
  final String projectId;

  EditProjectPage({required this.projectId});

  @override
  _EditProjectPageState createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  DateTime? createdDate;
  DateTime? untilDate;

  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectDescriptionController = TextEditingController();
  final TextEditingController _documentLinkController = TextEditingController();
  final TextEditingController _createdByController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();

  List<String> skills = [];
  String? selectedMajor;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchProjectData();
    _fetchUserMajor();
  }

  Future<void> _fetchProjectData() async {
    try {
      DocumentSnapshot projectSnapshot = await firestore.collection('projects').doc(widget.projectId).get();
      var data = projectSnapshot.data() as Map<String, dynamic>;

      setState(() {
        _projectNameController.text = data['projectName'];
        _projectDescriptionController.text = data['projectDescription'];
        _documentLinkController.text = data['documentLink'];
        _createdByController.text = data['createdBy'];
        skills = List<String>.from(data['skills'] ?? []);
        createdDate = (data['createdDate'] as Timestamp).toDate();
        untilDate = (data['untilDate'] as Timestamp).toDate();
      });
    } catch (e) {
      print('Error fetching project data: $e');
    }
  }

  Future<void> _fetchUserMajor() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userSnapshot = await firestore.collection('users').doc(user.uid).get();
        var data = userSnapshot.data() as Map<String, dynamic>;

        setState(() {
          selectedMajor = data['major'];
        });
      }
    } catch (e) {
      print('Error fetching user major: $e');
    }
  }

  String formatDate(DateTime? date) {
    return date != null ? DateFormat('yyyy-MM-dd').format(date) : "Select Date";
  }

  void updateProject() async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please log in to update a project")));
      return;
    }

    String projectName = _projectNameController.text;
    String projectDescription = _projectDescriptionController.text;
    String documentLink = _documentLinkController.text;
    String createdBy = _createdByController.text;

    if (projectName.isEmpty ||
        projectDescription.isEmpty ||
        createdBy.isEmpty ||
        selectedMajor == null ||
        createdDate == null ||
        untilDate == null ||
        skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    if (untilDate!.isBefore(createdDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Until Date cannot be earlier than Created Date")));
      return;
    }

    try {
      await firestore.collection('projects').doc(widget.projectId).update({
        'projectName': projectName,
        'projectDescription': projectDescription,
        'documentLink': documentLink,
        'createdBy': createdBy,
        'major': selectedMajor,
        'createdDate': createdDate,
        'untilDate': untilDate,
        'skills': skills,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Project Updated Successfully")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ViewProjectPage(projectId: widget.projectId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void deleteProject() async {
    try {
      await firestore.collection('projects').doc(widget.projectId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Project Deleted Successfully")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ViewProfilePage(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting project: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Project", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
              buildTextField('Project Name', _projectNameController),
              buildTextField('Description', _projectDescriptionController),
              buildTextField('Document Link (e.g., GitHub)', _documentLinkController),
              buildTextField('Created By', _createdByController, readOnly: true),
              buildTextField('Major', TextEditingController(text: selectedMajor), readOnly: true),

              // Skill Input
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Skills:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                              setState(() {
                                skills.add(_skillController.text.trim());
                                _skillController.clear();
                              });
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
                        Text('Create Date:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ListTile(
                          title: Text('Start Date: ${formatDate(createdDate)}', style: TextStyle(color: Colors.white)),
                          onTap: () async {
                            DateTime? date = await showDatePicker(
                              context: context,
                              initialDate: createdDate ?? DateTime.now(),
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
                        Text('Until Date:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ListTile(
                          title: Text('End Date: ${formatDate(untilDate)}', style: TextStyle(color: Colors.white)),
                          onTap: () async {
                            DateTime? date = await showDatePicker(
                              context: context,
                              initialDate: untilDate ?? createdDate ?? DateTime.now(),
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
              ElevatedButton(
                onPressed: updateProject,
                child: Text('Update Project'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Color(0xA8A790D8),
                  minimumSize: Size(double.infinity, 50),
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: deleteProject,
                child: Text('Delete Project'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Color(0xA8A790D8),
                  minimumSize: Size(double.infinity, 50),
                  foregroundColor: Colors.white,
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
          labelStyle: TextStyle(color: Colors.white),
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
        ),
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
