import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'dart:io' show File;

class SellPage extends StatefulWidget {
  final bool isPushed;
  const SellPage({super.key, this.isPushed = false});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  bool _isAnalyzing = false;
  String? _selectedCategory;
  String? _selectedSubCategory;
  String _listingType = 'Sale'; // 'Sale' or 'Rent'
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _maxDurationController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();

  final List<XFile> _imageFiles = [];
  XFile? _videoFile;
  final ImagePicker _picker = ImagePicker();

  static const int _maxImages = 9;

  Map<String, List<String>> _categoriesMap = {};

  @override
  void initState() {
    super.initState();
    _categoriesMap = Map.from(_fallbackCategoriesMap);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/categories');
      if (response is List) {
        final Map<String, List<String>> loadedMap = {};
        for (var cat in response) {
          final String catName = cat['name'] as String;
          final List<dynamic> subs = cat['subcategories'] as List<dynamic>;
          final List<String> subNames = subs.map((s) => s['name'] as String).toList();
          if (!subNames.contains('Others')) {
            subNames.add('Others');
          }
          loadedMap[catName] = subNames;
        }
        if (loadedMap.isNotEmpty) {
          if (mounted) {
            setState(() {
              _categoriesMap = loadedMap;
            });
          }
        }
      }
    } catch (e) {
      // Bypassed: keep using fallback categories
    }
  }

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

  Future<void> _pickVideo() async {
    if (_videoFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only 1 video allowed. Remove existing to change.')));
        return;
    }
    
    final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 15),
    );
    
    if (video != null) {
        setState(() {
            _videoFile = video;
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
        final mlCategory = result['category'] ?? 'Others';
        final mlSubCategory = result['sub_category'] ?? 'Others';

        // Add to map dynamically if it doesn't exist to ensure co-existence
        if (!_categoriesMap.containsKey(mlCategory)) {
          _categoriesMap[mlCategory] = [mlSubCategory];
        } else if (!_categoriesMap[mlCategory]!.contains(mlSubCategory)) {
          _categoriesMap[mlCategory]!.add(mlSubCategory);
        }

        _selectedCategory = mlCategory;
        _selectedSubCategory = mlSubCategory;
        
        // Fulfill UC07: Auto-fill Title and Price based on category if empty
        if (_titleController.text.isEmpty) {
             _titleController.text = "Pre-loved $_selectedCategory";
        }
        if (_priceController.text.isEmpty) {
             _priceController.text = _listingType == 'Sale' ? "15.00" : "5.00";
        }
      });

      // Auto-generate description now that we have a title and category
      _generateDescription();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Auto-Filled: $_selectedCategory (${(result['confidence'] * 100).toStringAsFixed(0)}%)')),
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

  static final Map<String, List<String>> _fallbackCategoriesMap = {
     'Books & Study Materials': ['Books', 'Calculators', 'Notes & Past Papers', 'Others'],
     'Electronics & Gadgets': ['Audio', 'Laptops', 'Others', 'PC Accessories', 'Smartphones', 'Tablets'],
     'Fashion & Accessories': ['Bags & Luggage', 'Clothing', 'Fashion Accessories', 'Shoes'],
     'Furniture & Appliances': ['Appliances', 'Chairs', 'Others', 'Sofas', 'Storage', 'Tables & Desks'],
     'Sports': ['Apparel', 'Bicycles', 'Equipment', 'Others'],
     'Stationery': ['Art Supplies', 'Others', 'Paper', 'Writing'],
     'Others': ['Cosmetics & Beauty', 'Drinkware', 'Miscellaneous']
  };

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
        return StatefulBuilder(
          builder: (context, setModalState) {
            final categories = _categoriesMap.keys.toList();
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              height: MediaQuery.of(context).size.height * 0.5,
              child: SingleChildScrollView(
                 child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. Select Category', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: categories.map((c) => ChoiceChip(
                         label: Text(c, style: GoogleFonts.outfit()),
                         selected: _selectedCategory == c,
                         onSelected: (sel) {
                            if (sel) {
                               setModalState(() {
                                  _selectedCategory = c;
                                  _selectedSubCategory = _categoriesMap[c]!.first; // Reset sub
                               });
                               setState(() {}); // Update parent
                            }
                         }
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                    if (_selectedCategory != null) ...[
                        Text('2. Select Sub-Category', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _categoriesMap[_selectedCategory!]!.map((sub) => ChoiceChip(
                             label: Text(sub, style: GoogleFonts.outfit(color: _selectedSubCategory == sub ? Colors.white : Colors.black)),
                             selected: _selectedSubCategory == sub,
                             selectedColor: Theme.of(context).colorScheme.primary,
                             onSelected: (sel) {
                                if (sel) {
                                   setModalState(() => _selectedSubCategory = sub);
                                   setState(() {}); // Update parent
                                   Navigator.pop(context);
                                }
                             }
                          )).toList(),
                        )
                    ]
                  ],
                ),
              ),
            );
          }
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
         final double? enteredPrice = double.tryParse(_priceController.text);
         final res = await apiClient.post('/products/generate-description', {
             'title': _titleController.text,
             'category': _selectedCategory,
             'condition': _selectedCondition,
             'type': _listingType,
             'price': enteredPrice ?? 0.0
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

  void _resetForm() {
      _titleController.clear();
      _priceController.clear();
      _descController.clear();
      _maxDurationController.clear();
      _depositController.clear();
      setState(() {
          _imageFiles.clear();
          _videoFile = null;
          _selectedCategory = null;
          _selectedSubCategory = null;
          _selectedCondition = 'Good';
          _listingType = 'Sale';
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Listing', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: widget.isPushed,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _resetForm,
            tooltip: 'Reset Form',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Media Upload Section (Images + Video)
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    children: [
                        // Add Photos Button
                        GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                                width: 100,
                                height: 120,
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
                                        Text("(Max $_maxImages)", style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey))
                                    ],
                                ),
                            ),
                        ),
                        // Add Video Button
                        GestureDetector(
                            onTap: _pickVideo,
                            child: Container(
                                width: 100,
                                height: 120,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!)
                                ),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        Icon(Icons.video_call_rounded, color: Theme.of(context).colorScheme.primary),
                                        const SizedBox(height: 4),
                                        Text("Add Video", style: GoogleFonts.outfit(fontSize: 12)),
                                        Text("(Max 15s)", style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey))
                                    ],
                                ),
                            ),
                        ),
                        // Picked Images
                        ...List.generate(_imageFiles.length, (index) {
                            final image = _imageFiles[index];
                            final isCover = index == 0;
                            return Stack(
                                children: [
                                    Container(
                                        width: 100,
                                        height: 120,
                                        margin: const EdgeInsets.only(right: 12),
                                        child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: kIsWeb 
                                              ? Image.network(image.path, fit: BoxFit.cover)
                                              : Image.file(File(image.path), fit: BoxFit.cover),
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
                                                    _imageFiles.removeAt(index);
                                                });
                                            },
                                            child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                                child: const Icon(Icons.close, color: Colors.white, size: 14)
                                            ),
                                        ),
                                    ),
                                    if (_isAnalyzing && index == 0) // Show spinner on first image if analyzing
                                        Positioned(
                                            left: 0, top: 0, right: 12, bottom: 0,
                                            child: const Center(child: CircularProgressIndicator())
                                        ),
                                ],
                            );
                        }),
                        // Picked Video
                        if (_videoFile != null)
                           Stack(
                                children: [
                                    Container(
                                        width: 100,
                                        height: 120,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                                const Icon(Icons.videocam_rounded, color: Colors.white, size: 32),
                                                const SizedBox(height: 8),
                                                Text("Video Selected", style: GoogleFonts.outfit(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                                            ],
                                        ),
                                    ),
                                    Positioned(
                                        top: 4,
                                        right: 16,
                                        child: GestureDetector(
                                            onTap: () {
                                                setState(() => _videoFile = null);
                                            },
                                            child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                                child: const Icon(Icons.close, color: Colors.white, size: 14)
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                    ],
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
                      Expanded(
                          child: Text('Category: $_selectedCategory > ${_selectedSubCategory ?? ""}', style: GoogleFonts.outfit(), overflow: TextOverflow.ellipsis),
                      ),
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
              maxLength: 50,
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                 FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 3,
                  style: GoogleFonts.outfit(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _depositController,
                  decoration: InputDecoration(
                    labelText: 'Deposit (RM)',
                    hintText: 'e.g. 50.00',
                    prefixText: 'RM ',
                    labelStyle: GoogleFonts.outfit(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                     FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
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
              maxLength: 1000,
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

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please provide a descriptive title', style: GoogleFonts.outfit())));
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a price', style: GoogleFonts.outfit())));
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a category', style: GoogleFonts.outfit())));
      return;
    }

    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please upload at least one image of the item', style: GoogleFonts.outfit())));
      return;
    }

    final double price = double.tryParse(_priceController.text) ?? 0.0;
    if (price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Price must be greater than 0', style: GoogleFonts.outfit())));
        return;
    }

    if (_listingType == 'Rent') {
        int maxDays = int.tryParse(_maxDurationController.text) ?? 0;
        if (maxDays < 1) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Max rental duration must be at least 1 day', style: GoogleFonts.outfit())));
            return;
        }
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ApiClient();
      
      // 1. Upload Images (Optimized for Performance: Concurrent Uploads)
      List<String> uploadedImageUrls = [];
      if (_imageFiles.isNotEmpty) {
          try {
              final uploadFutures = _imageFiles.map((img) => 
                  apiClient.postMultipart('/upload', img).catchError((e) => null)
              );
              final uploadResults = await Future.wait(uploadFutures);
              
              for (var res in uploadResults) {
                  if (res != null && res['url'] != null) {
                      uploadedImageUrls.add(res['url']);
                  }
              }
          } catch(e) {
              // Ignore partial failures
          }
      }

      // 2. Upload Video (if any)
      String? uploadedVideoUrl;
      if (_videoFile != null) {
          try {
              final uploadRes = await apiClient.postMultipart('/upload', _videoFile!);
              if (uploadRes['url'] != null) {
                  uploadedVideoUrl = uploadRes['url'];
              }
          } catch(e) {
              // print("Video upload failed: $e");
          }
      }

      final Map<String, dynamic> body = {
        'title': _titleController.text,
        'description': _descController.text,
        'category': _selectedCategory ?? 'Others',
        'sub_category_id': _selectedSubCategory ?? 'Others', // Use name as value for MVP if UUID not strictly required
        'condition': _selectedCondition, 
        'seller_id': session.userId,
        'type': _listingType,
        'image_urls': uploadedImageUrls,
        if (uploadedVideoUrl != null) 'video_url': uploadedVideoUrl,
      };

      if (_listingType == 'Sale') {
          body['price'] = double.tryParse(_priceController.text) ?? 0.0;
      } else {
          body['rental_price_per_day'] = double.tryParse(_priceController.text) ?? 0.0;
          body['max_rental_duration'] = int.tryParse(_maxDurationController.text) ?? 7;
          body['rental_deposit'] = double.tryParse(_depositController.text) ?? 0.0;
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
             _videoFile = null;
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
