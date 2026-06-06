import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  final User? user = Supabase.instance.client.auth.currentUser;
  Map<String, dynamic>? profileData;
  List<Map<String, dynamic>> achievements = []; 
  List<dynamic> claimedIds = [];
  List<dynamic> quests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final pData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user!.id)
          .single();
      
      final aData = await Supabase.instance.client
          .from('achievements')
          .select()
          .order('min_points', ascending: true);

      final cData = await Supabase.instance.client
          .from('user_claims')
          .select('achievement_id')
          .eq('user_id', user!.id);

      final qData = await Supabase.instance.client
          .from('quests')
          .select('*, badges(title, icon_name)');

      setState(() {
        profileData = pData;
        achievements = List<Map<String, dynamic>>.from(aData); 
        claimedIds = (cData as List).map((e) => e['achievement_id']).toList();
        quests = qData as List;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _claimAchievement(Map<String, dynamic> achievement) async {
    try {
      await Supabase.instance.client.from('user_claims').insert({
        'user_id': user!.id,
        'achievement_id': achievement['id'],
      });

      await Supabase.instance.client.from('profiles').update({
        'active_title': achievement['title']
      }).eq('id', user!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selamat! Anda sekarang adalah ${achievement['title']}!')),
        );
      }
      _fetchData(); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal klaim: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int points = profileData?['points'] ?? 0;
    
    // Logika pencarian target poin berikutnya yang lebih aman
    Map<String, dynamic> nextTarget = {'min_points': 100, 'title': '...'};
    if (achievements.isNotEmpty) {
      try {
        nextTarget = achievements.firstWhere((a) => (a['min_points'] as int) > points);
      } catch (e) {
        nextTarget = achievements.last; // Jika sudah level tertinggi
      }
    }
    
    double progress = (points / (nextTarget['min_points'] as int)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reward Saya', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF213049))),
                        const Text('Naikkan poin anda untuk status!', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 20),

                        _buildProgressCard(nextTarget, progress, points),
                        
                        const SizedBox(height: 30),
                        const Text('Misi & Quest', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF213049))),
                        const SizedBox(height: 15),

                        quests.isEmpty 
                          ? const Text('Tidak ada misi aktif.', style: TextStyle(fontSize: 12, color: Colors.grey))
                          : Column(children: quests.map((q) => _buildQuestCard(q)).toList()),

                        const SizedBox(height: 30),
                        const Text('Katalog Reward', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF213049))),
                        const SizedBox(height: 15),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                          itemCount: achievements.length,
                          itemBuilder: (context, index) {
                            final item = achievements[index];
                            bool isClaimed = claimedIds.contains(item['id']);
                            bool canClaim = points >= (item['min_points'] as int) && !isClaimed;
                            return _buildRewardCard(item, isClaimed, canClaim);
                          },
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
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
              IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF213049)), onPressed: () => Navigator.pop(context)),
              const Text('Bi Mistik', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF213049))),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(Map<String, dynamic> nextTarget, double progress, int points) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF69487D), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: Color(0xFFD8C494), size: 28),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL POIN ANDA', style: TextStyle(color: Color(0xFFD8C494), fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('$points', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Target: ${nextTarget['title']}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Color(0xFFD8C494), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, backgroundColor: Colors.white24, color: const Color(0xFFD8C494), minHeight: 8, borderRadius: BorderRadius.circular(10)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${((nextTarget['min_points'] as int) - points).clamp(0, 999999)} Poin lagi', style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(dynamic quest) {
    final badge = quest['badges'];
    final String iconName = badge?['icon_name'] ?? '';
    
    // Mapping ikon agar sesuai desain
    IconData iconData = Icons.volunteer_activism; // Default
    if (iconName == 'verified_user') iconData = Icons.verified_user;
    if (iconName == 'search' || iconName == 'sports_tennis') iconData = Icons.sports_tennis;
    if (iconName == 'star') iconData = Icons.star;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), 
            blurRadius: 5, 
            offset: const Offset(0, 2)
          )
        ]
      ),
      child: Row(
        children: [
          // Icon Section
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF69487D).withOpacity(0.1), 
              shape: BoxShape.circle
            ),
            child: Icon(iconData, color: const Color(0xFF69487D)),
          ),
          const SizedBox(width: 15),
          
          // Quest Info Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest['title'] ?? 'Misi', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF213049))
                ),
                const SizedBox(height: 2),
                Text(
                  quest['description'] ?? '', 
                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 10),

          // Reward Section (Rapi & Sejajar)
          SizedBox(
            width: 80, // Memberikan lebar tetap agar semua kartu sejajar
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'REWARD', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)
                ),
                const SizedBox(height: 2),
                Text(
                  badge?['title'] ?? 'Badge', 
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF69487D), 
                    fontSize: 11
                  )
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> item, bool isClaimed, bool canClaim) {
    // Logika pemilihan gambar: Cek apakah ada image_url di database
    Widget imageWidget;
    String imageUrl = item['image_url'] ?? '';

    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        // Jika isinya link internet (http...)
        imageWidget = Image.network(imageUrl, fit: BoxFit.contain);
      } else {
        // Jika isinya path aset (assets/images/...)
        imageWidget = Image.asset(imageUrl, fit: BoxFit.contain);
      }
    } else {
      // Jika kosong, pakai inisial sebagai cadangan (fallback)
      imageWidget = Image.network(
        'https://ui-avatars.com/api/?name=${item['title']}&background=transparent&color=fff&size=200',
        fit: BoxFit.contain,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Lapisan Warna Background Dasar
                  Container(
                    color: const Color(0xFF7D99B6),
                  ),
                  
                  // 2. Lapisan Gambar (Dinamis)
                  imageWidget,

                  // 3. Overlay jika sudah diklaim
                  if (isClaimed) 
                    Container(
                      color: Colors.black54, 
                      child: const Center(
                        child: Icon(Icons.check_circle, color: Colors.green, size: 40)
                      )
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'], 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF213049)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.green, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${item['min_points']}', 
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 35,
                  child: ElevatedButton(
                    onPressed: canClaim ? () => _claimAchievement(item) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD8C494),
                      foregroundColor: const Color(0xFF213049),
                      disabledBackgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      isClaimed ? 'Terpasang' : 'Klaim', 
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
