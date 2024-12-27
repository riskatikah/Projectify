import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewApplicationPage extends StatelessWidget {
  final String applicationId;

  ViewApplicationPage({required this.applicationId});

  Future<DocumentSnapshot> _fetchApplicationData(String applicationId) async {
    try {
      DocumentSnapshot applicationSnapshot = await FirebaseFirestore.instance
          .collection('team_applications')
          .doc(applicationId)
          .get();
      return applicationSnapshot;
    } catch (e) {
      throw Exception("Error fetching application data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "View Application",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/homepage2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<DocumentSnapshot>(
          future: _fetchApplicationData(applicationId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text("Application not found"));
            }

            var applicationData = snapshot.data!.data() as Map<String, dynamic>;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name of the applicant
                  Text(
                    "Applicant Name",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    applicationData['name'] ?? 'No Name',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  // Email of the applicant
                  Text(
                    "Email",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    applicationData['email'] ?? 'No Email',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  // Portfolio URL
                  Text(
                    "Portfolio URL",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final url = applicationData['portfolio'];
                      if (url != null && url.isNotEmpty) {
                        if (await canLaunch(url)) {
                          await launch(url);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch the URL')));
                        }
                      }
                    },
                    child: Text(
                      applicationData['portfolio'] ?? 'No Portfolio',
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Motivation Text
                  Text(
                    "Motivation",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    applicationData['motivation'] ?? 'No Motivation Provided',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  // Skills section
                  Text(
                    "Skills",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Wrap(
                    spacing: 8,
                    children: (applicationData['skills'] as List<dynamic>? ?? [])
                        .map((skill) => Chip(
                      label: Text(skill ?? '', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.grey[700],
                    ))
                        .toList(),
                  ),
                  SizedBox(height: 16),
                  // Status of the application
                  Text(
                    "Application Status",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    applicationData['status'] ?? 'Pending',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
