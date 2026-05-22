import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditListingPage extends StatefulWidget {
  final Product product;

  const EditListingPage({super.key, required this.product});

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  late String _listingType;
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _maxDurationController;
  late TextEditingController _depositController;
  late String _selectedCondition;
  late String _selectedStatus;

  final List<String> _conditions = ['New', 'Like New', 'Good', 'Fair', 'Poor'];
  final List<String> _statuses = ['Available', 'Reserved', 'Suspended']; // Removed Sold to prevent manual sold marking without transaction
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _listingType = widget.product.type;
    _titleController = TextEditingController(text: widget.product.title);
    
    double price = widget.product.type == 'Rent' ? widget.product.rentalPricePerDay : widget.product.price;
    _priceController = TextEditingController(text: price.toStringAsFixed(2));
    
    _descController = TextEditingController(text: widget.product.description);
    _maxDurationController = TextEditingController(text: widget.product.maxRentalDuration.toString());
    _depositController = TextEditingController(text: widget.product.rentalDeposit.toStringAsFixed(2));
    
    _selectedCondition = widget.product.condition;
    if (!_conditions.contains(_selectedCondition)) _selectedCondition = 'Good';

    _selectedStatus = widget.product.status;
    if (!_statuses.contains(_selectedStatus)) _selectedStatus = 'Available';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _maxDurationController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Listing', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Images (Read-only for now)
            if (widget.product.imageUrls.isNotEmpty)
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                      children: widget.product.imageUrls.map((url) => 
                          Container(
                              width: 100,
                              height: 120,
                              margin: const EdgeInsets.only(right: 12),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                      imageUrl: url, 
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                                      errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                                  ),
                              ),
                          )
                      ).toList(),
                  ),
              ),
            const SizedBox(height: 16),
            Text('Note: Image editing is coming in a future update.', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
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
            
            // Category (Read-only)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text('Category: ${widget.product.category}', style: GoogleFonts.outfit(color: Colors.grey[800]), overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(Icons.lock, size: 16, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 16),

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

             const SizedBox(height: 16),
             TextFormField(
              controller: _descController,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: GoogleFonts.outfit(),
                alignLabelWithHint: true,
              ),
              style: GoogleFonts.outfit(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _updateItem, 
              child: _isSubmitting 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : Text('Save Changes', style: GoogleFonts.outfit()),
            )
          ],
        ),
      ),
    );
  }

  void _updateItem() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please provide a descriptive title', style: GoogleFonts.outfit())));
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a price', style: GoogleFonts.outfit())));
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
      
      final Map<String, dynamic> body = {
        'title': _titleController.text,
        'description': _descController.text,
        'condition': _selectedCondition, 
        'type': _listingType,
      };

      if (_listingType == 'Sale') {
          body['price'] = double.tryParse(_priceController.text) ?? 0.0;
      } else {
          body['rental_price_per_day'] = double.tryParse(_priceController.text) ?? 0.0;
          body['max_rental_duration'] = int.tryParse(_maxDurationController.text) ?? 7;
          body['rental_deposit'] = double.tryParse(_depositController.text) ?? 0.0;
      }

      await apiClient.put('/products/${widget.product.id}', body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Listing Updated!', style: GoogleFonts.outfit())));
        Navigator.pop(context, true); // Return true to refresh caller
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
