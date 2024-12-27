import 'package:bismillah/profileuser.dart';
import 'package:bismillah/recruitment.dart';
import 'package:bismillah/service/auth_provider.dart';
import 'package:bismillah/splash_screen.dart';
import 'package:bismillah/submit_project.dart';
import 'package:bismillah/view_application.dart';
import 'package:bismillah/view_profile.dart';
import 'package:bismillah/view_project.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'edit_profile.dart';
import 'forgetpass.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'notif.dart';
import 'service/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProv(),
      child: MyApp(),
    ),);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {
        '/home_page': (context) => HomePage(),
        '/forget_password': (context) => PasswordRecoveryScreen(),
        '/submit_project': (context) => SubmitProjectPage(),
        '/view_project': (context) => ViewProjectPage(projectId: '',),
        '/view_profile': (context) => ViewProfilePage(),
        '/login_page': (context) => LoginPage(),
        '/edit_profile': (context) => EditProfilePage(),
        '/notif' : (context) => TeamNotificationsPage(),
        '/submitreq' : (context) => SubmitRecruitmentPage(),
        '/userprofile' : (context) => UserProfilePage(userId: '',),
        '/view_experiences' : (context) => ViewApplicationPage(applicationId: '',),
      },
    );
  }
}
