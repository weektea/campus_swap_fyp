import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReportListingPage extends StatefulWidget {
  final Product product;

  const ReportListingPage({super.key, required this.product});

  @override
  State<ReportListingPage> createState() => _ReportListingPageState();
}

class _ReportListingPageState extends State<ReportListingPage> {
  final _detailsController = TextEditingController();
  String _selectedCategory = 'Scam/Fraud';
  final List<String> _categories = [
    'Scam/Fraud',
    'Fake Item',
    'Prohibited Item',
    'Inappropriate Content',
    'Spam'
  ];

  final Map<String, String> _categoryMapping = {
    'Scam/Fraud': 'Scam',
    'Fake Item': 'Fake',
    'Prohibited Item': 'Prohibited',
    'Inappropriate Content': 'Prohibited',
    'Spam': 'Spam',
  };

  bool _isLoading = false;
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can upload a maximum of 3 evidence images.')),
      );
      return;
    }
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        if (_selectedImages.length + images.length > 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can select a maximum of 3 evidence images.')),
          );
          _selectedImages.addAll(images.take(3 - _selectedImages.length));
        } else {
          _selectedImages.addAll(images);
        }
      });
    }
  }

  Future<void> _submitReport() async {
    if (_detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide details for the report.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> evidenceUrls = [];
      if (_selectedImages.isNotEmpty) {
        final uploadFutures = _selectedImages.map((img) => ApiClient().postMultipart('/upload', img));
        final uploadResults = await Future.wait(uploadFutures);
        for (final res in uploadResults) {
          if (res != null && res['url'] != null) {
            evidenceUrls.add(res['url']);
          }
        }
      }

      final body = {
        'violation_type': _categoryMapping[_selectedCategory] ?? 'Spam',
        'description': _detailsController.text.trim(),
        'evidence_urls': evidenceUrls,
      };

      await ApiClient().post('/products/${widget.product.id}/report', body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing reported successfully. Moderators will review.')),
        );
        Navigator.pop(context, 'reported'); // Return reported result to hide it
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString();
        // Remove API Error prefix if present
        if (errMsg.startsWith('Exception: ')) {
          errMsg = errMsg.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryGreen = Color(0xFF006940);

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text('Report Listing', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Summary Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: widget.product.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.product.imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              )
                            : Container(width: 70, height: 70, color: Colors.grey[200]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'RM ${widget.product.price}',
                              style: GoogleFonts.outfit(
                                color: primaryGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Seller: ${widget.product.sellerName}',
                              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Category Dropdown
                Text(
                  'Reason for Report',
                  style: GoogleFonts.outfit(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? Colors.grey[900] : Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      items: _categories.map((String val) {
                        return DropdownMenuItem<String>(
                          value: val,
                          child: Text(val, style: GoogleFonts.outfit()),
                        );
                      }).toList(),
                      onChanged: (newVal) {
                        if (newVal != null) {
                          setState(() {
                            _selectedCategory = newVal;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                Text(
                  'Details of Violation',
                  style: GoogleFonts.outfit(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _detailsController,
                  maxLines: 4,
                  style: GoogleFonts.outfit(),
                  decoration: InputDecoration(
                    hintText: 'Describe why this listing violates policies (e.g., fake item, scam)...',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryGreen, width: 2),
                    ),
                    fillColor: isDark ? Colors.grey[900] : Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Upload Evidence
                Text(
                  'Evidence Photos (Optional, Max 3)',
                  style: GoogleFonts.outfit(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined, size: 40, color: primaryGreen),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to select screenshots or photo evidence',
                          style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Preview Selected Images
                if (_selectedImages.isNotEmpty) ...[
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        final xfile = _selectedImages[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                  image: DecorationImage(
                                    image: kIsWeb ? NetworkImage(xfile.path) : FileImage(File(xfile.path)) as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Submit Report',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            ),
        ],
      ),
    );
  }
}
