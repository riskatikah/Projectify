import 'package:bismillah/service/auth_provider.dart';
import 'package:bismillah/view_application.dart';
import 'package:bismillah/viewapplications_user.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class TeamNotificationsPage extends StatefulWidget {
  const TeamNotificationsPage({Key? key}) : super(key: key);

  @override
  _TeamNotificationsPageState createState() => _TeamNotificationsPageState();
}

class _TeamNotificationsPageState extends State<TeamNotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProv>(
      builder: (context, authProv, child) {
        if (authProv.user == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Invitation', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.black,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("You must be logged in to view this page."),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text("Login"),
                  ),
                ],
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(
                "Invitation",
                style: TextStyle(color: Colors.black), // Tidak ada properti backgroundColor di sini
              ),
              backgroundColor: Colors.white, // Warna latar belakang AppBar
              elevation: 1,
              centerTitle: true, // Menempatkan teks di tengah
              automaticallyImplyLeading: false, // Menghapus tanda panah kembali
              bottom: const TabBar(
                indicatorColor: Colors.black,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: "Sent"),
                  Tab(text: "Received"),
                ],
              ),
            ),
            backgroundColor: Colors.grey[200],
            body: TabBarView(
              children: [
                SentApplicationsTab(firestore: _firestore),
                ReceivedApplicationsTab(firestore: _firestore),
              ],
            ),
            bottomNavigationBar: _buildBottomNavigationBar(context),
          ),
        );
      },
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
}

class SentApplicationsTab extends StatefulWidget {
  final FirebaseFirestore firestore;

  const SentApplicationsTab({Key? key, required this.firestore}) : super(key: key);

  @override
  _SentApplicationsTabState createState() => _SentApplicationsTabState();
}

class _SentApplicationsTabState extends State<SentApplicationsTab> {
  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProv>(context, listen: false);

    return StreamBuilder<QuerySnapshot>(
      stream: widget.firestore
          .collection('team_applications')
          .where('userId', isEqualTo: authProv.user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final applications = snapshot.data!.docs;

        if (applications.isEmpty) {
          return const Center(
            child: Text(
              "You have no applications.",
              style: TextStyle(color: Colors.black87),
            ),
          );
        }

        return ListView.builder(
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final application = applications[index];
            String projectName = application['projectName'] ?? 'No project name';
            String status = application['status'] ?? 'pending';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                title: Text(projectName, style: const TextStyle(color: Colors.black87)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(application['email'], style: const TextStyle(color: Colors.grey)),
                    if (status == 'rejected') // Tambahkan jika statusnya "rejected"
                      Text(
                        'Status: Rejected',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                trailing: status == 'pending'
                    ? IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _cancelApplication(application.id),
                )
                    : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'accepted' ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status == 'accepted' ? 'Proses' : 'Rejected',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewApplicationPage(applicationId: application.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _cancelApplication(String id) async {
    try {
      await widget.firestore.collection('team_applications').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application has been canceled.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel application: $e')),
      );
    }
  }
}


class ReceivedApplicationsTab extends StatefulWidget {
  final FirebaseFirestore firestore;

  const ReceivedApplicationsTab({Key? key, required this.firestore}) : super(key: key);

  @override
  _ReceivedApplicationsTabState createState() => _ReceivedApplicationsTabState();
}

class _ReceivedApplicationsTabState extends State<ReceivedApplicationsTab> {
  late Future<List<String>> _recruitmentIds;

  @override
  void initState() {
    super.initState();
    final authProv = Provider.of<AuthProv>(context, listen: false);
    _recruitmentIds = _getRecruitmentIds(authProv.user!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _recruitmentIds,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading applications: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'You have no open recruitments.',
              style: TextStyle(color: Colors.black87),
            ),
          );
        }

        final recruitmentIds = snapshot.data!;
        return StreamBuilder<QuerySnapshot>(
          stream: widget.firestore
              .collection('team_applications')
              .where('recruitmentId', whereIn: recruitmentIds)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'You have no pending applications.',
                  style: TextStyle(color: Colors.black87),
                ),
              );
            }

            final applications = snapshot.data!.docs;
            return ListView.builder(
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final application = applications[index];
                String projectName = application['projectName'] ?? 'No project name';
                String applicantName = application['name'] ?? 'No Name';
                String applicantEmail = application['email'] ?? 'No Email';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewApplicationPage2(applicationId: application.id),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      title: Text(applicantName, style: const TextStyle(color: Colors.black87)),
                      subtitle: Text('$applicantEmail\nApplied for: $projectName', style: const TextStyle(color: Colors.grey)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _updateApplicationStatus(application.id, 'accepted'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _updateApplicationStatus(application.id, 'rejected'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<String>> _getRecruitmentIds(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('open_recruitments')
        .where('createdBy', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<void> _updateApplicationStatus(String id, String status) async {
    await widget.firestore.collection('team_applications').doc(id).update({'status': status});
  }
}
