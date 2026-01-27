import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  bool _isAnalyzing = false;
  String? _selectedCategory;
  String _listingType = 'Sale'; // 'Sale' or 'Rent'
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _maxDurationController = TextEditingController();

  final List<XFile> _imageFiles = [];
  final ImagePicker _picker = ImagePicker();

  static const int _maxImages = 9;

  Future<void> _pickImages() async {
    if (_imageFiles.length >= _maxImages) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum $_maxImages images allowed.')));
        return;
    }

    final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        imageQuality: 80 // Compression is key for size limit
    );
    
    if (images.isNotEmpty) {
        final remainingSlots = _maxImages - _imageFiles.length;
        final imagesToAdd = images.take(remainingSlots).toList();
        
        if (images.length > remainingSlots) {
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Only added first $remainingSlots images. Max $_maxImages allowed.')));
             }
        }

        setState(() {
            _imageFiles.addAll(imagesToAdd);
            // If first image added and no category, analyze it
            if (_imageFiles.length == imagesToAdd.length && _selectedCategory == null) {
                _analyzeImage(_imageFiles.first);
            }
        });
    }
  }

  Future<void> _analyzeImage(XFile image) async {
    setState(() => _isAnalyzing = true);
    try {
      final apiClient = ApiClient();
      final result = await apiClient.postMultipart('/products/classify', image);
      
      setState(() {
        _isAnalyzing = false;
        _selectedCategory = result['category'] ?? 'Others';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Detected: ${result['category']} (${(result['confidence'] * 100).toStringAsFixed(0)}%)')),
        );
      }
    } catch (e) {
      // print('AI Error: $e');
      setState(() { 
        _isAnalyzing = false;
        _selectedCategory = 'Others';
      });
    }
  }

   final List<String> _categories = [
    'Books', 'Electronics', 'Clothing', 'Furniture', 'Stationery', 'Bicycles', 'Others'
  ];

  final List<String> _conditions = [
    'New', 'Like New', 'Good', 'Fair', 'Poor'
  ];

  String _selectedCondition = 'Good';
  
  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Category', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  return ChoiceChip(
                    label: Text(category, style: GoogleFonts.outfit()),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchPriceSuggestion() async {
      if (_selectedCategory == null) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a category first', style: GoogleFonts.outfit())));
           return;
      }
      
      try {
          final apiClient = ApiClient();
          final res = await apiClient.post('/products/price-suggestion', {
              'category': _selectedCategory,
              'condition': _selectedCondition 
          });
          
          if (mounted) {
              final price = res['estimated_price'];
              double finalPrice = double.tryParse(price.toString()) ?? 0.0;
              if (_listingType == 'Rent') {
                  finalPrice = finalPrice * 0.1; // Rule of thumb: Rent is 10% of value
              }
              
              setState(() {
                  _priceController.text = finalPrice.toStringAsFixed(2);
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Price Suggested!', style: GoogleFonts.outfit())));
          }
      } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get suggestion: $e')));
      }
  }

  void _generateDescription() async {
     if (_titleController.text.isEmpty || _selectedCategory == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter title and select category', style: GoogleFonts.outfit())));
          return;
     }

     setState(() {
         _descController.text = "Generating...";
     });
     
     try {
         final apiClient = ApiClient();
         final res = await apiClient.post('/products/generate-description', {
             'title': _titleController.text,
             'category': _selectedCategory,
             'condition': _selectedCondition
         });
         
         if (mounted) {
             setState(() {
                 _descController.text = res['description'] ?? 'No description generated.';
             });
         }
     } catch (e) {
         if (mounted) {
             setState(() {
                 _descController.text = "";
             });
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gen Desc Failed: $e')));
         }
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Listing', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Upload Section (Smart Recognition)
            SizedBox(
                height: 120,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imageFiles.length + 1,
                    itemBuilder: (context, index) {
                        if (index == 0) {
                            return GestureDetector(
                                onTap: _pickImages,
                                child: Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[300]!)
                                    ),
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                            Icon(Icons.add_a_photo_rounded, color: Theme.of(context).colorScheme.primary),
                                            const SizedBox(height: 4),
                                            Text("Add Photos", style: GoogleFonts.outfit(fontSize: 12)),
                                            Text("(Max 9)", style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey))
                                        ],
                                    ),
                                ),
                            );
                        }
                        
                        final image = _imageFiles[index - 1];
                        final isCover = (index - 1) == 0;

                        return Stack(
                            children: [
                                Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: kIsWeb 
                                          ? Image.network(image.path, fit: BoxFit.cover, height: 120)
                                          : Image.file(File(image.path), fit: BoxFit.cover, height: 120),
                                    ),
                                ),
                                if (isCover)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 12, // Match margin
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                      ),
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Text("Cover", style: GoogleFonts.outfit(color: Colors.white, fontSize: 10)),
                                    ),
                                  ),
                                Positioned(
                                    top: 4,
                                    right: 16, // Adjusted for margin
                                    child: GestureDetector(
                                        onTap: () {
                                            setState(() {
                                                _imageFiles.removeAt(index - 1);
                                            });
                                        },
                                        child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                            child: const Icon(Icons.close, color: Colors.white, size: 14)
                                        ),
                                    ),
                                ),
                                if (_isAnalyzing && index == 1) // Show spinner on first image if analyzing
                                    const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                            ],
                        );
                    },
                ),
            ),
            const SizedBox(height: 24),

            // Listing Type Toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Sale', label: Text('For Sale'), icon: Icon(Icons.sell)),
                ButtonSegment(value: 'Rent', label: Text('For Rent'), icon: Icon(Icons.access_time)),
              ],
              selected: {_listingType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _listingType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Basic Fields
            if (_selectedCategory != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 20),
                      const SizedBox(width: 8),
                      Text('Category: $_selectedCategory', style: GoogleFonts.outfit()),
                      const Spacer(),
                      TextButton(
                          onPressed: _showCategoryPicker, 
                          child: Text('Edit', style: GoogleFonts.outfit())
                      )
                    ],
                  ),
                ),
              ),

             // Condition Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCondition,
              decoration: InputDecoration(
                labelText: 'Condition',
                labelStyle: GoogleFonts.outfit(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.outfit()))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCondition = val);
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Calculus Textbook',
                labelStyle: GoogleFonts.outfit(),
              ),
              style: GoogleFonts.outfit(),
            ),
            const SizedBox(height: 16),
             TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: _listingType == 'Sale' ? 'Price (RM)' : 'Rental Price (RM / Day)',
                prefixText: 'RM ',
                labelStyle: GoogleFonts.outfit(),
              ),
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(),
            ),

            if (_listingType == 'Rent') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxDurationController,
                  decoration: InputDecoration(
                    labelText: 'Max Duration (Days)',
                    hintText: 'e.g. 7',
                    labelStyle: GoogleFonts.outfit(),
                  ),
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(),
                ),
            ],

             const SizedBox(height: 8),
             Align(
               alignment: Alignment.centerRight,
               child: TextButton.icon(
                 onPressed: _fetchPriceSuggestion,
                 icon: const Icon(Icons.analytics_outlined, size: 16),
                 label: Text('Get Price Suggestion', style: GoogleFonts.outfit()),
               ),
             ),

             const SizedBox(height: 16),
             TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: GoogleFonts.outfit(),
                alignLabelWithHint: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.auto_fix_high),
                  tooltip: 'Generate Description',
                  onPressed: _generateDescription,
                )
              ),
              style: GoogleFonts.outfit(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _postItem, 
              child: _isSubmitting 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : Text('Post Item', style: GoogleFonts.outfit()),
            )
          ],
        ),
      ),
    );
  }

  bool _isSubmitting = false;

  void _postItem() async {
    final session = UserSession();
    if (!session.isLoggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please login to post items', style: GoogleFonts.outfit())));
        return;
    }

    if (_titleController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in title and price', style: GoogleFonts.outfit())));
      return;
    }

    final double price = double.tryParse(_priceController.text) ?? 0.0;
    if (price < 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Price cannot be negative', style: GoogleFonts.outfit())));
        return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ApiClient();
      
      // 1. Upload Images
      List<String> uploadedImageUrls = [];
      for (var img in _imageFiles) {
          try {
              final uploadRes = await apiClient.postMultipart('/upload', img);
              if (uploadRes['url'] != null) {
                  uploadedImageUrls.add(uploadRes['url']);
              }
           } catch(e) {
              // print("Upload failed for one image: $e");
           }
      }

      final Map<String, dynamic> body = {
        'title': _titleController.text,
        'description': _descController.text,
        'category': _selectedCategory ?? 'Others',
        'condition': _selectedCondition, 
        'seller_id': session.userId,
        'type': _listingType,
        'image_urls': uploadedImageUrls,
      };

      if (_listingType == 'Sale') {
          body['price'] = double.tryParse(_priceController.text) ?? 0.0;
      } else {
          body['rental_price_per_day'] = double.tryParse(_priceController.text) ?? 0.0;
          body['max_rental_duration'] = int.tryParse(_maxDurationController.text) ?? 7;
      }

      await apiClient.post('/products', body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item Posted Successfully!', style: GoogleFonts.outfit())));
        // Reset form or nav back
        _titleController.clear();
        _priceController.clear();
        _descController.clear();
        setState(() {
             _imageFiles.clear();
             _selectedCategory = null;
             _selectedCondition = 'Good';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
