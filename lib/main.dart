import 'package:flutter/material.dart';
import 'pages/sign_in.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Theme state is held here
  bool isDarkMode = true;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void handleLogin() {
    print("Login triggered");
    // Navigate to Dashboard here
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UniTap',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      scrollBehavior: AppScrollBehavior(),
      home: SignIn(
        isDarkMode: isDarkMode,
        onToggleTheme: toggleTheme,
        onLogin: handleLogin,
      ),
    );
  }
}
