import 'package:latlong2/latlong.dart';

class SafeZone {
  final String id;
  final String name;
  final String description;
  final LatLng coordinates;

  const SafeZone({
    required this.id,
    required this.name,
    required this.description,
    required this.coordinates,
  });

  // Pre-defined Safe Zones around TARUMT Penang (Approx center: 5.4614, 100.2818)
  static final List<SafeZone> predefinedZones = [
    SafeZone(
      id: 'z1',
      name: 'Library',
      description: 'Main Campus Library Entrance',
      coordinates: const LatLng(5.461623, 100.281987),
    ),
    SafeZone(
      id: 'z2',
      name: 'Student Center',
      description: 'Student Hub Ground Floor',
      coordinates: const LatLng(5.461234, 100.282123),
    ),
    SafeZone(
      id: 'z3',
      name: 'Cafeteria A',
      description: 'Beside Block C',
      coordinates: const LatLng(5.461800, 100.281500),
    ),
    SafeZone(
      id: 'z4',
      name: 'Main Hall',
      description: 'Tunku Abdul Rahman Hall Foyer',
      coordinates: const LatLng(5.462100, 100.281850),
    ),
    SafeZone(
      id: 'z5',
      name: 'Sports Complex',
      description: 'Badminton Court Area',
      coordinates: const LatLng(5.461000, 100.281200),
    ),
    SafeZone(
      id: 'z6',
      name: 'Hostel Block B',
      description: 'Hostel B Security Guard Post',
      coordinates: const LatLng(5.460800, 100.282500),
    ),
  ];

  static SafeZone? findByName(String name) {
    try {
      return predefinedZones.firstWhere((z) => z.name == name);
    } catch (_) {
      return null;
    }
  }
}
