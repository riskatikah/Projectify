import 'package:bismillah/recruitment.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bismillah/service/auth_provider.dart';

import 'ViewRecruitmentPage2.dart';

class ViewExperiencesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProv>(context);
    final userEmail = authProvider.email;

    if (userEmail == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Activity', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Please log in to view your activity.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('View Activity', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white), // Tanda panah menjadi putih
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            tooltip: 'Submit Recruitment',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SubmitRecruitmentPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('open_recruitments')
            .where('createdBy', isEqualTo: authProvider.user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading experiences',
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No experiences available.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final experiences = snapshot.data!.docs;
          return ListView.builder(
            itemCount: experiences.length,
            itemBuilder: (context, index) {
              final experience = experiences[index];
              return _buildExperienceItem(context, experience);
            },
          );
        },
      ),
    );
  }

  Widget _buildExperienceItem(BuildContext context, QueryDocumentSnapshot experience) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke ViewRecruitmentPage dengan recruitmentId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewRecruitmentPage2(
              recruitmentId: experience.id, // Kirim recruitmentId
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.all(8.0),
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                child: Image.asset(
                  'images/reqtim.png', // Gambar lokal yang digunakan
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    experience['projectName'] ?? 'No Title',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    experience['description'] ?? 'No Description',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  if (experience['startDate'] != null && experience['endDate'] != null)
                    Text(
                      'Duration: ${DateFormat('yMMMd').format((experience['startDate'] as Timestamp).toDate())} - ${DateFormat('yMMMd').format((experience['endDate'] as Timestamp).toDate())}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
