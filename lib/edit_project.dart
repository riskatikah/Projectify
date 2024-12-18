import 'dart:io';
import 'package:bismillah/view_project.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  String? selectedImagePath;
  String? selectedMajor;
  List<String> majors = ['Informatics', 'Information System'];

  // Firestore and Firebase Storage instances
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _fetchProjectData();
  }

  // Fetch project data from Firestore
  Future<void> _fetchProjectData() async {
    DocumentSnapshot projectSnapshot = await firestore.collection('projects').doc(widget.projectId).get();
    var data = projectSnapshot.data() as Map<String, dynamic>;

    setState(() {
      _projectNameController.text = data['projectName'];
      _projectDescriptionController.text = data['projectDescription'];
      _documentLinkController.text = data['documentLink'];
      _createdByController.text = data['createdBy'];
      createdDate = (data['createdDate'] as Timestamp).toDate();
      untilDate = (data['untilDate'] as Timestamp).toDate();
      selectedImagePath = data['imageUrl']; // Setting the existing image URL
      selectedMajor = data['major'];
    });
  }

  // Format the date for display
  String formatDate(DateTime? date) {
    return date != null ? DateFormat('yyyy-MM-dd').format(date) : "Select Date";
  }

  // Select image from gallery
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImagePath = image.path; // Update the selected image path
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image Selected: ${image.name}")));
    }
  }

  // Upload the image to Firebase Storage
  Future<String?> uploadFileToStorage(File file, String filePath) async {
    try {
      final Reference storageRef = storage.ref().child(filePath);
      final UploadTask uploadTask = storageRef.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading file: $e");
      return null;
    }
  }

  // Update the project data in Firestore
  void updateProject() async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please log in to update a project")));
      return;
    }

    String projectName = _projectNameController.text;
    String projectDescription = _projectDescriptionController.text;
    String documentLink = _documentLinkController.text;
    String createdBy = _createdByController.text;
    String userId = FirebaseAuth.instance.currentUser!.uid;

    if (projectName.isEmpty || projectDescription.isEmpty || createdBy.isEmpty || selectedMajor == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    if (untilDate != null && createdDate != null && untilDate!.isBefore(createdDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Until Date cannot be earlier than Created Date")));
      return;
    }

    try {
      String? imageUrl;
      // Upload the new image if selected
      if (selectedImagePath != null) {
        imageUrl = await uploadFileToStorage(File(selectedImagePath!), 'project_images/${DateTime.now().millisecondsSinceEpoch}');
      }

      // Update project data in Firestore
      await firestore.collection('projects').doc(widget.projectId).update({
        'projectName': projectName,
        'projectDescription': projectDescription,
        'documentLink': documentLink,
        'createdBy': createdBy,
        'userId': userId,
        'major': selectedMajor,
        'createdDate': createdDate ?? DateTime.now(),
        'untilDate': untilDate,
        'imageUrl': imageUrl ?? selectedImagePath ?? '',
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Project Updated Successfully")));

      // Navigate back to the ViewProjectPage
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

  // Delete the project from Firestore
  void deleteProject() async {
    try {
      await firestore.collection('projects').doc(widget.projectId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Project Deleted Successfully")));
      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting project: $e")));
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
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[900],
                  labelStyle: TextStyle(color: Colors.white),
                ),
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
                        Text(
                          'Until Date:',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
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

  // Text input field
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
