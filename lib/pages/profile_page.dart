import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bi_mistik/pages/auth_wrapper.dart';
import 'package:bi_mistik/pages/reward_page.dart';
import 'package:bi_mistik/pages/about_page.dart';
import 'package:bi_mistik/pages/notification_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = Supabase.instance.client.auth.currentUser;
  Map<String, dynamic>? profileData;
  List<dynamic> userBadges = [];
  int totalBadges = 0; // Tambahkan variabel untuk total badge
  bool _isLoading = true;
  bool _hasUnreadNotification = false; // Variabel status notifikasi

  @override
  void initState() {
    super.initState();
    _fetchProfile();
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

  Future<void> _fetchProfile() async {
    try {
      final pData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user!.id)
          .single();
      
      final bData = await Supabase.instance.client
          .from('user_badges')
          .select('badges(title, icon_name)')
          .eq('user_id', user!.id);

      // Ambil total semua badge yang ada di database dengan cara yang lebih simpel
      final totalB = await Supabase.instance.client
          .from('badges')
          .select('id');

      setState(() {
        profileData = pData;
        userBadges = bData as List;
        totalBadges = (totalB as List).length; // Menghitung jumlah data dari list
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    // Menampilkan dialog konfirmasi
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text('Apakah Anda yakin ingin keluar dari Bi Mistik?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String fullName = profileData?['full_name'] ?? user?.userMetadata?['full_name'] ?? 'User';
    final String activeTitle = profileData?['active_title'] ?? 'Pemula';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // PROFILE HEADER BOX
                      Center(
                        child: Container(
                          width: double.infinity,
                          height: 220,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/box_profile.png'),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black45,
                                BlendMode.darken,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white24,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.network(
                                    profileData?['avatar_url'] ?? 'https://ui-avatars.com/api/?name=$fullName&background=random',
                                    width: 90, height: 90, fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                fullName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontSize: 22, 
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTitleBadge(activeTitle),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      _buildAchievementSection(),
                      const SizedBox(height: 25),
                      _buildMenuCard(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF7D99B6),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bi Mistik', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF213049))),
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
    );
  }

  Widget _buildTitleBadge(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
          const SizedBox(width: 5),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAchievementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Pencapaian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF213049))),
            Text('${userBadges.length}/$totalBadges Badge Diraih', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ],
        ),
        const SizedBox(height: 15),
        userBadges.isEmpty 
          ? const Text('Belum ada badge. Selesaikan misi di menu Reward!', style: TextStyle(fontSize: 12, color: Colors.grey))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: userBadges.map((b) {
                  final badge = b['badges'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _buildBadgeCard(badge['title'], badge['icon_name']),
                  );
                }).toList(),
              ),
            ),
      ],
    );
  }

  Widget _buildBadgeCard(String title, String iconName) {
    IconData iconData = Icons.volunteer_activism;
    if (iconName == 'verified_user') iconData = Icons.verified_user;
    if (iconName == 'search') iconData = Icons.search;
    if (iconName == 'sports_tennis') iconData = Icons.sports_tennis;
    if (iconName == 'star') iconData = Icons.star;

    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF69487D).withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(iconData, color: const Color(0xFF69487D), size: 24),
          ),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF213049))),
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          _buildMenuItem(Icons.card_giftcard, 'Reward Saya', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const RewardPage())).then((_) => _fetchProfile());
          }),
          const Divider(height: 1, indent: 60),
          _buildMenuItem(Icons.info_outline, 'Tentang', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage()));
          }),
          const Divider(height: 1, indent: 60),
          _buildMenuItem(Icons.logout, 'Keluar', _handleLogout, isLogout: true),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isLogout ? Colors.red.withOpacity(0.1) : const Color(0xFFF7F9FB), shape: BoxShape.circle), child: Icon(icon, color: isLogout ? Colors.red : const Color(0xFF213049), size: 22)),
      title: Text(title, style: TextStyle(color: isLogout ? Colors.red : const Color(0xFF213049), fontWeight: FontWeight.w500)),
      trailing: isLogout ? null : const Icon(Icons.chevron_right, size: 20, color: Colors.blueGrey),
      onTap: onTap,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 100,
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(onTap: () => Navigator.pop(context), child: _buildNavItem(Icons.home, 'Home', false)),
          _buildMapItem(),
          _buildNavItem(Icons.person, 'Profile', true),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: isSelected ? const Color(0xFFF0F0F0) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF7D99B6) : const Color(0xFF213049), size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: isSelected ? const Color(0xFF7D99B6) : const Color(0xFF213049), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildMapItem() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF69487D), width: 2.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]),
          child: const Icon(Icons.map_outlined, color: Color(0xFF213049), size: 30),
        ),
        const SizedBox(height: 4),
        const Text('Map', style: TextStyle(fontSize: 12, color: Color(0xFF213049), fontWeight: FontWeight.bold)),
      ],
    );
  }
}
