import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/core/api/api_client.dart';

class RateExperiencePage extends StatefulWidget {
  final String transactionId;
  final String revieweeId;
  final bool isSeller;
  final String revieweeName;
  final String productName;
  final VoidCallback onSubmitted;

  const RateExperiencePage({
    super.key,
    required this.transactionId,
    required this.revieweeId,
    required this.isSeller,
    required this.revieweeName,
    required this.productName,
    required this.onSubmitted,
  });

  @override
  State<RateExperiencePage> createState() => _RateExperiencePageState();
}

class _RateExperiencePageState extends State<RateExperiencePage> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  List<String> get _availableTags {
    if (widget.isSeller) {
      // Seller rating Buyer (Behavior, Punctuality & Communication)
      return [
        '🤝 Polite & Respectful',
        '⏱️ Punctual for Meetup',
        '💵 Fast Payment / Cash Ready',
        '💬 Responsive & Clear',
        '⚡ Decisive & No Hassle',
        '⭐ Recommended Buyer',
      ];
    } else {
      // Buyer rating Seller (Item condition match & Service attitude)
      return [
        '📦 Matches Description',
        '✨ Item in Great Condition',
        '🤝 Friendly & Helpful',
        '⏱️ Punctual for Meetup',
        '⚡ Fast Response',
        '💯 Honest Seller',
        '🏷️ Fair Price',
        '🧼 Clean & Well Kept',
      ];
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getFriendlyErrorMessage(dynamic e) {
    final message = e.toString();
    if (message.contains('SocketException') || message.contains('Connection error') || message.contains('Failed host lookup')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (message.contains('TimeoutException') || message.contains('Connection timed out')) {
      return 'Connection timed out. Please check your network and try again.';
    }
    return message.replaceAll(RegExp(r'^Exception:\s*'), '').replaceAll(RegExp(r'^ApiException:\s*'), '');
  }

  void _submitReview() async {
    if (_rating == 0) {
      _showErrorSnackBar(context, 'Please select a star rating.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ApiClient();
      
      String combinedReview = _commentController.text.trim();
      if (_selectedTags.isNotEmpty) {
          final tagsStr = _selectedTags.map((e) => '[$e]').join(' ');
          combinedReview = '$tagsStr\n\n$combinedReview'.trim();
      }

      await apiClient.post('/reviews', {
        'transaction_id': widget.transactionId,
        'reviewee_id': widget.revieweeId,
        'rating': _rating,
        'comment': combinedReview,
      });

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackBar(context, 'Review Submitted! 🎉');
        widget.onSubmitted();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Submission failed: ${_getFriendlyErrorMessage(e)}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rate Experience',
          style: GoogleFonts.outfit(color: primary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // User Avatar & Title
            CircleAvatar(
              radius: 40,
              backgroundColor: primary.withValues(alpha: 0.1),
              child: Text(
                  widget.revieweeName.isNotEmpty ? widget.revieweeName[0].toUpperCase() : '?',
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rate @${widget.revieweeName}',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.isSeller ? 'Rating Buyer • For: ${widget.productName}' : 'Rating Seller • For: ${widget.productName}',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            
            const SizedBox(height: 24),
            
            // Double blind alert
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD6EBE0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF1B5E20), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.outfit(color: Colors.black87, fontSize: 13, height: 1.4),
                        children: const [
                          TextSpan(text: 'Double-Blind System: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'Your review is hidden and protected. It will only be published once both parties have submitted their feedback, ensuring 100% honest reviews.'),
                        ]
                      )
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 48,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Role-specific Tag Section Header & Chips
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isSeller 
                    ? 'Buyer Attitude & Behavior Tags' 
                    : 'Item Condition & Seller Service Tags',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: primary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag, style: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : Colors.black87, 
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                      )),
                      selected: isSelected,
                      selectedColor: primary,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20), 
                          side: BorderSide(color: isSelected ? primary : Colors.grey[300]!)
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Text Area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Share more details about your experience...',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitReview,
              icon: _isSubmitting ? const SizedBox.shrink() : const Icon(Icons.lock_rounded, size: 20),
              label: _isSubmitting 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Submit Securely', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D503C), // Dark green
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
