import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bi_mistik/pages/map/map_page.dart';

class NearPlacesPage extends StatefulWidget {
  final Position? currentPosition;
  const NearPlacesPage({super.key, this.currentPosition});

  @override
  State<NearPlacesPage> createState() => _NearPlacesPageState();
}

class _NearPlacesPageState extends State<NearPlacesPage> {
  List<Map<String, dynamic>> _allPlaces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllPlaces();
  }

  Future<void> _fetchAllPlaces() async {
    try {
      final data = await Supabase.instance.client
          .from('places')
          .select()
          .eq('kategori', 'lapangan_badminton');
      
      List<Map<String, dynamic>> places = List<Map<String, dynamic>>.from(data);

      if (widget.currentPosition != null) {
        for (var p in places) {
          double distance = Geolocator.distanceBetween(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
            (p['latitude'] as num).toDouble(),
            (p['longitude'] as num).toDouble(),
          );
          p['distance_km'] = distance / 1000;
        }
        places.sort((a, b) => (a['distance_km'] as double).compareTo(b['distance_km'] as double));
      }

      if (mounted) {
        setState(() {
          _allPlaces = places;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
          Container(
            color: primaryColor,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Lapangan Terdekat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : _allPlaces.isEmpty
                    ? const Center(child: Text('Tidak ada lapangan ditemukan'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _allPlaces.length,
                        itemBuilder: (context, index) {
                          final loc = _allPlaces[index];
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
                            child: _buildPlaceCard(
                              loc['name'] ?? '-',
                              loc['address'] ?? '',
                              loc['image_url'] ?? 'assets/images/welcome_bg.png',
                              'Lapangan Bulutangkis ${distText.isNotEmpty ? '• $distText' : ''}',
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(String title, String subtitle, String imagePath, String infoText) {
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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF213049),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  infoText,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF7D99B6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
