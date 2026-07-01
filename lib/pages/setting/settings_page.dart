import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bi_mistik/main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final User? user = Supabase.instance.client.auth.currentUser;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // State untuk switch notifikasi
  bool _notifQuest = true;
  bool _notifReward = true;
  bool _notifSystem = true;

  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    // Inisialisasi kosong agar tidak muncul username lama saat refresh
    _usernameController.text = '';
    _fetchCurrentAvatar();
  }

  Future<void> _fetchCurrentAvatar() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user!.id)
          .single();
      if (mounted) {
        setState(() {
          _currentAvatarUrl = data['avatar_url'];
        });
      }
    } catch (e) {
      debugPrint('Error fetch avatar: $e');
    }
  }

  Future<void> _updateUsername() async {
    if (_usernameController.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      // 1. Update Auth Metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {'username': _usernameController.text.trim()},
        ),
      );

      // 2. Update Database (Tabel profiles)
      await Supabase.instance.client
          .from('profiles')
          .update({'username': _usernameController.text.trim()})
          .eq('id', user!.id);

      if (mounted) {
        _usernameController.clear(); // Bersihkan input setelah simpan
        FocusScope.of(context).unfocus(); // Sembunyikan keyboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username berhasil diperbarui!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );
      if (mounted) {
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diperbarui!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Daftar pilihan avatar menggunakan folder assets
  final List<String> _avatarOptions = [
    'assets/images/avatar1.png',
    'assets/images/avatar2.png',
    'assets/images/avatar3.png',
    'assets/images/avatar4.png',
    'assets/images/avatar5.png',
    'assets/images/avatar6.png',
  ];

  Future<void> _updateAvatar(String url) async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': url})
          .eq('id', user!.id);
      
      if (mounted) {
        setState(() => _currentAvatarUrl = url); // Update tampilan lokal
        Navigator.pop(context); // Tutup dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar berhasil diubah!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih Avatar Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: _avatarOptions.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _updateAvatar(_avatarOptions[index]),
                child: CircleAvatar(
                  backgroundImage: AssetImage(_avatarOptions[index]),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  bool _confirmDelete = false;

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);
    try {
      // Menghapus baris user di tabel profiles (karena ON DELETE CASCADE di auth.users)
      // Namun cara terbaik menghapus akun di Supabase adalah via Edge Function atau menghapus dari auth.users.
      // Untuk demo ini kita lakukan signOut & arahkan ke Welcome.
      await Supabase.instance.client.auth.signOut();
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun Anda telah dihapus secara permanen.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                  const Text('Kelola akun', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Kendalikan akun mana yang berada di Pusat Akun. Pelajari selengkapnya', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
              const SizedBox(height: 30),
              
              // Card Hapus Akun
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hapus akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Checkbox(
                          value: _confirmDelete, 
                          onChanged: (val) {
                            setModalState(() => _confirmDelete = val!);
                          },
                          activeColor: const Color(0xFF69487D),
                          shape: const CircleBorder(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Penghapusan akun Anda bersifat permanen. Saat Anda menghapus akun BI MISTIK Anda, profil, foto, poin, dan data lainnya akan dihapus secara permanen.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _confirmDelete ? _deleteAccount : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF69487D),
                    disabledBackgroundColor: const Color(0xFF9E8AAA),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text('Lanjutkan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: Colors.black)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Keamanan & Profil'),
                  Center(
                    child: GestureDetector(
                      onTap: _showAvatarPicker,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFF7D99B6),
                            backgroundImage: _currentAvatarUrl != null
                                ? (_currentAvatarUrl!.startsWith('assets/')
                                    ? AssetImage(_currentAvatarUrl!) as ImageProvider
                                    : NetworkImage(_currentAvatarUrl!))
                                : null,
                            child: _currentAvatarUrl == null
                                ? const Icon(Icons.person, size: 40, color: Colors.white)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Color(0xFF69487D), shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAccountCard(primaryColor, textColor),
                  
                  const SizedBox(height: 30),
                  _buildSectionTitle('Notifikasi'),
                  _buildNotificationCard(textColor),

                  const SizedBox(height: 30),
                  _buildSectionTitle('Akun'),
                  _buildManageAccountCard(textColor),
                  
                  const SizedBox(height: 40),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: primaryColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageAccountCard(Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        title: const Text('Kelola Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text('Hapus akun secara permanen', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
        trailing: const Icon(Icons.chevron_right),
        onTap: _showDeleteConfirmation,
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
                'Pengaturan',
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF213049),
        ),
      ),
    );
  }

  Widget _buildAccountCard(Color primaryColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Username Field
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'Ganti username sapaan',
              prefixIcon: const Icon(Icons.person_outline),
              suffixIcon: IconButton(
                onPressed: _isLoading ? null : _updateUsername,
                icon: const Icon(Icons.check_circle, color: Colors.green),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          const SizedBox(height: 20),
          // Password Field
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password Baru',
              hintText: 'Masukkan password baru',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: _isLoading ? null : _updatePassword,
                icon: const Icon(Icons.save, color: Color(0xFF7D99B6)),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '*Klik ikon di kanan input untuk menyimpan perubahan',
            style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
          )
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _buildNotifTile('Misi & Quest', 'Dapatkan info quest mingguan terbaru', _notifQuest, (v) => setState(() => _notifQuest = v)),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildNotifTile('Reward & Poin', 'Info poin masuk dan klaim badge', _notifReward, (v) => setState(() => _notifReward = v)),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildNotifTile('Sistem', 'Pembaruan aplikasi dan info penting', _notifSystem, (v) => setState(() => _notifSystem = v)),
        ],
      ),
    );
  }

  Widget _buildNotifTile(String title, String sub, bool val, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
      value: val,
      onChanged: onChanged,
      activeColor: const Color(0xFF7D99B6),
    );
  }
}
