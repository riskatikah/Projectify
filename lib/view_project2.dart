import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

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
                        : Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey[700],
                      ),
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
                    onTap: () {
                      if (projectData['documentLink'] != null &&
                          projectData['documentLink'].isNotEmpty) {
                        _launchURL(projectData['documentLink']);
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
                        ? projectData['createdDate'].toDate().toString().split(' ')[0]
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
                        ? projectData['untilDate'].toDate().toString().split(' ')[0]
                        : 'Not Available',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Fungsi untuk membuka URL dokumen
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not open the URL: $url';
    }
  }
}
