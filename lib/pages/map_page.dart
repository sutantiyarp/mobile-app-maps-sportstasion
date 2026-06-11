import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  List<Map<String, dynamic>> _locations = [];
  String _activeFilter = 'all';
  bool _isLoading = true;
  LatLng? _currentPosition;

  static const Color primaryColor   = Color(0xFF7D99B6);
  static const Color secondaryColor = Color(0xFF69487D);
  static const Color tokoColor      = Color(0xFFf97316);
  static const Color lapanganColor  = Color(0xFF16a34a);
  static const Color textColor      = Color(0xFF213049);

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
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, 13),
        );
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _fetchLocations() async {
    try {
      final data = await Supabase.instance.client
          .from('locations')
          .select()
          .order('kategori');

      if (mounted) {
        setState(() {
          _locations = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
        _buildMarkers();
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _buildMarkers() {
    final filtered = _activeFilter == 'all'
        ? _locations
        : _locations.where((l) {
            if (_activeFilter == 'toko') return l['kategori'] == 'toko_olahraga';
            return l['kategori'] == 'lapangan_badminton';
          }).toList();

    final Set<Marker> newMarkers = {};

    for (final loc in filtered) {
      final isToko = loc['kategori'] == 'toko_olahraga';
      final markerId = MarkerId(loc['id'].toString());

      newMarkers.add(
        Marker(
          markerId: markerId,
          position: LatLng(
            (loc['lat'] as num).toDouble(),
            (loc['lng'] as num).toDouble(),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isToko
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: loc['nama'] ?? '-',
            snippet: loc['alamat'] ?? (isToko ? '🏪 Toko Olahraga' : '🏸 Lapangan Badminton'),
          ),
          onTap: () => _showLocationDetail(loc),
        ),
      );
    }

    setState(() => _markers
      ..clear()
      ..addAll(newMarkers));

    if (newMarkers.isNotEmpty && _mapController != null) {
      _fitBounds(newMarkers);
    }
  }

  void _fitBounds(Set<Marker> markers) {
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final m in markers) {
      final lat = m.position.latitude;
      final lng = m.position.longitude;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.01, minLng - 0.01),
          northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
        ),
        60,
      ),
    );
  }

  void _showLocationDetail(Map<String, dynamic> loc) {
    final isToko = loc['kategori'] == 'toko_olahraga';
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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isToko
                        ? tokoColor.withOpacity(0.12)
                        : lapanganColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isToko ? '🏪 Toko Olahraga' : '🏸 Lapangan Badminton',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isToko ? tokoColor : lapanganColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              loc['nama'] ?? '-',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc['alamat'] ?? '-',
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
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(
                        (loc['lat'] as num).toDouble(),
                        (loc['lng'] as num).toDouble(),
                      ),
                      16,
                    ),
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
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
      );
    }
  }

  void _setFilter(String f) {
    setState(() => _activeFilter = f);
    _buildMarkers();
  }

  int get _tokoCount => _locations.where((l) => l['kategori'] == 'toko_olahraga').length;
  int get _lapanganCount => _locations.where((l) => l['kategori'] == 'lapangan_badminton').length;

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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_currentPosition != null) {
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentPosition!, 13),
                      );
                    } else {
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          const LatLng(-7.2575, 112.7521),
                          12,
                        ),
                      );
                    }
                    if (_markers.isNotEmpty) _fitBounds(_markers);
                  },
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-7.2575, 112.7521),
                    zoom: 12,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),

                if (_isLoading)
                  Container(
                    color: Colors.white.withOpacity(0.8),
                    child: const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  ),

                Positioned(
                  right: 16,
                  bottom: 180,
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
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4)),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _statCard('$_tokoCount', 'Toko\nOlahraga', tokoColor),
                    const SizedBox(width: 10),
                    _statCard('$_lapanganCount', 'Lapangan\nBadminton', lapanganColor),
                    const SizedBox(width: 10),
                    _statCard('${_tokoCount + _lapanganCount}', 'Total\nLokasi', primaryColor),
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}
