import 'package:bismillah/service/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_project2.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProv>(context);
    String username = authProvider.username ?? 'Guest';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/homepage2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Hello, $username',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tagline Section
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFF000000),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Image.asset(
                            'images/taglinee.png',
                            fit: BoxFit.contain,
                            height: 250,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // FutureBuilder for Projects
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance.collection('projects').get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text(
                                'No projects found.',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            );
                          }

                          var projects = snapshot.data!.docs;
                          return GridView.builder(
                            shrinkWrap: true, // Ensures GridView adapts to its content
                            physics: NeverScrollableScrollPhysics(), // Disable GridView's internal scrolling
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _getGridColumnCount(context), // Dynamic column count
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1, // Makes the grid items square
                            ),
                            itemCount: projects.length,
                            itemBuilder: (context, index) {
                              var project = projects[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ViewProjectPage2(
                                        projectId: project.id,
                                      ),
                                    ),
                                  );
                                },
                                child: _buildProjectItem(
                                  project['projectName'] ?? 'No Name',
                                  project['imageUrl'] ?? '',
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
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
              icon: const Icon(Icons.add_circle, color: Colors.white, size: 35),
              onPressed: () {
                Navigator.pushNamed(context, '/submit_project');
              },
            ),
            IconButton(
              icon: const Icon(Icons.people, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/view_profile');
              },
            ),
          ],
        ),
      ),
    );
  }

  // Function to determine the number of columns based on screen width
  int _getGridColumnCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 4; // Large screens (desktops)
    } else if (width > 800) {
      return 3; // Medium screens (tablets)
    } else {
      return 2; // Small screens (mobile)
    }
  }

  // Improved _buildProjectItem function
  Widget _buildProjectItem(String projectName, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6FF), // Background color for project card
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12), // Rounded corners for the image
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              height: 150, // Adjusted size for the image
              width: 150,
              fit: BoxFit.cover, // Ensures the image scales properly
            )
                : Container(
              height: 150,
              width: 150,
              color: Colors.grey[300],
              child: Icon(Icons.image, size: 50, color: Colors.grey[700]), // Placeholder for missing image
            ),
          ),
          const SizedBox(height: 2), // Spacing between the image and the text
          Text(
            projectName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18, // Font size for project name
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
