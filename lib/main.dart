import 'package:flutter/material.dart';
import 'register.dart';

import 'login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym App',
      theme: ThemeData(
        useMaterial3: true,
        
        brightness: Brightness.dark,
        
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.yellowAccent,      
          selectionColor: Colors.yellowAccent,   
          selectionHandleColor: Colors.yellowAccent, 
        ),

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellowAccent,
          primary: Colors.yellowAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const Login(),
    );
  }
}