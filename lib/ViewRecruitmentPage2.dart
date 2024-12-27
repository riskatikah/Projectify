import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'edit_reqtim.dart';

class ViewRecruitmentPage2 extends StatelessWidget {
  final String recruitmentId;

  const ViewRecruitmentPage2({Key? key, required this.recruitmentId}) : super(key: key);

  Future<DocumentSnapshot?> _fetchRecruitmentData(String recruitmentId) async {
    try {
      DocumentSnapshot recruitmentSnapshot = await FirebaseFirestore.instance
          .collection('open_recruitments')
          .doc(recruitmentId)
          .get();

      if (!recruitmentSnapshot.exists) {
        return null; // Handle if the document does not exist
      }
      return recruitmentSnapshot;
    } catch (e) {
      debugPrint("Error fetching recruitment data: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "View Recruitment",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/homepage2.png'), // Background Image
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<DocumentSnapshot?>(
          future: _fetchRecruitmentData(recruitmentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("Recruitment not found"));
            }

            var recruitmentData = snapshot.data!.data() as Map<String, dynamic>?;

            if (recruitmentData == null) {
              return const Center(child: Text("No data available"));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'images/reqtim.png', // Gambar lokal yang digunakan
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Display project details
                  _buildTextSection("Project Name", recruitmentData['projectName'] ?? 'No Name'),
                  _buildTextSection("Description", recruitmentData['description'] ?? 'No Description'),
                  _buildTextSection("Team Size", recruitmentData['teamSize']?.toString() ?? 'Not Available'),
                  _buildTextSection("Benefits", recruitmentData['benefits'] ?? 'Not Available'),
                  _buildTextSection(
                    "Start Date",
                    recruitmentData['startDate'] != null
                        ? DateFormat('yyyy-MM-dd').format((recruitmentData['startDate'] as Timestamp).toDate())
                        : 'Not Available',
                  ),
                  _buildTextSection(
                    "End Date",
                    recruitmentData['endDate'] != null
                        ? DateFormat('yyyy-MM-dd').format((recruitmentData['endDate'] as Timestamp).toDate())
                        : 'Not Available',
                  ),
                  const SizedBox(height: 16),
                  // Skills Section
                  const Text(
                    "Skills",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Wrap(
                    spacing: 8,
                    children: (recruitmentData['skills'] as List<dynamic>? ?? [])
                        .map((skill) => Chip(
                      label: Text(skill, style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.grey[700],
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  // Edit Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditRecruitmentPage(
                              recruitmentId: recruitmentId,
                              projectName: recruitmentData['projectName'],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        backgroundColor: const Color(0xA8A790D8),
                        minimumSize: const Size(double.infinity, 50),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Edit', style: TextStyle(fontSize: 16)),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
