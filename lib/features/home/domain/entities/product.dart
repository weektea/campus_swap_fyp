class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String sellerName;
  final String sellerId;
  final String condition; // 'New', 'Like New', 'Good', 'Fair'
  final String type; // 'Sale' or 'Rent'
  final double rentalPricePerDay;
  final DateTime postedAt;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.sellerName,
    required this.sellerId,
    required this.condition,
    required this.postedAt,
    this.type = 'Sale',
    this.rentalPricePerDay = 0.0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      // Parse price safely whether it comes as int, double or String
      price: double.tryParse(json['price'].toString()) ?? 0.0, 
      imageUrl: (json['image_urls'] != null && (json['image_urls'] as List).isNotEmpty)
          ? json['image_urls'][0] as String
          : '',
      category: json['category'] as String,
      sellerName: json['seller']?['full_name'] ?? 'Unknown Seller',
      sellerId: json['seller_id'] as String? ?? '',
      condition: json['condition'] as String? ?? 'Good',
      postedAt: DateTime.parse(json['createdAt']),
      type: json['type'] as String? ?? 'Sale',
      rentalPricePerDay: double.tryParse(json['rental_price_per_day'].toString()) ?? 0.0,
    );
  }
}
