import 'package:flutter/material.dart';
import 'package:women_safety/Login.dart';
import 'package:women_safety/Storiespage1.dart';
import 'package:women_safety/LawyerRecommend.dart';
import 'package:women_safety/Report.dart';
import 'package:women_safety/SignUp.dart';  // Import the SignUp page
import 'package:women_safety/chatbot.dart';
import 'package:women_safety/mapscreen.dart';
import 'maps.dart'; // Import the maps.dart file
import 'package:firebase_core/firebase_core.dart';
import 'matchem.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyA0f8QeJovJsiOtQnIHUY6dciYWzBHn2iY",
      appId: "1:409806951976:web:06f13fb4d98036a075071d",
      messagingSenderId: "409806951976",
      projectId: "mubh-16ab0",
    ),
  );

  runApp(const MyApp()); // No need to pass initialization here
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false, // Disable debug banner
      initialRoute: '/login',
      routes: {
        '/signup': (context) => SignUpPage(),
        '/login': (context) => LoginPage(),
        '/stories': (context) => StoriesPage(),
        '/lawyerrecommend': (context) => LawyerRecommendationApp(),
        '/report': (context) => ReportPage(),
        '/maps': (context) => WomenSafetyApp(),
        '/maps1': (context) => MapScreen(),
        '/chatbot': (context) => WebPage(),
      },
    );
  }
}
