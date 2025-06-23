import 'package:flutter/material.dart';
import 'package:work_line/screens/authentication_screen.dart';
import 'package:work_line/screens/registration_screen.dart';

class WorkLineApp extends StatelessWidget {
  const WorkLineApp({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFEFF1F3);

    return MaterialApp(
      title: 'Work Line',
      theme: ThemeData(
        scaffoldBackgroundColor: primaryColor,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.light),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) =>  AuthenticationScreen(), 
        '/register': (context) =>  RegistrationScreen(), 
      },
    );
  }
}
