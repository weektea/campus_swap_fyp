import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/features/location/domain/entities/safe_zone.dart';
import 'package:campus_swap/core/api/api_client.dart';

class SafeZoneMapPage extends StatefulWidget {
  final SafeZone? initialZone;

  const SafeZoneMapPage({super.key, this.initialZone});

  @override
  State<SafeZoneMapPage> createState() => _SafeZoneMapPageState();
}

class _SafeZoneMapPageState extends State<SafeZoneMapPage> {
  final MapController _mapController = MapController();
  SafeZone? _selectedZone;
  final ApiClient _apiClient = ApiClient();
  List<SafeZone> _zones = [];
  bool _isLoading = true;

  // Corrected Center of TARUMT Penang
  final LatLng _campusCenter = const LatLng(5.4568, 100.2860);

  @override
  void initState() {
    super.initState();
    _selectedZone = widget.initialZone;
    _fetchZones();
  }

  Future<void> _fetchZones() async {
    try {
      final response = await _apiClient.get('/zones');
      if (response is List) {
        final loadedZones = response
            .map((item) => SafeZone.fromJson(item as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _zones = loadedZones;
            _isLoading = false;
            if (_selectedZone != null && loadedZones.isNotEmpty) {
              try {
                _selectedZone = loadedZones.firstWhere((z) => z.name == _selectedZone!.name);
              } catch (_) {}
            }
          });
        }
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      debugPrint('Error fetching zones: $e');
      if (mounted) {
        setState(() {
          _zones = SafeZone.predefinedZones;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Safe Zone', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedZone?.coordinates ?? _campusCenter,
              initialZoom: 17.0,
              maxZoom: 19.0,
              minZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.campusswap.app',
              ),
              MarkerLayer(
                markers: _zones.map((zone) {
                  final isSelected = _selectedZone?.id == zone.id;
                  return Marker(
                    point: zone.coordinates,
                    width: 100,
                    height: 90,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedZone = zone);
                        _mapController.move(zone.coordinates, 17.5);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                              border: Border.all(color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary, width: 2),
                            ),
                            child: Icon(
                              Icons.security_rounded,
                              color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))],
                              ),
                              child: Text(
                                zone.name,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Safety Banner overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap on a pre-defined Safe Zone to select it as the meetup location.',
                      style: GoogleFonts.outfit(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Selection Card
          if (_selectedZone != null)
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedZone!.name, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_selectedZone!.description, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context, _selectedZone);
                        },
                        child: Text('Confirm Location', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
