import 'package:flutter/material.dart';
import 'screens/user_side/landing_page.dart';
import 'screens/user_side/user_profile.dart';
import 'screens/user_side/citizen_charter.dart';
import 'screens/user_side/sqd.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'V-Serve',
      initialRoute: '/',
      routes: {
        '/': (context) => LandingScreen(),      // Landing/main page
        '/profile': (context) => UserProfileScreen(), // User profile page
        '/citizenCharter': (context) => CitizenCharterScreen(),
        '/sqd': (context) => SQDScreen(),  // SQD page
        
        // Add other routes/screens here as you create them:
        // '/cc1': (context) => CC1Screen(), // Citizen's Charter Q1
        // ...
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
