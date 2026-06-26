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

  // Corrected Pre-defined Safe Zones around TARUMT Penang (Approx center: 5.457, 100.286)
  static final List<SafeZone> predefinedZones = [
    SafeZone(
      id: 'z1',
      name: 'Library',
      description: 'Main Campus Library Entrance',
      coordinates: const LatLng(5.457222, 100.285511),
    ),
    SafeZone(
      id: 'z2',
      name: 'Student Center',
      description: 'Student Hub Ground Floor',
      coordinates: const LatLng(5.457544, 100.286012),
    ),
    SafeZone(
      id: 'z3',
      name: 'Cafeteria A',
      description: 'Beside Block C',
      coordinates: const LatLng(5.457400, 100.285800),
    ),
    SafeZone(
      id: 'z4',
      name: 'Main Hall',
      description: 'Tunku Abdul Rahman Hall Foyer',
      coordinates: const LatLng(5.456512, 100.285222),
    ),
    SafeZone(
      id: 'z5',
      name: 'Sports Complex',
      description: 'Badminton Court Area',
      coordinates: const LatLng(5.456000, 100.284800),
    ),
    SafeZone(
      id: 'z6',
      name: 'Hostel Block B',
      description: 'Hostel B Security Guard Post',
      coordinates: const LatLng(5.455800, 100.286000),
    ),
  ];

  factory SafeZone.fromJson(Map<String, dynamic> json) {
    double lat = 0.0;
    if (json['latitude'] != null) {
      if (json['latitude'] is num) {
        lat = (json['latitude'] as num).toDouble();
      } else {
        lat = double.tryParse(json['latitude'].toString()) ?? 0.0;
      }
    }
    double lng = 0.0;
    if (json['longitude'] != null) {
      if (json['longitude'] is num) {
        lng = (json['longitude'] as num).toDouble();
      } else {
        lng = double.tryParse(json['longitude'].toString()) ?? 0.0;
      }
    }
    return SafeZone(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      coordinates: LatLng(lat, lng),
    );
  }

  static SafeZone? findByName(String name) {
    try {
      return predefinedZones.firstWhere((z) => z.name == name);
    } catch (_) {
      return null;
    }
  }
}
