import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  // Tambahan parameter penerima data dari halaman Home
  final Map<String, dynamic>? targetLocation;

  const MapPage({super.key, this.targetLocation});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  List<Map<String, dynamic>> _locations = [];
  String _activeFilter = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  LatLng? _currentPosition;

  List<LatLng> _routePoints = [];
  String? _activeRouteName;

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
    
    // Jika halaman ini dibuka dari klik kartu di HomePage, otomatis buka pop-up lokasinya
    if (widget.targetLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final lat = (widget.targetLocation!['latitude'] as num).toDouble();
        final lng = (widget.targetLocation!['longitude'] as num).toDouble();
        _mapController.move(LatLng(lat, lng), 16.0);
        _showLocationDetail(widget.targetLocation!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
        });
        
        // Pindahkan kamera ke lokasi kita, kecuali jika ada target dari HomePage
        if (widget.targetLocation == null) {
          _mapController.move(_currentPosition!, 14);
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _fetchLocations() async {
    try {
      final data = await Supabase.instance.client.from('places').select().order('name');
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

  Future<void> _getRouteOSRM(double destLat, double destLng, String destName) async {
    if (_currentPosition == null) return;
    
    setState(() {
      _isLoading = true;
      _activeRouteName = destName;
      _searchQuery = ''; 
      _searchController.clear();
      _searchFocus.unfocus();
    });

    final start = '${_currentPosition!.longitude},${_currentPosition!.latitude}';
    final end = '$destLng,$destLat';
    final url = Uri.parse('https://router.project-osrm.org/route/v1/driving/$start;$end?overview=full&geometries=geojson');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List coordinates = data['routes'][0]['geometry']['coordinates'];

        setState(() {
          _routePoints = coordinates.map((coord) => LatLng(coord[1] as double, coord[0] as double)).toList();
          _isLoading = false;
        });
        _mapController.move(_currentPosition!, 13.5);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error rute OSRM: $e");
      setState(() => _isLoading = false);
    }
  }

  void _cancelRoute() {
    setState(() {
      _routePoints = [];
      _activeRouteName = null;
    });
    _goToMyLocation();
  }

  List<Map<String, dynamic>> get _filteredLocations {
    var list = _locations;
    if (_activeFilter == 'toko') {
      list = list.where((l) => (l['kategori'] ?? 'toko_olahraga') == 'toko_olahraga').toList();
    } else if (_activeFilter == 'lapangan') {
      list = list.where((l) => (l['kategori'] ?? 'toko_olahraga') == 'lapangan_badminton').toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      list = list.where((l) {
        final name = (l['name'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    return list;
  }

  bool _isLapangan(Map<String, dynamic> loc) {
    return (loc['kategori'] ?? 'toko_olahraga') == 'lapangan_badminton';
  }

  void _showLocationDetail(Map<String, dynamic> loc) {
    final isLap = _isLapangan(loc);
    final lat = (loc['latitude'] as num).toDouble();
    final lng = (loc['longitude'] as num).toDouble();
    final name = loc['name'] ?? 'Tujuan';

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
              child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isLap ? lapanganColor.withOpacity(0.12) : tokoColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isLap ? '🏸 Lapangan Badminton' : '🏪 Toko Olahraga',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isLap ? lapanganColor : tokoColor),
              ),
            ),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 4),
            Text(loc['description'] ?? '-', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Expanded(child: Text(loc['address'] ?? '-', style: const TextStyle(fontSize: 13, color: Colors.blueGrey))),
              ],
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); 
                  _getRouteOSRM(lat, lng, name); 
                },
                icon: const Icon(Icons.directions, size: 20),
                label: const Text('Mulai Rute Navigasi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      resizeToAvoidBottomInset: false, 
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
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Eksplorasi & Rute', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),

          Container(
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Cari lapangan atau toko...',
                      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: primaryColor),
                      suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _searchFocus.unfocus();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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
                    initialZoom: 13,
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture) _searchFocus.unfocus();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.bi_mistik',
                    ),
                    
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(points: _routePoints, strokeWidth: 5.0, color: Colors.blueAccent),
                        ],
                      ),

                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition!,
                            width: 20, height: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue, shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 8)],
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
                          point: LatLng((loc['latitude'] as num).toDouble(), (loc['longitude'] as num).toDouble()),
                          width: 40, height: 50,
                          child: GestureDetector(
                            onTap: () {
                              _searchFocus.unfocus();
                              _showLocationDetail(loc);
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 3))],
                                  ),
                                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
                                ),
                                CustomPaint(size: const Size(10, 8), painter: _TrianglePainter(color)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                if (_searchQuery.isNotEmpty && _filteredLocations.isNotEmpty)
                  Positioned(
                    top: 10, left: 16, right: 16,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _filteredLocations.length,
                        separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200, height: 1),
                        itemBuilder: (context, index) {
                          final loc = _filteredLocations[index];
                          final isLap = _isLapangan(loc);
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: (isLap ? lapanganColor : tokoColor).withOpacity(0.1), shape: BoxShape.circle),
                              child: Text(isLap ? '🏸' : '🏪', style: const TextStyle(fontSize: 18)),
                            ),
                            title: Text(loc['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(loc['address'] ?? '', style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              _searchFocus.unfocus();
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                              _mapController.move(
                                LatLng((loc['latitude'] as num).toDouble(), (loc['longitude'] as num).toDouble()), 
                                16.0
                              );
                              _showLocationDetail(loc);
                            },
                          );
                        },
                      ),
                    ),
                  ),

                if (_activeRouteName != null)
                  Positioned(
                    top: 10, left: 16, right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: primaryColor, borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Rute Menuju:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                Text(_activeRouteName!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _cancelRoute,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                if (_isLoading)
                  Container(color: Colors.white.withOpacity(0.8), child: const Center(child: CircularProgressIndicator(color: primaryColor))),

                Positioned(
                  right: 16, bottom: 20,
                  child: FloatingActionButton.small(
                    heroTag: 'myLoc',
                    onPressed: _goToMyLocation,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: primaryColor),
                  ),
                ),
              ],
            ),
          ),

          Container(
            decoration: const BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: [
                Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
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
      onTap: () {
        _searchFocus.unfocus(); 
        _setFilter(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          border: Border.all(color: isActive ? color : Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.white : textColor)),
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
    final path = ui.Path()..moveTo(0, 0)..lineTo(size.width, 0)..lineTo(size.width / 2, size.height)..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => false;
}