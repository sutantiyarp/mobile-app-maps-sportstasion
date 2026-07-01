import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  final Map<String, dynamic>? initialLocation;
  const MapPage({super.key, this.initialLocation});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _locations = [];
  String _activeFilter = 'all';
  bool _isLoading = true;
  LatLng? _currentPosition;
  List<LatLng> _routePoints = [];

  static const Color primaryColor  = Color(0xFF7D99B6);
  static const Color tokoColor     = Color(0xFFf97316);
  static const Color lapanganColor = Color(0xFF16a34a);
  static const Color textColor     = Color(0xFF213049);
  static const LatLng _defaultCenter = LatLng(-7.2575, 112.7521);

  @override
  void initState() {
    super.initState();
    _initLocation().then((_) {
      if (widget.initialLocation != null) {
        final loc = widget.initialLocation!;
        final LatLng dest = LatLng(
          (loc['latitude'] as num).toDouble(),
          (loc['longitude'] as num).toDouble(),
        );
        _mapController.move(dest, 15); // Langsung geser kamera ke lokasi terpilih
        _showLocationDetail(loc);
      }
    });
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
          _routePoints = []; // Hapus rute saat refresh data
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
    final LatLng destLocation = LatLng(
      (loc['latitude'] as num).toDouble(),
      (loc['longitude'] as num).toDouble(),
    );

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: loc['image_url'] != null && loc['image_url'].toString().startsWith('http')
                      ? Image.network(
                          loc['image_url'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/images/welcome_bg.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          loc['image_url'] ?? 'assets/images/welcome_bg.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _mapController.move(destLocation, 16);
                      },
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('Fokus'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _getRoute(destLocation);
                      },
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Rute'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _getRoute(LatLng destination) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi GPS tidak ditemukan')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${_currentPosition!.longitude},${_currentPosition!.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=polyline';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['routes'][0]['geometry'];
        _decodePolyline(geometry);
        _mapController.move(destination, 14);
      }
    } catch (e) {
      debugPrint('Route error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    setState(() {
      _routePoints = points;
    });
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
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF213049)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Peta Lokasi Olahraga',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF213049),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF213049)),
                      onPressed: _fetchLocations,
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
                      userAgentPackageName: 'com.example.uas_flutter_app',
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            color: Colors.blue,
                            strokeWidth: 5,
                          ),
                        ],
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