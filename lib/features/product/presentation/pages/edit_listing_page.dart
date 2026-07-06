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
  
  final List<String> _paymentMethods = ['Cash', 'TNG', 'Bank Transfer'];
  late List<String> _selectedPaymentMethods;
  
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

    _selectedPaymentMethods = List<String>.from(widget.product.acceptedPaymentMethods);
    if (_selectedPaymentMethods.isEmpty) {
      _selectedPaymentMethods = ['Cash', 'TNG', 'Bank Transfer'];
    }
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
                                      placeholder: (context, url) => Container(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[200]),
                                      errorWidget: (context, url, error) => Container(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[200], child: const Icon(Icons.broken_image)),
                                  ),
                              ),
                          )
                      ).toList(),
                  ),
              ),
            const SizedBox(height: 16),
            Text('Note: Image editing is coming in a future update.', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
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
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.category, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text('Category: ${widget.product.category}', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                  ),
                  Icon(Icons.lock, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
            const SizedBox(height: 16),
            Text('Accepted Payment Methods', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ..._paymentMethods.map((method) {
                return CheckboxListTile(
                    title: Text(method, style: GoogleFonts.outfit(fontSize: 14)),
                    value: _selectedPaymentMethods.contains(method),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (bool? checked) {
                        setState(() {
                            if (checked == true) {
                                _selectedPaymentMethods.add(method);
                            } else {
                                if (_selectedPaymentMethods.length > 1) {
                                    _selectedPaymentMethods.remove(method);
                                } else {
                                    _showErrorSnackBar(context, 'At least one payment method must be accepted.');
                                }
                            }
                        });
                    },
                );
            }),
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

  void _updateItem() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar(context, 'Please provide a descriptive title');
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      _showErrorSnackBar(context, 'Please enter a price');
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
      
      final Map<String, dynamic> body = {
        'title': _titleController.text,
        'description': _descController.text,
        'condition': _selectedCondition, 
        'type': _listingType,
        'accepted_payment_methods': _selectedPaymentMethods,
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
        _showSuccessSnackBar(context, 'Listing Updated!');
        Navigator.pop(context, true); // Return true to refresh caller
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Update failed: ${_getFriendlyErrorMessage(e)}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
