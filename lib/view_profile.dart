import 'package:bismillah/service/auth_provider.dart';
import 'package:bismillah/login_page.dart';
import 'package:bismillah/view_project.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bismillah/view_activity.dart';

class ViewProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProv>(context);
    final String username = authProvider.username ?? 'Guest';
    final String? email = authProvider.email;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(username, style: TextStyle(color: Colors.white)),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
        ),
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(authProvider.user?.uid).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading profile data',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text(
                  'User data not found',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final String description = userData['description'] ?? 'No Description';

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(email, description),
                  _buildSkillsSection(authProvider.user?.uid),
                  _buildProfileActions(context),
                  SizedBox(height: 16),
                  _buildActivityButton(context),
                  _buildSectionTitle(context, 'Project Experience', '/submit_project'),
                  _buildProjectList(email),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context),
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
            backgroundImage: AssetImage('images/user.jpg'),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email ?? 'No Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
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

  Widget _buildSkillsSection(String? userId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('projects')
          .where('userId', isEqualTo: userId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading skills',
              style: TextStyle(color: Colors.red),
            ),
          );
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
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('No skills found.', style: TextStyle(color: Colors.white)),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 8,
            children: skillsSet.map((skill) {
              return Chip(
                label: Text(skill, style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.grey[700],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildProfileActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
            child: Text('Edit Profile'),
          ),
          ElevatedButton(
            onPressed: () => _showLogoutDialog(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ViewExperiencesPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          padding: EdgeInsets.symmetric(vertical: 12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 8),
            Text(
              'View Activities',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              if (title == 'Project Experience') {
                Navigator.pushNamed(context, route);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList(String? email) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .where('createdBy', isEqualTo: email)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No projects submitted yet.', style: TextStyle(color: Colors.white)),
          );
        }
        if (snapshot.hasData) {
          final items = snapshot.data!.docs;
          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];
              return _buildProjectItem(context, item);
            },
          );
        }
        return SizedBox();
      },
    );
  }

  Widget _buildProjectItem(BuildContext context, QueryDocumentSnapshot item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewProjectPage(projectId: item.id),
        ),
      ),
      child: Container(
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(16),
        decoration: _buildBoxDecoration(),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                child: Image.asset(
                  'images/project.png', // Gambar lokal
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
                    item['projectName'] ?? 'No Title',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    item['projectDescription'] ?? 'No Description',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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

  BoxDecoration _buildBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomAppBar(
      color: const Color(0xA8A790D8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/home_page');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white, size: 35),
            onPressed: () {
              Navigator.pushNamed(context, '/notif');
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/view_profile');
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Center(
            child: Text(
              'Do you want to logout?',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Provider.of<AuthProv>(context, listen: false).signOut();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                          (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xA8A790D8)),
                  child: const Text('Yes', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200]),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
