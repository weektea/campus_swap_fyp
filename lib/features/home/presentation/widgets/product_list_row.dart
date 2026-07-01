import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductListRow extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const ProductListRow({
    super.key,
    required this.product,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRent = product.type.toLowerCase() == 'rent';
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 124,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Image Section with Badges
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 124,
                height: 124,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[100],
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey[400],
                                size: 36,
                              ),
                            ),
                          ),
                    
                    // Top Left Badge: Rent/Sale
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isRent ? const Color(0xFF00C875) : const Color(0xFF337BFF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isRent ? 'RENT' : 'SALE',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right: Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row for Category & Favorite Heart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          product.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: onFavoriteToggle,
                          child: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 20,
                            color: isFavorite ? Colors.red : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Title
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Price & Condition Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price text
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: isRent
                                    ? 'RM ${product.rentalPricePerDay.toStringAsFixed(2)}'
                                    : 'RM ${product.price.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (isRent)
                                TextSpan(
                                  text: ' /day',
                                  style: GoogleFonts.outfit(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Condition Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.condition,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF475569),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Divider
                    Container(
                      height: 1,
                      color: Colors.grey[100],
                    ),
                    const SizedBox(height: 6),

                    // Seller Avatar, Username & Stars + Date Posted
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          child: Text(
                            product.sellerName.isNotEmpty
                                ? product.sellerName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 8,
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  product.sellerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF334155),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.star_rounded, size: 10, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                product.sellerReputation.toStringAsFixed(1),
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatTimeAgo(product.postedAt),
                          style: GoogleFonts.outfit(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
