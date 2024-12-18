import 'package:bismillah/view_profile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';  // Import package intl untuk format tanggal
import 'edit_project.dart'; // Mengimpor halaman edit proyek

class ViewProjectPage extends StatelessWidget {
  final String projectId;

  ViewProjectPage({required this.projectId});

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
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ViewProfilePage()),
            );
          },
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
                  // Gambar proyek
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: projectData['imageUrl'] != null && projectData['imageUrl'] != ''
                        ? Image.network(
                      projectData['imageUrl'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    )
                        : Image.asset(
                      'images/placeholder.png', // Gambar placeholder dari assets
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Nama proyek
                  Text(
                    "Project Name",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    projectData['projectName'] ?? 'No Name',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  // Deskripsi proyek
                  Text(
                    "Description",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    projectData['projectDescription'] ?? 'No Description',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  // Pembuat proyek
                  Text(
                    "Created By",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    projectData['createdBy'] ?? 'Unknown',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  // Jurusan
                  Text(
                    "Major",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    projectData['major'] ?? 'Not Available',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  // Tautan dokumen
                  GestureDetector(
                    onTap: () async {
                      final documentLink = projectData['documentLink'];
                      if (documentLink != null && documentLink.isNotEmpty) {
                        try {
                          final uri = Uri.parse(documentLink);
                          if (await canLaunch(uri.toString())) {
                            launchUrl(uri);
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
                  SizedBox(height: 16),
                  // Tanggal dibuat dan sampai
                  Text(
                    "Created Date",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    projectData['createdDate'] != null
                        ? DateFormat('yyyy-MM-dd').format(projectData['createdDate'].toDate())
                        : 'Not Available',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Until Date",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    projectData['untilDate'] != null
                        ? DateFormat('yyyy-MM-dd').format(projectData['untilDate'].toDate())
                        : 'Not Available',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  // Tombol Edit
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProjectPage(projectId: projectId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        backgroundColor: Color(0xA8A790D8),
                        minimumSize: Size(double.infinity, 50),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Edit Project', style: TextStyle(fontSize: 16)),
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
}
