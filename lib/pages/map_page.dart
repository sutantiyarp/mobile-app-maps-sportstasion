import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _locations = [];
  String _activeFilter = 'all';
  bool _isLoading = true;
  LatLng? _currentPosition;

  static const Color primaryColor  = Color(0xFF7D99B6);
  static const Color tokoColor     = Color(0xFFf97316);
  static const Color lapanganColor = Color(0xFF16a34a);
  static const Color textColor     = Color(0xFF213049);
  static const LatLng _defaultCenter = LatLng(-7.2575, 112.7521);

  @override
  void initState() {
    super.initState();
    _initLocation();
    _fetchLocations();
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
          _currentPosition = LatLng(pos.latitude, pos.longitude);
        });
        _mapController.move(_currentPosition!, 14);
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _fetchLocations() async {
    try {
      final data = await Supabase.instance.client
          .from('places')
          .select()
          .order('name');

      if (mounted) {
        setState(() {
          _locations = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredLocations {
    if (_activeFilter == 'all') return _locations;
    if (_activeFilter == 'toko') {
      return _locations.where((l) =>
        (l['kategori'] ?? 'toko_olahraga') == 'toko_olahraga'
      ).toList();
    }
    return _locations.where((l) =>
      (l['kategori'] ?? 'toko_olahraga') == 'lapangan_badminton'
    ).toList();
  }

  bool _isLapangan(Map<String, dynamic> loc) {
    return (loc['kategori'] ?? 'toko_olahraga') == 'lapangan_badminton';
  }

  void _showLocationDetail(Map<String, dynamic> loc) {
    final isLap = _isLapangan(loc);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isLap
                    ? lapanganColor.withOpacity(0.12)
                    : tokoColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isLap ? '🏸 Lapangan Badminton' : '🏪 Toko Olahraga',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isLap ? lapanganColor : tokoColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc['name'] ?? '-',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc['description'] ?? '-',
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc['address'] ?? '-',
                    style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _mapController.move(
                    LatLng(
                      (loc['latitude'] as num).toDouble(),
                      (loc['longitude'] as num).toDouble(),
                    ),
                    16,
                  );
                },
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Fokus di Peta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _goToMyLocation() async {
    await _initLocation();
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15);
    }
  }

  void _setFilter(String f) {
    setState(() => _activeFilter = f);
  }

  int get _tokoCount => _locations.where((l) => !_isLapangan(l)).length;
  int get _lapanganCount => _locations.where((l) => _isLapangan(l)).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          Container(
            color: primaryColor,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Peta Lokasi Olahraga',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _fetchLocations,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.refresh, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _filterChip('all', '🔵 Semua', primaryColor),
                const SizedBox(width: 8),
                _filterChip('toko', '🟠 Toko', tokoColor),
                const SizedBox(width: 8),
                _filterChip('lapangan', '🟢 Lapangan', lapanganColor),
              ],
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition ?? _defaultCenter,
                    initialZoom: 6,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.bi_mistik',
                    ),
                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition!,
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 8),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: _filteredLocations.map((loc) {
                        final isLap = _isLapangan(loc);
                        final color = isLap ? lapanganColor : tokoColor;
                        final emoji = isLap ? '🏸' : '🏪';
                        return Marker(
                          point: LatLng(
                            (loc['latitude'] as num).toDouble(),
                            (loc['longitude'] as num).toDouble(),
                          ),
                          width: 40,
                          height: 50,
                          child: GestureDetector(
                            onTap: () => _showLocationDetail(loc),
                            child: Column(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 3)),
                                    ],
                                  ),
                                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
                                ),
                                CustomPaint(
                                  size: const Size(10, 8),
                                  painter: _TrianglePainter(color),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.white.withOpacity(0.8),
                    child: const Center(child: CircularProgressIndicator(color: primaryColor)),
                  ),
                Positioned(
                  right: 16, bottom: 20,
                  child: FloatingActionButton.small(
                    heroTag: 'myLoc',
                    onPressed: _goToMyLocation,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: primaryColor),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: Colors.white.withOpacity(0.7),
                    child: const Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 9, color: Colors.black54)),
                  ),
                ),
              ],
            ),
          ),

          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: [
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _statCard('$_tokoCount', 'Toko\nOlahraga', tokoColor),
                    const SizedBox(width: 10),
                    _statCard('$_lapanganCount', 'Lapangan\nBadminton', lapanganColor),
                    const SizedBox(width: 10),
                    _statCard('${_locations.length}', 'Total\nLokasi', primaryColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label, Color color) {
    final isActive = _activeFilter == value;
    return GestureDetector(
      onTap: () => _setFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          border: Border.all(color: isActive ? color : Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.white : textColor),
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => false;
}
