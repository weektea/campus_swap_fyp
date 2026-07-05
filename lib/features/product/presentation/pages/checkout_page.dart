import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/features/profile/presentation/pages/transaction_detail_page.dart';
import 'package:campus_swap/features/location/domain/entities/safe_zone.dart';
import 'package:campus_swap/features/location/presentation/pages/safe_zone_map_page.dart';

class CheckoutPage extends StatefulWidget {
  final Product product;

  const CheckoutPage({super.key, required this.product});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  SafeZone _selectedZone = SafeZone.predefinedZones.first;
  double _buyerReputationScore = 5.0;

  @override
  void initState() {
    super.initState();
    _fetchZones();
    _fetchBuyerReputation();
  }

  Future<void> _fetchBuyerReputation() async {
    try {
      final session = UserSession();
      if (session.userId != null) {
        final apiClient = ApiClient();
        final res = await apiClient.get('/auth/user/${session.userId}');
        if (res != null && res['reputation_score'] != null && mounted) {
          setState(() {
            _buyerReputationScore = double.tryParse(res['reputation_score'].toString()) ?? 5.0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching buyer reputation in checkout: $e');
    }
  }

  Future<void> _fetchZones() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/zones');
      if (response is List) {
        final loadedZones = response
            .map((item) => SafeZone.fromJson(item as Map<String, dynamic>))
            .toList();
        if (loadedZones.isNotEmpty && mounted) {
          setState(() {
            _selectedZone = loadedZones.first;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching zones in checkout: $e');
    }
  }

  DateTime? _rentStartDate;
  DateTime? _rentEndDate;
  bool _isSubmitting = false;
  bool _isShared = false;
  final TextEditingController _coRenterUsernameController = TextEditingController();

  @override
  void dispose() {
    _coRenterUsernameController.dispose();
    super.dispose();
  }

  bool get _isRent => widget.product.type == 'Rent';

  int get _rentDays {
    if (_rentStartDate == null || _rentEndDate == null) return 0;
    return _rentEndDate!.difference(_rentStartDate!).inDays + 1;
  }

  double get _rentalSubtotal {
    return _rentDays > 0
        ? _rentDays * widget.product.rentalPricePerDay
        : widget.product.rentalPricePerDay;
  }

  double get _longTermDiscount {
    if (_isRent && _rentDays >= 30) {
      return _rentalSubtotal * 0.3; // 30% flat academic discount
    }
    return 0.0;
  }

  double get _discountedSubtotal => _rentalSubtotal - _longTermDiscount;

  bool get _isDepositWaived => _buyerReputationScore >= 4.8;

  double get _rentalDeposit => _isDepositWaived ? 0.0 : widget.product.rentalDeposit;

  double get _totalPrice {
    if (_isRent) {
      if (_isShared) {
        return (_discountedSubtotal / 2.0) + _rentalDeposit;
      }
      return _discountedSubtotal + _rentalDeposit;
    }
    return widget.product.price;
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final days = picked.end.difference(picked.start).inDays + 1;
      if (widget.product.maxRentalDuration > 0 && days > widget.product.maxRentalDuration) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Max rental is ${widget.product.maxRentalDuration} days'),
            backgroundColor: Colors.red,
          ));
        }
        return;
      }
      setState(() {
        _rentStartDate = picked.start;
        _rentEndDate = picked.end;
      });
    }
  }

  Future<void> _confirmOrder() async {
    if (_isRent && (_rentStartDate == null || _rentEndDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select rental dates'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_isRent && _isShared && _coRenterUsernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your friend's username for Shared Rental"), backgroundColor: Colors.red),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isRent ? 'Confirm Rental?' : 'Confirm Order?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'You are committing to ${_isRent ? 'rent' : 'purchase'} this item for RM ${_totalPrice.toStringAsFixed(2)} and meet up at ${_selectedZone.name}. Proceed?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirm', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _submitOrder();
    }
  }

  Future<void> _submitOrder() async {
    setState(() => _isSubmitting = true);
    try {
      final apiClient = ApiClient();
      final payload = {
        'buyer_id': UserSession().userId,
        'seller_id': widget.product.sellerId,
        'product_id': widget.product.id,
        'amount': _totalPrice,
        'meetup_location': _selectedZone.name,
      };

      if (_isRent && _rentStartDate != null && _rentEndDate != null) {
        payload['rental_start_date'] = _rentStartDate!.toIso8601String();
        payload['rental_end_date'] = _rentEndDate!.toIso8601String();
        if (_isShared && _coRenterUsernameController.text.trim().isNotEmpty) {
          payload['co_renter_username'] = _coRenterUsernameController.text.trim();
        }
      }

      final result = await apiClient.post('/transactions', payload);

      if (mounted) {
        // Navigate to transaction detail
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isRent ? 'Rental Request Sent! 🎉' : 'Order Placed! 🎉',
              style: GoogleFonts.outfit()),
          backgroundColor: Colors.green,
        ));
        // Pop checkout and push transaction detail
        Navigator.of(context).pop(); // pop checkout
        if (result is Map && result['id'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionDetailPage(transactionId: result['id'].toString()),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isRent ? 'Checkout — Rent' : 'Checkout',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product Card ──────────────────────────────────────
            _SectionCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.product.imageUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 72, height: 72,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 72, height: 72, color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 72, height: 72, color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.title,
                          style: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isRent
                              ? 'RM ${widget.product.rentalPricePerDay.toStringAsFixed(2)} / day'
                              : 'RM ${widget.product.price.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(
                            color: primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _isRent
                                ? Colors.blue.withValues(alpha: 0.1)
                                : primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _isRent ? 'For Rent' : 'For Sale',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isRent ? Colors.blue[700] : primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Select Safe Meetup Zone ───────────────────────────
            _SectionLabel(
              icon: Icons.location_on_rounded,
              iconColor: primary,
              label: 'Select Safe Meetup Zone',
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final result = await Navigator.push<SafeZone>(
                  context,
                  MaterialPageRoute(builder: (_) => SafeZoneMapPage(initialZone: _selectedZone)),
                );
                if (result != null) {
                  setState(() => _selectedZone = result);
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: _SectionCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(Icons.security_rounded, color: primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedZone.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('Tap to change on map', style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.map_rounded, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Rental Dates (Rent only) ──────────────────────────
            _SectionLabel(
              icon: Icons.calendar_month_rounded,
              iconColor: Colors.blue,
              label: _isRent ? 'Select Rental Dates' : 'Scheduled Meetup Date (Optional)',
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _isRent ? _pickDateRange : null,
              borderRadius: BorderRadius.circular(14),
              child: _SectionCard(
                child: Row(
                  children: [
                    Icon(Icons.date_range_rounded,
                        color: (_rentStartDate != null) ? primary : Colors.grey[400],
                        size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _rentStartDate != null && _rentEndDate != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_formatDate(_rentStartDate!)} → ${_formatDate(_rentEndDate!)}',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                                Text('$_rentDays day${_rentDays > 1 ? 's' : ''} selected',
                                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
                              ],
                            )
                          : Text(
                              _isRent ? 'Tap to select dates' : 'No date required for purchase',
                              style: GoogleFonts.outfit(color: Colors.grey[500]),
                            ),
                    ),
                    if (_isRent)
                      Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_isRent) ...[
              // ── Shared Rental Toggle ───────────────────────────────
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people_alt_outlined, color: primary, size: 22),
                            const SizedBox(width: 12),
                            Text(
                              'Shared Rental',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isShared,
                          activeColor: primary,
                          onChanged: (val) {
                            setState(() {
                              _isShared = val;
                            });
                          },
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _isShared
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Split bill cost sharing with a friend (50% rent split, full deposit retained).",
                                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _coRenterUsernameController,
                                    decoration: InputDecoration(
                                      labelText: "Enter Friend's Username",
                                      labelStyle: GoogleFonts.outfit(fontSize: 13),
                                      hintText: "e.g. ali_student",
                                      hintStyle: GoogleFonts.outfit(fontSize: 13),
                                      prefixIcon: const Icon(Icons.alternate_email, size: 16),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    style: GoogleFonts.outfit(fontSize: 14),
                                    onChanged: (text) {
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Rental deposit notice ─────────────────────────────
            if (_isRent && widget.product.rentalDeposit > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'A refundable deposit of RM ${widget.product.rentalDeposit.toStringAsFixed(2)} is required. It will be returned upon item return.',
                        style: GoogleFonts.outfit(fontSize: 13, color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Reservation notice ────────────────────────────────
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Item will be reserved upon confirmation to prevent overbooking.',
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.amber[900]),
                    ),
                  ),
                ],
              ),
            ),

            // ── Price Breakdown ───────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isRent) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isShared
                                ? Colors.purple.withValues(alpha: 0.1)
                                : (_rentDays >= 30
                                    ? Colors.orange.withValues(alpha: 0.1)
                                    : Colors.blue.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _isShared
                                ? 'Shared Bill Rental'
                                : (_rentDays >= 30 ? 'Long-Term Semester Rental' : 'Short-Term Rental'),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isShared
                                  ? Colors.purple[700]
                                  : (_rentDays >= 30 ? Colors.orange[800] : Colors.blue[700]),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _PriceRow(
                      label: 'Days Selected',
                      value: '$_rentDays day${_rentDays > 1 ? 's' : ''}',
                      isTotal: false,
                    ),
                    const Divider(height: 20),
                    _PriceRow(
                      label: 'Base Rental Subtotal',
                      value: 'RM ${_rentalSubtotal.toStringAsFixed(2)}',
                      isTotal: false,
                    ),
                    if (_rentDays >= 30) ...[
                      const Divider(height: 20),
                      _PriceRow(
                        label: 'Long-Term Discount (30%)',
                        value: '-RM ${_longTermDiscount.toStringAsFixed(2)}',
                        isTotal: false,
                        valueColor: Colors.green[700]!,
                      ),
                    ],
                    if (_isShared) ...[
                      const Divider(height: 20),
                      _PriceRow(
                        label: 'Cost Share Split (50%)',
                        value: '-RM ${(_discountedSubtotal / 2.0).toStringAsFixed(2)}',
                        isTotal: false,
                        valueColor: Colors.purple[700]!,
                      ),
                    ],
                    const Divider(height: 20),
                    if (_isDepositWaived) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Security Deposit',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'Deposit Waived (High Trust User)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'RM ${widget.product.rentalDeposit.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'RM 0.00',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ] else ...[
                      _PriceRow(
                        label: 'Security Deposit (Full)',
                        value: 'RM ${widget.product.rentalDeposit.toStringAsFixed(2)}',
                        isTotal: false,
                        valueColor: Colors.blue[700]!,
                      ),
                    ],
                  ] else ...[
                    _PriceRow(
                      label: 'Item Price',
                      value: 'RM ${widget.product.price.toStringAsFixed(2)}',
                      isTotal: false,
                    ),
                  ],
                  const Divider(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: _PriceRow(
                      key: ValueKey<String>('${_isShared}_$_totalPrice'),
                      label: _isShared ? 'Your Share (50% Payable)' : 'Total Payable Amount',
                      value: 'RM ${_totalPrice.toStringAsFixed(2)}',
                      isTotal: true,
                      valueColor: primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Confirm Button ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        _isRent ? 'Confirm Rental' : 'Confirm Order',
                        style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Section Card ─────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Section Label with icon ───────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _SectionLabel(
      {required this.icon, required this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

// ── Price Row ─────────────────────────────────────────────────────────────────
class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  const _PriceRow({
    super.key,
    required this.label,
    required this.value,
    required this.isTotal,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black87 : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? (isTotal ? theme.colorScheme.primary : Colors.black87),
          ),
        ),
      ],
    );
  }
}
