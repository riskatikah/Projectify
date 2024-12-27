import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'apply.dart';

class ViewRecruitmentPage extends StatelessWidget {
  final String recruitmentId;

  const ViewRecruitmentPage({Key? key, required this.recruitmentId}) : super(key: key);

  Future<DocumentSnapshot> _fetchRecruitmentData(String recruitmentId) async {
    try {
      DocumentSnapshot recruitmentSnapshot = await FirebaseFirestore.instance
          .collection('open_recruitments')
          .doc(recruitmentId)
          .get();
      return recruitmentSnapshot;
    } catch (e) {
      throw Exception("Error fetching recruitment data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "View Recruitment",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/homepage2.png'), // Background Image
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<DocumentSnapshot>(
          future: _fetchRecruitmentData(recruitmentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text("Recruitment not found"));
            }

            var recruitmentData = snapshot.data!.data() as Map<String, dynamic>;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'images/reqtim.png', // Gambar lokal yang digunakan
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Project Name
                  _buildTextSection("Project Name", recruitmentData['projectName'] ?? 'No Name'),
                  // Description
                  _buildTextSection("Description", recruitmentData['description'] ?? 'No Description'),
                  // Team Size
                  _buildTextSection("Team Size", recruitmentData['teamSize']?.toString() ?? 'Not Available'),
                  // Benefits
                  _buildTextSection("Benefits", recruitmentData['benefits'] ?? 'Not Available'),
                  // Start Date
                  _buildTextSection(
                    "Start Date",
                    recruitmentData['startDate'] != null
                        ? DateFormat('yyyy-MM-dd').format((recruitmentData['startDate'] as Timestamp).toDate())
                        : 'Not Available',
                  ),
                  // End Date
                  _buildTextSection(
                    "End Date",
                    recruitmentData['endDate'] != null
                        ? DateFormat('yyyy-MM-dd').format((recruitmentData['endDate'] as Timestamp).toDate())
                        : 'Not Available',
                  ),
                  SizedBox(height: 16),
                  // Skills Section
                  Text(
                    "Skills",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Wrap(
                    spacing: 8,
                    children: (recruitmentData['skills'] as List<dynamic>? ?? [])
                        .map((skill) => Chip(
                      label: Text(skill, style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.grey[700],
                    ))
                        .toList(),
                  ),
                  SizedBox(height: 16),
                  // Apply Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ApplyPage(
                              recruitmentId: recruitmentId,
                              projectName: recruitmentData['projectName'],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        backgroundColor: Color(0xA8A790D8),
                        minimumSize: Size(double.infinity, 50),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Apply', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextSection(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
