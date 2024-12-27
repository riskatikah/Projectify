import 'package:bismillah/ViewRecruitmentPage.dart';
import 'package:bismillah/service/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                      // FutureBuilder for Open Recruitment
                      const SizedBox(height: 10),
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance.collection('open_recruitments').get(),
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
                                'No open recruitments found.',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            );
                          }

                          var recruitments = snapshot.data!.docs;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _getGridColumnCount(context),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1,
                            ),
                            itemCount: recruitments.length,
                            itemBuilder: (context, index) {
                              var recruitment = recruitments[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ViewRecruitmentPage(
                                        recruitmentId: recruitment.id,
                                      ),
                                    ),
                                  );
                                },
                                child: _buildRecruitmentItem(
                                  recruitment['projectName'] ?? 'No Name',
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

  // Modified _buildRecruitmentItem function to use a local image
  Widget _buildRecruitmentItem(String projectName) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6FF),
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
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'images/reqtim.png', // Use the local image
              height: 150,
              width: 150,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            projectName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
