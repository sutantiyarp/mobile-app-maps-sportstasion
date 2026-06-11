import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bi_mistik/pages/profile_page.dart';
import 'package:bi_mistik/pages/notification_page.dart';
import 'package:bi_mistik/pages/map_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final User? user = Supabase.instance.client.auth.currentUser;
  bool _hasUnreadNotification = false;

  @override
  void initState() {
    super.initState();
    _checkNotifications();
  }

  Future<void> _checkNotifications() async {
    try {
      final nData = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', user!.id)
          .eq('is_read', false)
          .limit(1);
      if (mounted) {
        setState(() {
          _hasUnreadNotification = (nData as List).isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = user?.userMetadata?['username'] ?? user?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          // Top Navbar with Hex Color 7D99B6
          Container(
            width: double.infinity,
            color: const Color(0xFF7D99B6),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bi Mistik',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF213049), // Teks tetap gelap agar kontras
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationPage()),
                            ).then((_) => _checkNotifications()); // Refresh saat kembali
                          },
                          child: Stack(
                            children: [
                              const Icon(Icons.notifications_none, size: 28, color: Color(0xFF213049)),
                              if (_hasUnreadNotification)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF7D99B6), width: 2),
                                    ),
                                  ),
                                )
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Icon(Icons.settings_outlined, size: 28, color: Color(0xFF213049)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Welcome Banner
                  Container(
                    width: double.infinity,
                    height: 160,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6548AD), // Warna dasar ungu solid
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // Gambar dengan ShaderMask yang transisinya lebih panjang
                        Positioned.fill(
                          child: ShaderMask(
                            shaderCallback: (rect) {
                              return const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.transparent,
                                  Colors.white,
                                ],
                                // Transisi diperhalus: 0.1 sampai 0.9
                                stops: [0.1, 0.9], 
                              ).createShader(rect);
                            },
                            blendMode: BlendMode.dstIn,
                            child: Image.asset(
                              'assets/images/welcome_box.png',
                              fit: BoxFit.fitHeight,
                              // Alignment dikurangi agar gambar tidak "keluar" dari box
                              alignment: const Alignment(1.2, 0.0), 
                            ),
                          ),
                        ),

                        // Overlay Ungu dengan gradasi yang lebih lebar dan tanpa "stop" tajam
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6548AD),
                                const Color(0xFF6548AD).withOpacity(0.0),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              // Mulai memudar dari 30% lebar box sampai 80%
                              stops: const [0.3, 0.8], 
                            ),
                          ),
                        ),

                        // Content (Text)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Selamat pagi,\n$displayName! ☀️',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Ayo keluarkan keringat mu dengan\nolahraga hari ini!',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Ringkasanmu
                  const Text(
                    'Ringkasanmu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF213049),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Container(
                      width: 180,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.stars, color: Color(0xFFD8C494), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'TOTAL KUNJUNGAN',
                                style: TextStyle(
                                  color: Color(0xFFD8C494),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1.240',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF213049),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Misi Mingguan
                  const Text(
                    'Misi Mingguan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF213049),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF69487D).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF69487D).withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF213049).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_outline, color: Color(0xFF213049), size: 28),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Kunjungi 3 area minggu ini',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF213049),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Bonus 100 poin',
                                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF213049)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lapangan di Sekitarmu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lapangan di Sekitarmu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF213049),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(color: Color(0xFF7D99B6), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // List Toko
                  _buildStoreCard('Gedung Perintis', '', 'assets/images/welcome_bg.png', 'Lapangan Bulutangkis'),
                  _buildStoreCard('Gedung Assec', '', 'assets/images/welcome_bg.png', 'Lapangan Bulutangkis'),
                  const SizedBox(height: 20), 
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildStoreCard(String title, String subtitle, String imagePath, String infoText) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              imagePath,
              width: 85,
              height: 85,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF213049),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8C494).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Jadwalkan',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                ],
                if (infoText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    infoText,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF7D99B6)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 100, // Sedikit lebih tinggi untuk menampung shape background
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => setState(() => _selectedIndex = 0),
            child: _buildNavItem(Icons.home, 'Home', _selectedIndex == 0),
          ),
          _buildMapItem(),
          GestureDetector(
            onTap: () {
              setState(() => _selectedIndex = 2);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              ).then((_) => setState(() => _selectedIndex = 0));
            },
            child: _buildNavItem(Icons.person, 'Profile', _selectedIndex == 2),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0F0F0) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            color: isSelected ? const Color(0xFF7D99B6) : const Color(0xFF213049), 
            size: 28
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFF7D99B6) : const Color(0xFF213049),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

Widget _buildMapItem() {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = 1);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapPage()),
        ).then((_) => setState(() => _selectedIndex = 0));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF69487D), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.map_outlined, color: Color(0xFF213049), size: 30),
          ),
          const SizedBox(height: 4),
          const Text(
            'Map',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF213049),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
