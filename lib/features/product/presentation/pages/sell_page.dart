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

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _analyzeImage() async {
    // Optimization: Resize image to max 1024px width and 80% quality to save bandwidth
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024, 
      imageQuality: 80
    );
    if (image == null) return;

    setState(() {
      _imageFile = image;
      _isAnalyzing = true;
    });

    try {
      final apiClient = ApiClient();
      final result = await apiClient.postMultipart('/products/classify', image);
      
      setState(() {
        _isAnalyzing = false;
        _selectedCategory = result['category'] ?? 'Others';
        // Removed auto-filling title to avoid "Detected Category" awkwardness
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Detected: ${result['category']} (${(result['confidence'] * 100).toStringAsFixed(0)}%)')),
        );
      }
    } catch (e) {
      print('AI Error: $e');
      setState(() { 
        _isAnalyzing = false;
        // Fallback to manual selection if AI fails
        _selectedCategory = 'Others';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('AI Analysis failed. Please enter details manually.'))
        );
      }
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
            GestureDetector(
              onTap: _analyzeImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_imageFile != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: kIsWeb 
                              ? Image.network(_imageFile!.path, fit: BoxFit.contain)
                              : Image.file(File(_imageFile!.path), fit: BoxFit.contain),
                        ),
                    if (_isAnalyzing)
                        const Center(child: CircularProgressIndicator())
                    else if (_imageFile == null)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             Icon(Icons.camera_alt_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
                             const SizedBox(height: 12),
                             Text('Tap to upload photo & auto-detect', style: GoogleFonts.outfit()),
                             TextButton(
                               onPressed: _analyzeImage, 
                               child: Text('Open Gallery', style: GoogleFonts.outfit())
                              )
                          ],
                        ),
                  ],
                ),
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
    if (price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Price must be greater than 0', style: GoogleFonts.outfit())));
        return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ApiClient();
      
      // 1. Upload Image first if exists
      String? uploadedImageUrl;
      if (_imageFile != null) {
          try {
              final uploadRes = await apiClient.postMultipart('/upload', _imageFile!);
              uploadedImageUrl = uploadRes['url'];
           } catch(e) {
              print("Upload failed: $e");
              // Decide whether to fail hard or soft. Let's fail hard if image exists but fails.
              throw Exception("Image upload failed. Check connection.");
           }
      }

      final Map<String, dynamic> body = {
        'title': _titleController.text,
        'description': _descController.text,
        'category': _selectedCategory ?? 'Others',
        'condition': _selectedCondition, 
        'seller_id': session.userId,
        'type': _listingType,
        'image_urls': uploadedImageUrl != null ? [uploadedImageUrl] : [],
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
             _imageFile = null;
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
