import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _analyzeImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _imageFile = File(image.path);
      _isAnalyzing = true;
    });

    try {
      final apiClient = ApiClient();
      final result = await apiClient.postMultipart('/products/classify', image.path);
      
      setState(() {
        _isAnalyzing = false;
        _selectedCategory = result['category'] ?? 'Others';
        if (_titleController.text.isEmpty) {
            _titleController.text = 'Detected ${result['category']}';
        }
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

  Future<void> _fetchPriceSuggestion() async {
      if (_selectedCategory == null) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a category first', style: GoogleFonts.outfit())));
           return;
      }
      
      try {
          final apiClient = ApiClient();
          final res = await apiClient.post('/products/price-suggestion', {
              'category': _selectedCategory,
              'condition': 'Good' // Default for MVP
          });
          
          if (mounted) {
              final price = res['estimated_price'];
              // If simple heuristic returned sale price, but we are renting, maybe adjust?
              // For now, let's just use what ML gives.
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
             'condition': 'Good'
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
                  image: _imageFile != null 
                    ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                    : null,
                ),
                child: _isAnalyzing 
                  ? const Center(child: CircularProgressIndicator())
                  : _imageFile != null 
                    ? const SizedBox() // Show image
                    : Column(
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
                      TextButton(onPressed: (){}, child: Text('Edit', style: GoogleFonts.outfit()))
                    ],
                  ),
                ),
              ),

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
      final Map<String, dynamic> body = {
        'title': _titleController.text,
        'description': _descController.text,
        'category': _selectedCategory ?? 'Others',
        'condition': 'Good', // Default for now
        'seller_id': session.userId,
        'type': _listingType,
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
