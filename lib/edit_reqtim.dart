import 'package:bismillah/view_profile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EditRecruitmentPage extends StatefulWidget {
  final String recruitmentId; // ID of the recruitment to edit
  EditRecruitmentPage({required this.recruitmentId, required projectName});

  @override
  _EditRecruitmentPageState createState() => _EditRecruitmentPageState();
}

class _EditRecruitmentPageState extends State<EditRecruitmentPage> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _teamSizeController = TextEditingController();
  final TextEditingController _benefitsController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _skills = [];

  // Load recruitment data
  Future<void> _loadRecruitmentData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('open_recruitments')
          .doc(widget.recruitmentId)
          .get();

      if (doc.exists) {
        setState(() {
          _projectNameController.text = doc['projectName'];
          _descriptionController.text = doc['description'];
          _teamSizeController.text = doc['teamSize'].toString();
          _benefitsController.text = doc['benefits'];
          _skills = List<String>.from(doc['skills']);
          _startDate = (doc['startDate'] as Timestamp).toDate();
          _endDate = (doc['endDate'] as Timestamp).toDate();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load recruitment data: $e")),
      );
    }
  }

  // Submit the edited recruitment form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all required fields.")),
      );
      return;
    }

    final String projectName = _projectNameController.text.trim();
    final String description = _descriptionController.text.trim();
    final String teamSize = _teamSizeController.text.trim();
    final String benefits = _benefitsController.text.trim();
    final User? user = _auth.currentUser;

    if (_startDate == null || _endDate == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("All fields including dates are required.")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('open_recruitments').doc(widget.recruitmentId).update({
        'projectName': projectName,
        'description': description,
        'teamSize': int.parse(teamSize),
        'benefits': benefits,
        'startDate': _startDate,
        'endDate': _endDate,
        'skills': _skills,
        'updatedBy': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Recruitment updated successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update recruitment: $e")),
      );
    }
  }

  // Delete the recruitment document
  Future<void> _deleteRecruitment() async {
    try {
      // Delete the recruitment document from Firestore
      await FirebaseFirestore.instance.collection('open_recruitments').doc(widget.recruitmentId).delete();

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Recruitment deleted successfully!")),
      );

      // Navigate to ViewExperiencesPage (or ViewProfilePage as intended) after successful deletion
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ViewProfilePage(), // Pass the correct userId here
        ),
      );
    } catch (e) {
      // Show an error message if the deletion fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete recruitment: $e")),
      );
    }
  }



  // Add skill to the list
  void _addSkill() {
    final String skill = _skillController.text.trim();
    if (skill.isNotEmpty) {
      setState(() {
        _skills.add(skill);
      });
      _skillController.clear();
    }
  }

  // Select a date (Start or End)
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2100);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRecruitmentData(); // Load data when the page is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Recruitment', style: TextStyle(color: Colors.white)),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                buildTextField('Project Name', _projectNameController),
                buildTextField('Description', _descriptionController, maxLines: 3),
                buildTextField('Number of Team Members Needed', _teamSizeController, keyboardType: TextInputType.number),
                buildTextField('Benefits', _benefitsController, maxLines: 3),
                SizedBox(height: 20),
                Text(
                  'Skills:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Expanded(
                      child: buildTextField('Enter skill', _skillController),
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
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildDateSelector('Start Date', _startDate, () => _selectDate(context, true)),
                    buildDateSelector('End Date', _endDate, () => _selectDate(context, false)),
                  ],
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: Text('Update Project'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Color(0xA8A790D8),
                      minimumSize: Size(double.infinity, 50),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _deleteRecruitment(),
                    child: Text('Delete Recruitment'),
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

  Widget buildTextField(String label, TextEditingController controller, {bool readOnly = false, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
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

  Widget buildDateSelector(String label, DateTime? date, VoidCallback onTap) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          ListTile(
            title: Text('${date != null ? DateFormat('yMMMd').format(date) : 'Select Date'}', style: TextStyle(color: Colors.white)),
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}
