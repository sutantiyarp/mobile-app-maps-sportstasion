import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestPage extends StatefulWidget {
  const QuestPage({super.key});

  @override
  State<QuestPage> createState() => _QuestPageState();
}

class _QuestPageState extends State<QuestPage> {
  final User? user = Supabase.instance.client.auth.currentUser;
  List<dynamic> _weeklyQuests = [];
  List<dynamic> _dailyQuests = [];
  List<String> _completedQuestIds = []; // Simpan ID misi yang sudah selesai
  int _currentPoints = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // 1. Ambil data misi
      final mData = await Supabase.instance.client
          .from('missions')
          .select()
          .order('id');
      
      final pData = await Supabase.instance.client
          .from('profiles')
          .select('points')
          .eq('id', user!.id)
          .single();

      // 2. Tentukan batas waktu Reset (Hari ini & Minggu ini)
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day).toIso8601String();
      
      // Hitung awal minggu (Senin)
      final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day).toIso8601String();

      // 3. Ambil data klaim user
      final cData = await Supabase.instance.client
          .from('user_missions')
          .select('mission_id, completed_at')
          .eq('user_id', user!.id);

      if (mounted) {
        List<dynamic> allMissions = mData as List;
        List<dynamic> allClaims = cData as List;

        setState(() {
          _currentPoints = pData['points'] ?? 0;
          _completedQuestIds = [];

          // Logika Filter & Reset
          _dailyQuests = allMissions.where((m) => m['category'] == 'daily').map((m) {
            // Cek apakah ada klaim UNTUK MISI INI yang dilakukan HARI INI
            bool isClaimedToday = allClaims.any((c) => 
              c['mission_id'] == m['id'] && 
              DateTime.parse(c['completed_at']).isAfter(DateTime.parse(startOfToday))
            );
            if (isClaimedToday) _completedQuestIds.add(m['id'].toString());

            // Misi Login otomatis 1/1, lainnya 0/1 (bisa dikembangkan nanti)
            int prog = (m['id'] == 'daily_1') ? 1 : 0; 
            return {...m, 'target': 1, 'progress': prog};
          }).toList();

          _weeklyQuests = allMissions.where((m) => m['category'] == 'weekly').map((m) {
            // Cek apakah ada klaim UNTUK MISI INI yang dilakukan MINGGU INI
            bool isClaimedThisWeek = allClaims.any((c) => 
              c['mission_id'] == m['id'] && 
              DateTime.parse(c['completed_at']).isAfter(DateTime.parse(startOfWeek))
            );
            if (isClaimedThisWeek) _completedQuestIds.add(m['id'].toString());

            return {
              ...m, 
              'target': m['id'] == 'weekly_1' ? 3 : 4, 
              'progress': 0 // Sementara 0, perlu sistem tracking untuk real progress
            };
          }).toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeQuest(dynamic quest) async {
    final String missionId = quest['id'].toString();
    final int reward = quest['points_reward'] ?? 0;

    setState(() => _isLoading = true);

    try {
      // Simpan ke tabel BARU: user_missions
      await Supabase.instance.client.from('user_missions').insert({
        'user_id': user!.id,
        'mission_id': missionId,
      });

      // Update Poin di profiles
      await Supabase.instance.client
          .from('profiles')
          .update({'points': _currentPoints + reward})
          .eq('id', user!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Misi Selesai! +$reward Poin Berhasil Ditambahkan!'), backgroundColor: Colors.green),
        );
        _fetchData(); 
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal klaim atau sudah pernah diklaim.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF7D99B6);
    const textColor = Color(0xFF213049);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          _buildTopBar(context, primaryColor, textColor),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: primaryColor))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 30),
                      
                      _buildSectionTitle('Misi Harian', Icons.today),
                      ..._dailyQuests.map((q) => _buildQuestTile(q, isDaily: true)).toList(),
                      
                      const SizedBox(height: 30),
                      _buildSectionTitle('Misi Mingguan', Icons.calendar_view_week),
                      _weeklyQuests.isEmpty 
                        ? const Text('Tidak ada misi mingguan aktif.', style: TextStyle(fontSize: 12, color: Colors.grey))
                        : Column(children: _weeklyQuests.map((q) => _buildQuestTile(q)).toList()),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Color bgColor, Color txtColor) {
    return Container(
      width: double.infinity,
      color: bgColor,
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
                'Misi & Quest',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF213049)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF69487D), Color(0xFF7D99B6)]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: const [
          Icon(Icons.auto_awesome, color: Color(0xFFD8C494), size: 40),
          SizedBox(height: 10),
          Text(
            'Selesaikan Misi, Raih Hadiah!',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'Kumpulkan poin untuk menaikkan status profilmu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF213049)),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF213049))),
        ],
      ),
    );
  }

  Widget _buildQuestTile(dynamic q, {bool isDaily = false}) {
    final String qId = q['id'].toString();
    final bool alreadyCompleted = _completedQuestIds.contains(qId);
    double progress = (q['progress'] ?? 0) / (q['target'] ?? 1);
    bool canClaim = progress >= 1.0 && !alreadyCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: alreadyCompleted ? Colors.green.withOpacity(0.1) : const Color(0xFF69487D).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              alreadyCompleted ? Icons.check : Icons.whatshot_outlined, 
              color: alreadyCompleted ? Colors.green : const Color(0xFF69487D), 
              size: 24
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q['title'] ?? 'Misi', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF213049))),
                Text(q['description'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                if (!alreadyCompleted)
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    color: isDaily ? const Color(0xFFD8C494) : const Color(0xFF7D99B6),
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(10),
                  )
                else
                  const Text('Sudah tersimpan di database', style: TextStyle(fontSize: 10, color: Colors.green, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              if (canClaim)
                ElevatedButton(
                  onPressed: () => _completeQuest(q),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD8C494),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(50, 30),
                  ),
                  child: const Text('KLAIM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF213049))),
                )
              else if (alreadyCompleted)
                const Icon(Icons.verified, color: Colors.green, size: 28)
              else
                Column(
                  children: [
                    const Text('REWARD', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text('+${q['points_reward'] ?? 50}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                )
            ],
          )
        ],
      ),
    );
  }
}
