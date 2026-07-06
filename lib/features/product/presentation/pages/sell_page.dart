import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
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

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _maxDurationController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  final List<XFile> _imageFiles = [];
  XFile? _videoFile;
  final ImagePicker _picker = ImagePicker();

  static const int _maxImages = 9;

  Map<String, List<String>> _categoriesMap = {};
  
  final List<String> _paymentMethods = ['Cash', 'TNG', 'Bank Transfer'];
  List<String> _selectedPaymentMethods = ['Cash', 'TNG', 'Bank Transfer'];

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
        _showErrorSnackBar(context, 'Maximum $_maxImages images allowed.');
        return;
    }

    final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        imageQuality: 80
    );
    
    if (images.isNotEmpty) {
        final remainingSlots = _maxImages - _imageFiles.length;
        final imagesToAdd = images.take(remainingSlots).toList();
        
        if (images.length > remainingSlots) {
             if (mounted) {
               _showErrorSnackBar(context, 'Only added first $remainingSlots images. Max $_maxImages allowed.');
             }
        }

        setState(() {
            _imageFiles.addAll(imagesToAdd);
            if (_imageFiles.length == imagesToAdd.length && _selectedCategory == null) {
                _analyzeImage(_imageFiles.first);
            }
        });
    }
  }

  Future<void> _pickVideo() async {
    if (_videoFile != null) {
        _showErrorSnackBar(context, 'Only 1 video allowed. Remove existing to change.');
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
            final theme = Theme.of(context);
            final categories = _categoriesMap.keys.toList();
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              height: MediaQuery.of(context).size.height * 0.5,
              child: SingleChildScrollView(
                 child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Select Category',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: categories.map((c) => ChoiceChip(
                         label: Text(c, style: theme.textTheme.bodyMedium),
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
                        Text(
                          '2. Select Sub-Category',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _categoriesMap[_selectedCategory!]!.map((sub) => ChoiceChip(
                             label: Text(
                               sub,
                               style: theme.textTheme.bodyMedium?.copyWith(
                                 color: _selectedSubCategory == sub
                                     ? theme.colorScheme.onPrimary
                                     : theme.colorScheme.onSurface,
                               ),
                             ),
                             selected: _selectedSubCategory == sub,
                             selectedColor: theme.colorScheme.primary,
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
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category first')));
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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Price Suggested!')));
          }
      } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get suggestion: $e')));
      }
  }

  void _generateDescription() async {
     if (_titleController.text.isEmpty || _selectedCategory == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter title and select category')));
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Listing',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
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
                                    color: theme.colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: theme.colorScheme.outlineVariant)
                                ),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        Icon(Icons.add_a_photo_rounded, color: theme.colorScheme.primary),
                                        const SizedBox(height: 4),
                                        Text("Add Photos", style: theme.textTheme.bodySmall),
                                        Text(
                                          "(Max $_maxImages)",
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        )
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
                                    color: theme.colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: theme.colorScheme.outlineVariant)
                                ),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        Icon(Icons.video_call_rounded, color: theme.colorScheme.primary),
                                        const SizedBox(height: 4),
                                        Text("Add Video", style: theme.textTheme.bodySmall),
                                        Text(
                                          "(Max 15s)",
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        )
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
                                            color: theme.colorScheme.primaryContainer,
                                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                          ),
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Text(
                                            "Cover",
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.onPrimaryContainer,
                                            ),
                                          ),
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
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.scrim.withValues(alpha: 0.54),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(Icons.close, color: theme.colorScheme.onInverseSurface, size: 14)
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
                                            color: theme.colorScheme.surfaceContainer,
                                            borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                                Icon(Icons.videocam_rounded, color: theme.colorScheme.onSurfaceVariant, size: 32),
                                                const SizedBox(height: 8),
                                                Text(
                                                  "Video Selected",
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
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
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.scrim.withValues(alpha: 0.54),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(Icons.close, color: theme.colorScheme.onInverseSurface, size: 14)
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                            'Category: $_selectedCategory > ${_selectedSubCategory ?? ""}',
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ),
                      TextButton(
                          onPressed: _showCategoryPicker, 
                          child: const Text('Edit')
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c, style: theme.textTheme.bodyMedium))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCondition = val);
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Calculus Textbook',
              ),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
             TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: _listingType == 'Sale' ? 'Price (RM)' : 'Rental Price (RM / Day)',
                prefixText: 'RM ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                 FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              style: theme.textTheme.bodyMedium,
            ),

            if (_listingType == 'Rent') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxDurationController,
                  decoration: const InputDecoration(
                    labelText: 'Max Duration (Days)',
                    hintText: 'e.g. 7',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 3,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _depositController,
                  decoration: const InputDecoration(
                    labelText: 'Deposit (RM)',
                    hintText: 'e.g. 50.00',
                    prefixText: 'RM ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                     FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: theme.textTheme.bodyMedium,
                ),
            ],

             const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _fetchPriceSuggestion,
                  icon: const Icon(Icons.analytics_outlined, size: 16),
                  label: const Text('Get Price Suggestion'),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Accepted Payment Methods',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._paymentMethods.map((method) {
                  return CheckboxListTile(
                      title: Text(method, style: theme.textTheme.bodyMedium),
                      value: _selectedPaymentMethods.contains(method),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (bool? checked) {
                          setState(() {
                              if (checked == true) {
                                  _selectedPaymentMethods.add(method);
                              } else {
                                  if (_selectedPaymentMethods.length > 1) {
                                      _selectedPaymentMethods.remove(method);
                                  } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least one payment method must be accepted.')));
                                  }
                              }
                          });
                      },
                  );
              }),

             const SizedBox(height: 16),
             TextFormField(
              controller: _descController,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.auto_fix_high),
                  tooltip: 'Generate Description',
                  onPressed: _generateDescription,
                )
              ),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _postItem, 
              child: _isSubmitting 
                  ? SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2)
                    )
                  : const Text('Post Item'),
            )
          ],
        ),
      ),
    );
  }

  bool _isSubmitting = false;

  void _showErrorSnackBar(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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

  void _postItem() async {
    final session = UserSession();
    if (!session.isLoggedIn) {
        _showErrorSnackBar(context, 'Please login to post items');
        return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar(context, 'Please provide a descriptive title');
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      _showErrorSnackBar(context, 'Please enter a price');
      return;
    }

    if (_selectedCategory == null) {
      _showErrorSnackBar(context, 'Please select a category');
      return;
    }

    if (_imageFiles.isEmpty) {
      _showErrorSnackBar(context, 'Please upload at least one image of the item');
      return;
    }

    final double price = double.tryParse(_priceController.text) ?? 0.0;
    if (price <= 0) {
        _showErrorSnackBar(context, 'Price must be greater than 0');
        return;
    }

    if (_listingType == 'Rent') {
        int maxDays = int.tryParse(_maxDurationController.text) ?? 0;
        if (maxDays < 1) {
            _showErrorSnackBar(context, 'Max rental duration must be at least 1 day');
            return;
        }
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ApiClient();
      
      // 1. Upload Images (Concurrent Uploads)
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
        'sub_category_id': _selectedSubCategory ?? 'Others', 
        'condition': _selectedCondition, 
        'seller_id': session.userId,
        'type': _listingType,
        'image_urls': uploadedImageUrls,
        'accepted_payment_methods': _selectedPaymentMethods,
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
        _showSuccessSnackBar(context, 'Item posted successfully!');
        // Reset form or nav back
        _titleController.clear();
        _priceController.clear();
        _descController.clear();
        setState(() {
             _imageFiles.clear();
              _videoFile = null;
              _selectedCategory = null;
              _selectedCondition = 'Good';
              _selectedPaymentMethods = ['Cash', 'TNG', 'Bank Transfer'];
         });
       }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Post failed: ${_getFriendlyErrorMessage(e)}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
