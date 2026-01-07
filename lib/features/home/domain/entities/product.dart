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
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    var list = json['image_urls'] as List? ?? [];
    List<String> images = list.map((i) => i.toString()).toList();
    
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
    );
  }
}
