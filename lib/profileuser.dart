import 'package:bismillah/viewproject2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfilePage extends StatelessWidget {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);  // Go back to the previous screen
                },
              ),
              const SizedBox(width: 8),
              FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(userId).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Loading...',
                      style: TextStyle(color: Colors.white),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                    return const Text(
                      'Error loading username',
                      style: TextStyle(color: Colors.white),
                    );
                  }

                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  final username = userData['username'] ?? 'Unknown User';
                  return Text(
                    username,
                    style: const TextStyle(color: Colors.white),
                  );
                },
              ),
            ],
          ),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
        ),
        body: FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(userId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text('Error loading profile data', style: TextStyle(color: Colors.red)),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final String username = userData['username'] ?? 'Unknown User';
            final String? email = userData['email'];
            final String description = userData['description'] ?? 'No Description';

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(email, description),
                  _buildSkillsSection(userId),
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'Project Experience', '/submit_project'),
                  _buildProjectList(userId),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String? email, String description) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage('images/user.jpg'), // Placeholder image
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email ?? 'No Email',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  softWrap: true,
                  overflow: TextOverflow.fade,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(String userId) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore.collection('projects').where('userId', isEqualTo: userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading skills', style: TextStyle(color: Colors.red)));
        }

        final skillsSet = <String>{};

        if (snapshot.hasData) {
          for (var project in snapshot.data!.docs) {
            final List<dynamic>? skills = project['skills'] as List<dynamic>?;
            if (skills != null) {
              skillsSet.addAll(skills.cast<String>());
            }
          }
        }

        if (skillsSet.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No skills found.', style: TextStyle(color: Colors.white)),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 8,
            children: skillsSet.map((skill) {
              return Chip(
                label: Text(skill, style: const TextStyle(color: Colors.white)),
                backgroundColor: Colors.grey[700],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            'See More',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('projects')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading projects', style: TextStyle(color: Colors.red)),
          );
        }

        if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No projects submitted yet.', style: TextStyle(color: Colors.white)),
          );
        }

        if (snapshot.hasData) {
          final items = snapshot.data!.docs;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];
              return _buildProjectItem(context, item);
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildProjectItem(BuildContext context, QueryDocumentSnapshot item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ViewProjectPage2(projectId: item.id)),
      ),
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[800],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                child: Image.asset(
                  'images/project.png', // Placeholder image
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['projectName'] ?? 'No Title',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['projectDescription'] ?? 'No Description',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
