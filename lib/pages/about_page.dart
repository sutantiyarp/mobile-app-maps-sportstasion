import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  // Logo & Version Section
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF69487D).withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Image.asset('assets/images/logo.png', height: 100),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'BI MISTIK',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF213049),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Text(
                    'Versi 1.0.0',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 40),

                  // Description Card
                  _buildAboutCard(
                    title: 'Filosofi Kami',
                    content:
                        'BI MISTIK lahir dari semangat "Bersamamu dengan Hobiku". Kami percaya bahwa setiap smash dan langkah di lapangan adalah bentuk dedikasi. Aplikasi ini hadir untuk memudahkan para pecinta bulutangkis menemukan perlengkapan terbaik dengan cepat dan akurat.',
                    icon: Icons.auto_awesome,
                  ),
                  const SizedBox(height: 20),

                  // Vision & Mission Section
                  Row(
                    children: [
                      Expanded(
                        child: _buildSmallInfo(
                          Icons.location_on_outlined,
                          'Navigasi Akurat',
                          'Menjangkau toko terdekat.',
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildSmallInfo(
                          Icons.workspace_premium_outlined,
                          'Sistem Reward',
                          'Apresiasi untuk hobi Anda.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Community Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF69487D), Color(0xFF7D99B6)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: const [
                        Text(
                          '"Smash Tiap Tantangan"',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Terima kasih telah menjadi bagian dari komunitas Bi Mistik. Mari kembangkan olahraga bulutangkis Indonesia bersama-sama!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  const Text(
                    'Developed with ❤️ by Tim Bi Mistik',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 11),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF7D99B6),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF213049)),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Tentang Aplikasi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF213049),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutCard({required String title, required String content, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFD8C494)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF213049),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            content,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF69487D)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
