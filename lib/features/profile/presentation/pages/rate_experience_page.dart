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

  final List<String> _tags = ['Friendly', 'Punctual', 'Good Condition', 'Responsive', 'Polite'];
  final Set<String> _selectedTags = {};

  void _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a star rating.'), backgroundColor: Colors.red));
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

      await apiClient.patch('/transactions/${widget.transactionId}/rate', {
        'rating': _rating,
        'review': combinedReview,
        'is_seller': widget.isSeller
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Review Submitted! 🎉', style: GoogleFonts.outfit()), backgroundColor: Colors.green));
        widget.onSubmitted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
              'For: ${widget.productName}',
              style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey[600]),
            ),
            
            const SizedBox(height: 24),
            
            // Double blind alert
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD6EBE0), // Light green tint based on screenshot
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

            // Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag, style: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : Colors.black87, 
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
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
