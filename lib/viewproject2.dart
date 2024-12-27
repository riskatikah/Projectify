import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ViewProjectPage2 extends StatelessWidget {
  final String projectId;

  ViewProjectPage2({required this.projectId});

  Future<DocumentSnapshot> _fetchProjectData(String projectId) async {
    try {
      DocumentSnapshot projectSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .get();
      return projectSnapshot;
    } catch (e) {
      throw Exception("Error fetching project data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "View Project",
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
          future: _fetchProjectData(projectId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text("Project not found"));
            }

            var projectData = snapshot.data!.data() as Map<String, dynamic>;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gambar proyek menggunakan file lokal
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'images/project.png',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Nama proyek
                  _buildTextSection("Project Name", projectData['projectName'] ?? 'No Name'),
                  // Deskripsi proyek
                  _buildTextSection("Description", projectData['projectDescription'] ?? 'No Description'),
                  // Pembuat proyek
                  _buildTextSection("Created By", projectData['createdBy'] ?? 'Unknown'),
                  // Jurusan
                  _buildTextSection("Major", projectData['major'] ?? 'Not Available'),
                  // Tanggal dibuat dan sampai
                  _buildTextSection(
                    "Created Date",
                    projectData['createdDate'] != null
                        ? DateFormat('yyyy-MM-dd').format(projectData['createdDate'].toDate())
                        : 'Not Available',
                  ),
                  _buildTextSection(
                    "Until Date",
                    projectData['untilDate'] != null
                        ? DateFormat('yyyy-MM-dd').format(projectData['untilDate'].toDate())
                        : 'Not Available',
                  ),
                  SizedBox(height: 16),
                  // Skills
                  Text(
                    "Skills",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Wrap(
                    spacing: 8,
                    children: (projectData['skills'] as List<dynamic>? ?? [])
                        .map((skill) => Chip(
                      label: Text(skill, style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.grey[700],
                    ))
                        .toList(),
                  ),
                  SizedBox(height: 16),
                  // Tautan dokumen
                  GestureDetector(
                    onTap: () async {
                      final documentLink = projectData['documentLink'];
                      if (documentLink != null && documentLink.isNotEmpty) {
                        try {
                          final uri = Uri.parse(documentLink);
                          if (await canLaunchUrl(uri)) {
                            launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not open the document link')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invalid URL')),
                          );
                        }
                      }
                    },
                    child: Text(
                      "Open Document",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
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
