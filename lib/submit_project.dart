import 'dart:io';
import 'package:bismillah/view_profile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'service/auth_provider.dart';

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;

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

  String? selectedMajor;
  String? selectedImagePath;
  String? uploadedImageUrl;

  List<String> majors = ['Informatics', 'Information System'];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProv>(context, listen: false).user;
    _createdByController.text = user?.displayName ?? user?.email ?? 'Unknown';
  }

  String formatDate(DateTime? date) {
    return date != null ? DateFormat('yyyy-MM-dd').format(date) : "Select Date";
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImagePath = image.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image Selected: ${image.name}")));
    }
  }

  Future<String?> uploadFileToStorage(File file, String filePath) async {
    try {
      final Reference storageRef = FirebaseStorage.instance.ref().child(filePath);
      final UploadTask uploadTask = storageRef.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading file: $e");
      return null;
    }
  }

  void submitProject() async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please log in to submit a project")));
      return;
    }

    final CollectionReference projects = FirebaseFirestore.instance.collection('projects');

    String projectName = _projectNameController.text;
    String projectDescription = _projectDescriptionController.text;
    String documentLink = _documentLinkController.text;
    String createdBy = _createdByController.text;
    String userId = FirebaseAuth.instance.currentUser!.uid;

    if (projectName.isEmpty || projectDescription.isEmpty || createdBy.isEmpty || selectedMajor == null || createdDate == null || untilDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    if (untilDate!.isBefore(createdDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Until Date cannot be earlier than Created Date")));
      return;
    }

    try {
      if (selectedImagePath != null) {
        uploadedImageUrl = await uploadFileToStorage(
          File(selectedImagePath!),
          'project_images/${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Add project data to Firestore
      DocumentReference newProject = await projects.add({
        'projectName': projectName,
        'projectDescription': projectDescription,
        'documentLink': documentLink,
        'createdBy': createdBy,
        'userId': userId,
        'major': selectedMajor,
        'createdDate': createdDate,
        'untilDate': untilDate,
        'imageUrl': selectedImagePath ?? '',
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Project Submitted Successfully")));

      // Clear fields after submission
      _projectNameController.clear();
      _projectDescriptionController.clear();
      _documentLinkController.clear();

      setState(() {
        createdDate = null;
        untilDate = null;
        selectedMajor = null;
        selectedImagePath = null;
      });

      // Navigate to ViewProfilePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ViewProfilePage(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
              Center(
                child: GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      image: selectedImagePath != null
                          ? DecorationImage(image: FileImage(File(selectedImagePath!)), fit: BoxFit.cover)
                          : null,
                    ),
                    child: selectedImagePath == null
                        ? Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 20),
              buildTextField('Project Name', _projectNameController),
              buildTextField('Description', _projectDescriptionController),
              buildTextField('Document Link (e.g., GitHub)', _documentLinkController),
              buildTextField('Created By', _createdByController, readOnly: true),
              DropdownButtonFormField<String>(
                value: selectedMajor,
                decoration: InputDecoration(filled: true, fillColor: Colors.grey[900]),
                dropdownColor: Colors.black,
                items: majors.map((major) {
                  return DropdownMenuItem<String>(
                    value: major,
                    child: Text(major, style: TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMajor = value;
                  });
                },
                hint: Text('Select Major', style: TextStyle(color: Colors.white)),
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
