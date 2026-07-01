import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final User? user = Supabase.instance.client.auth.currentUser;
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final data = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', user!.id)
          .order('created_at', ascending: false);

      setState(() {
        _notifications = data as List;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
    _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final item = _notifications[index];
                            return _buildNotificationCard(item);
                          },
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
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF213049)),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Notifikasi',
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

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final bool isRead = item['is_read'] ?? false;
    final String type = item['type'] ?? 'system';
    
    IconData iconData = Icons.notifications;
    Color iconColor = const Color(0xFF69487D);

    if (type == 'reward') {
      iconData = Icons.card_giftcard;
      iconColor = Colors.orange;
    } else if (type == 'quest') {
      iconData = Icons.auto_awesome;
      iconColor = Colors.blue;
    }

    return GestureDetector(
      onTap: () => _markAsRead(item['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(15),
          boxShadow: isRead ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
          border: isRead ? null : Border.all(color: const Color(0xFF7D99B6).withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 20),
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
                        item['title'],
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                          fontSize: 14,
                          color: const Color(0xFF213049),
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(DateTime.parse(item['created_at'])),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item['message'],
                    style: TextStyle(
                      fontSize: 12,
                      color: isRead ? Colors.blueGrey : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                margin: const EdgeInsets.only(top: 5, left: 5),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF7D99B6),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 20),
          const Text(
            'Belum ada notifikasi',
            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Kabar terbaru akan muncul di sini.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
