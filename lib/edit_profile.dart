import 'package:bismillah/service/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _oldPasswordController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _passwordConfirmController = TextEditingController();
  TextEditingController _majorController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProv>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _usernameController.text = authProvider.username ?? '';
        _emailController.text = authProvider.email ?? '';
        _majorController.text = authProvider.major ?? '';
        _descriptionController.text = authProvider.description ?? '';
      });
    });
  }

  Future<void> _updateProfile() async {
    final authProvider = Provider.of<AuthProv>(context, listen: false);
    setState(() {
      _isLoading = true;
    });

    try {
      if (_usernameController.text.isEmpty) {
        throw Exception('Username cannot be empty');
      }

      if (_oldPasswordController.text.isNotEmpty) {
        final credential = EmailAuthProvider.credential(
          email: authProvider.email!,
          password: _oldPasswordController.text,
        );
        try {
          await authProvider.user!.reauthenticateWithCredential(credential);
        } catch (e) {
          throw Exception('Old password is incorrect');
        }
      }

      if (_emailController.text != authProvider.email) {
        await authProvider.user!.updateEmail(_emailController.text);
      }

      if (_passwordController.text.isNotEmpty) {
        if (_passwordController.text != _passwordConfirmController.text) {
          throw Exception('New password and confirm password do not match');
        }
        await authProvider.user!.updatePassword(_passwordController.text);
      }

      final userDoc = FirebaseFirestore.instance.collection('users').doc(authProvider.user!.uid);

      await userDoc.update({
        'email': _emailController.text,
        'username': _usernameController.text,
        'major': _majorController.text,
        'description': _descriptionController.text,
      });

      authProvider.notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount(String password) async {
    final authProvider = Provider.of<AuthProv>(context, listen: false);
    setState(() {
      _isLoading = true;
    });

    try {
      final user = authProvider.user;
      final credential = EmailAuthProvider.credential(
        email: authProvider.email!,
        password: password,
      );

      // Reauthenticate the user
      await user!.reauthenticateWithCredential(credential);

      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Delete documents in 'projects' collection where 'userId' matches
      final userProjects = FirebaseFirestore.instance
          .collection('projects')
          .where('userId', isEqualTo: user.uid);
      final userProjectsSnapshot = await userProjects.get();

      for (var projectDoc in userProjectsSnapshot.docs) {
        await projectDoc.reference.delete();
      }

      // Delete documents in 'team_applications' collection where 'userId' matches
      final userApplications = FirebaseFirestore.instance
          .collection('team_applications')
          .where('userId', isEqualTo: user.uid);
      final userApplicationsSnapshot = await userApplications.get();

      for (var applicationDoc in userApplicationsSnapshot.docs) {
        await applicationDoc.reference.delete();
      }

      // Delete documents in 'open_recruitments' collection where 'uid' matches
      final openRecruitments = FirebaseFirestore.instance
          .collection('open_recruitments')
          .where('uid', isEqualTo: user.uid);
      final openRecruitmentsSnapshot = await openRecruitments.get();

      for (var recruitmentDoc in openRecruitmentsSnapshot.docs) {
        await recruitmentDoc.reference.delete();
      }

      // Finally, delete the user document and the auth account
      await userDoc.delete();
      await user.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account and all associated data deleted successfully!')),
      );

      Navigator.pushReplacementNamed(context, '/login_page');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  void _confirmDeleteAccount() {
    _passwordConfirmController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please enter your password to confirm account deletion.',
                style: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _passwordConfirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount(_passwordConfirmController.text);
              },
              child: Text('Delete'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProv>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/homepage2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('images/user.jpg'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.white),
                  hintText: 'Enter username',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white),
                  hintText: 'Enter email',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _majorController,
                decoration: InputDecoration(
                  labelText: 'Lecture/Student Major',
                  labelStyle: TextStyle(color: Colors.white),
                  hintText: 'Enter your major',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white),
                  hintText: 'Enter description',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _oldPasswordController,
                obscureText: !_isOldPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Old Password',
                  labelStyle: TextStyle(color: Colors.white),
                  hintText: 'Enter old password',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isOldPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isOldPasswordVisible = !_isOldPasswordVisible;
                      });
                    },
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: !_isNewPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: Colors.white),
                  hintText: 'Enter new password',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordConfirmController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: TextStyle(color: Colors.white),
                  hintText: 'Confirm password',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('Update Profile'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Color(0xA8A790D8),
                  minimumSize: Size(double.infinity, 50),
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _confirmDeleteAccount,
                child: Text('Delete Account'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Color(0xA8A790D8),
                  minimumSize: Size(double.infinity, 50),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
