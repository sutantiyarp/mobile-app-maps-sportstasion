import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bi_mistik/pages/login_page.dart';
import 'package:bi_mistik/pages/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://gvjcirfyqalgczuioskd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2amNpcmZ5cWFsZ2N6dWlvc2tkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyOTc2MDUsImV4cCI6MjA5NTg3MzYwNX0.Wf_rOYD4dsieqkqX3kiHHuJUdA9MScIltC_pdst0SVc',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BI MISTIK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F9FB), // Halaman Dasar Baru
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7D99B6), // Primary
          primary: const Color(0xFF7D99B6),
          secondary: const Color(0xFF69487D), // Secondary
          surface: const Color(0xFFF7F9FB),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF213049), fontWeight: FontWeight.bold), // Teks
          bodyLarge: TextStyle(color: Color(0xFF213049)),
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/welcome_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Radial Grey Overlay (Fades from solid grey at edges to transparent at center)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.2, 1.0],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  const Text(
                    'BI MISTIK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const Text(
                    '"Bersamamu dengan Hobiku"',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Spacer(),
                  // Button Mulai
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD8C494), // Button color
                        foregroundColor: const Color(0xFF213049), // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Mulai',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Logo & Brand Bottom
                  Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 50,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'BI MISTIK',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
