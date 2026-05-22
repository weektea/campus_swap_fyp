import 'package:campus_swap/core/api/api_client.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> imageUrls;
  final String category;
  final String sellerName;
  final String sellerId;
  final String condition;
  final DateTime postedAt;
  final String type;
  final double rentalPricePerDay;
  final int maxRentalDuration;
  final String subCategoryName;
  final double rentalDeposit;
  final double co2Saved;
  final String status;
  final double sellerReputation;
  final int sellerTotalReviews;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.imageUrls,
    required this.category,
    required this.sellerName,
    required this.sellerId,
    required this.condition,
    required this.postedAt,
    this.type = 'Sale',
    this.rentalPricePerDay = 0.0,
    this.maxRentalDuration = 7,
    this.subCategoryName = '',
    this.rentalDeposit = 0.0,
    this.co2Saved = 0.0,
    this.status = 'Available',
    this.sellerReputation = 5.0,
    this.sellerTotalReviews = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    var list = json['image_urls'] as List? ?? [];
    String baseHost = ApiClient.baseUrl.replaceAll('/api', '');
    List<String> images = list.map((i) {
      String path = i.toString();
      if (path.startsWith('/uploads')) {
        return '$baseHost$path';
      }
      return path;
    }).toList();
    
    return Product(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      // Parse price safely whether it comes as int, double or String
      price: double.tryParse(json['price'].toString()) ?? 0.0, 
      imageUrl: images.isNotEmpty ? images[0] : '',
      imageUrls: images,
      category: json['category'] as String,
      sellerName: json['seller']?['full_name'] ?? 'Unknown Seller',
      sellerId: json['seller_id'] as String? ?? '',
      condition: json['condition'] as String? ?? 'Good',
      postedAt: DateTime.parse(json['createdAt']),
      type: json['type'] as String? ?? 'Sale',
      rentalPricePerDay: double.tryParse(json['rental_price_per_day'].toString()) ?? 0.0,
      maxRentalDuration: int.tryParse(json['max_rental_duration'].toString()) ?? 7,
      subCategoryName: json['sub_category_name'] as String? ?? '',
      rentalDeposit: double.tryParse(json['rental_deposit'].toString()) ?? 0.0,
      co2Saved: double.tryParse(json['co2_saved'].toString()) ?? 0.0,
      status: json['status'] as String? ?? 'Available',
      sellerReputation: double.tryParse(json['seller']?['reputation_score']?.toString() ?? '5.0') ?? 5.0,
      sellerTotalReviews: int.tryParse(json['seller']?['total_reviews']?.toString() ?? '0') ?? 0,
    );
  }
}
