import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bi_mistik/pages/profile/profile_page.dart';
import 'package:bi_mistik/pages/setting/notification_page.dart';
import 'package:bi_mistik/pages/map/map_page.dart';
import 'package:bi_mistik/pages/setting/settings_page.dart';
import 'package:bi_mistik/pages/home/near_places_page.dart';
import 'package:bi_mistik/pages/home/quest_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final User? user = Supabase.instance.client.auth.currentUser;
  bool _hasUnreadNotification = false;
  List<Map<String, dynamic>> _nearPlaces = [];
  bool _isLoadingPlaces = true;
  int _userPoints = 0;
  Position? _currentPosition;
  List<Map<String, dynamic>> _activeMissions = [];

  @override
  void initState() {
    super.initState();
    _checkNotifications();
    _fetchUserProfile();
    _fetchActiveMissions(); // Ambil data semua misi aktif
    _refreshData();
  }

  Future<void> _fetchActiveMissions() async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day).toIso8601String();
      final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day).toIso8601String();

      // 1. Ambil semua misi master (Urutkan berdasarkan ID agar daily_1 paling atas)
      final mData = await Supabase.instance.client
          .from('missions')
          .select()
          .order('id');
      
      // 2. Ambil semua klaim user
      final cData = await Supabase.instance.client
          .from('user_missions')
          .select('mission_id, completed_at')
          .eq('user_id', user!.id);

      List<Map<String, dynamic>> allMissions = List<Map<String, dynamic>>.from(mData);
      List<dynamic> allClaims = cData as List;
      List<Map<String, dynamic>> pendingMissions = [];

      for (var m in allMissions) {
        bool isClaimed = false;
        if (m['category'] == 'daily') {
          isClaimed = allClaims.any((c) => 
            c['mission_id'] == m['id'] && 
            DateTime.parse(c['completed_at']).isAfter(DateTime.parse(startOfToday))
          );
        } else {
          isClaimed = allClaims.any((c) => 
            c['mission_id'] == m['id'] && 
            DateTime.parse(c['completed_at']).isAfter(DateTime.parse(startOfWeek))
          );
        }

        if (!isClaimed) {
          pendingMissions.add(m);
        }
      }

      if (mounted) {
        setState(() {
          _activeMissions = pendingMissions;
        });
      }
    } catch (e) {
      debugPrint('Error fetch missions: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoadingPlaces = true);
    await _initLocation();
    await _fetchNearPlaces();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('points')
          .eq('id', user!.id)
          .single();
      if (mounted) {
        setState(() {
          _userPoints = data['points'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetch profile: $e');
    }
  }

  Future<void> _fetchNearPlaces() async {
    try {
      final data = await Supabase.instance.client
          .from('places')
          .select()
          .eq('kategori', 'lapangan_badminton');
      
      List<Map<String, dynamic>> places = List<Map<String, dynamic>>.from(data);

      if (_currentPosition != null) {
        // Hitung jarak dan urutkan
        for (var p in places) {
          double distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            (p['latitude'] as num).toDouble(),
            (p['longitude'] as num).toDouble(),
          );
          p['distance_km'] = distance / 1000; // Simpan dalam KM
        }
        places.sort((a, b) => (a['distance_km'] as double).compareTo(b['distance_km'] as double));
      }

      if (mounted) {
        setState(() {
          _nearPlaces = places.take(2).toList(); // Ambil 2 terdekat
          _isLoadingPlaces = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch places: $e');
      if (mounted) setState(() => _isLoadingPlaces = false);
    }
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
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsPage()),
                            ).then((_) {
                              // Re-fetch user metadata and points when returning
                              setState(() {}); 
                              _fetchUserProfile();
                            });
                          },
                          child: const Icon(Icons.settings_outlined, size: 28, color: Color(0xFF213049)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                          Text(
                            '$_userPoints',
                            style: const TextStyle(
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

                  // Section Misi
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QuestPage()),
                      ).then((_) {
                        _fetchUserProfile(); 
                        _fetchActiveMissions(); 
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Misi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF213049),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Color(0xFF213049)),
                          ],
                        ),
                        if (_activeMissions.isNotEmpty) ...[
                          const SizedBox(height: 15),
                          // Tampilkan maksimal 1 misi aktif teratas sebagai preview
                          ..._activeMissions.take(1).map((m) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
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
                                  child: Icon(
                                    m['category'] == 'daily' ? Icons.wb_sunny_outlined : Icons.calendar_month_outlined, 
                                    color: const Color(0xFF213049), 
                                    size: 24
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m['title'] ?? 'Misi',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF213049),
                                        ),
                                      ),
                                      Text(
                                        'Reward +${m['points_reward']} poin',
                                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ],
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NearPlacesPage(currentPosition: _currentPosition),
                            ),
                          );
                        },
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(color: Color(0xFF7D99B6), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // List Toko (Dinamis dari Database)
                  if (_isLoadingPlaces)
                    const Center(child: CircularProgressIndicator())
                  else if (_nearPlaces.isEmpty)
                    const Text('Tidak ada lokasi tersedia', style: TextStyle(fontSize: 12, color: Colors.grey))
                  else
                    ..._nearPlaces.map((loc) {
                      String distText = '';
                      if (loc['distance_km'] != null) {
                        double d = loc['distance_km'];
                        distText = d < 1 
                          ? '${(d * 1000).toInt()} m' 
                          : '${d.toStringAsFixed(1)} km';
                      }
                      
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapPage(initialLocation: loc),
                            ),
                          );
                        },
                        child: _buildStoreCard(
                          loc['name'] ?? '-',
                          loc['address'] ?? '',
                          loc['image_url'] ?? 'assets/images/welcome_bg.png', 
                          '${(loc['kategori'] ?? 'toko_olahraga') == 'lapangan_badminton' ? 'Lapangan Bulutangkis' : 'Toko Olahraga'} ${distText.isNotEmpty ? '• $distText' : ''}',
                        ),
                      );
                    }),
                  const SizedBox(height: 20), 
                ],
              ),
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
            child: imagePath.startsWith('http')
                ? Image.network(
                    imagePath,
                    width: 85,
                    height: 85,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/welcome_bg.png',
                      width: 85,
                      height: 85,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
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
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF213049),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
