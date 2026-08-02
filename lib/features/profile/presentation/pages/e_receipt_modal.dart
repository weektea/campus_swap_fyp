import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:campus_swap/core/session/user_session.dart';

class EReceiptModal extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const EReceiptModal({super.key, required this.transaction});

  static Future<void> show(BuildContext context, Map<String, dynamic> transaction) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EReceiptModal(transaction: transaction),
    );
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) {
      final now = DateTime.now();
      return "${now.day.toString().padLeft(2, '0')} ${_getMonthName(now.month)} ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    }
    try {
      final dt = DateTime.parse(dateVal.toString()).toLocal();
      return "${dt.day.toString().padLeft(2, '0')} ${_getMonthName(dt.month)} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return dateVal.toString();
    }
  }

  static String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1) % 12];
  }

  String _formatTxnId(dynamic rawId) {
    if (rawId == null) return "TXN-00000000";
    final idStr = rawId.toString().replaceAll('-', '').toUpperCase();
    if (idStr.length >= 8) {
      return "TXN-${idStr.substring(0, 8)}";
    }
    return "TXN-$idStr";
  }

  @override
  Widget build(BuildContext context) {
    final product = transaction['product'] ?? {};
    final buyer = transaction['buyer'] ?? {};
    final seller = transaction['seller'] ?? {};

    final bool isRent = product['type'] == 'Rent' || transaction['rental_start_date'] != null;
    final double totalPaid = double.tryParse(transaction['amount']?.toString() ?? transaction['total_payment']?.toString() ?? '0.0') ?? 0.0;
    final double depositAmount = double.tryParse(transaction['deposit_amount']?.toString() ?? '0.0') ?? 0.0;
    final double rentalFee = isRent 
        ? (double.tryParse(transaction['rental_fee']?.toString() ?? '') ?? (totalPaid > depositAmount ? totalPaid - depositAmount : totalPaid))
        : totalPaid;
    final double platformFee = double.tryParse(transaction['platform_fee']?.toString() ?? '') ?? (rentalFee * 0.02);
    final double ownerNetEarnings = rentalFee - platformFee;
    final bool isBuying = transaction['buyer_id']?.toString() == UserSession().userId?.toString();

    final String buyerName = buyer['full_name'] ?? buyer['username'] ?? 'Campus Buyer';
    final String buyerUsername = buyer['username'] != null ? '@${buyer['username']}' : '@buyer';
    final String sellerName = seller['full_name'] ?? seller['username'] ?? 'Campus Seller';
    final String sellerUsername = seller['username'] != null ? '@${seller['username']}' : '@seller';

    final String itemName = product['title'] ?? 'Campus Item';
    final String meetupZone = transaction['meetup_location'] ?? product['location'] ?? 'FCI Library Entrance';
    final String paymentMethod = transaction['selected_payment_method'] ?? 'Cash / E-Wallet';
    final String completedDate = _formatDate(transaction['completed_at'] ?? transaction['createdAt']);
    final String txnId = _formatTxnId(transaction['id']);

    final double carbonSaved = double.tryParse(transaction['awarded_carbon_points']?.toString() ?? '2.5') ?? 2.5;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar with Drag Handle and Close Button
            Container(
              color: const Color(0xFF005A43),
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Campus Swap E-Receipt",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable Receipt Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Receipt Header Block
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFA5D6A7)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  (transaction['status'] ?? 'COMPLETED').toString().toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2E7D32),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            txnId,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Completed: $completedDate",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    _buildDottedDivider(),
                    const SizedBox(height: 16),

                    // Section 1: User Details (Buyer & Seller)
                    Text(
                      "TRANSACTION PARTIES",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shopping_bag_outlined, color: Color(0xFF0284C7), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text("Buyer", style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600)),
                              ),
                              Text(
                                buyerName,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "($buyerUsername)",
                                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF0284C7), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(height: 1, thickness: 0.5),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.storefront_outlined, color: Color(0xFF16A34A), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text("Seller", style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600)),
                              ),
                              Text(
                                sellerName,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "($sellerUsername)",
                                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF16A34A), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Section 2: Item & Fulfillment Details
                    Text(
                      "ITEM & FULFILLMENT",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildRowItem("Item Name", itemName, isBold: true),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Meetup Zone",
                          style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shield_outlined, size: 14, color: Color(0xD9770600)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      meetupZone,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFB45309),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    _buildDottedDivider(),
                    const SizedBox(height: 16),

                    // Section 3: Payment Summary
                    Text(
                      "PAYMENT SUMMARY",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isRent) ...[
                      _buildRowItem("Rental Fee", "RM ${rentalFee.toStringAsFixed(2)}"),
                      const SizedBox(height: 8),
                      _buildRowItem("Deposit (Refundable)", "RM ${depositAmount.toStringAsFixed(2)}", isSecondary: true),
                      const SizedBox(height: 8),
                      _buildRowItem("Platform Fee (2% of Rental Fee)", "- RM ${platformFee.toStringAsFixed(2)}", isSecondary: true),
                      const SizedBox(height: 8),
                      _buildRowItem("Payment Method", paymentMethod, isBadge: true),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(height: 1, thickness: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isBuying ? "Total Upfront Paid (Cash/TNG)" : "Owner Net Earnings",
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            isBuying
                                ? "RM ${totalPaid.toStringAsFixed(2)}"
                                : "RM ${ownerNetEarnings.toStringAsFixed(2)}",
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF005A43),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildRowItem("Item Price", "RM ${rentalFee.toStringAsFixed(2)}"),
                      const SizedBox(height: 8),
                      if (!isBuying) ...[
                        _buildRowItem("Platform Fee (2%)", "- RM ${platformFee.toStringAsFixed(2)}", isSecondary: true),
                        const SizedBox(height: 8),
                      ],
                      _buildRowItem("Payment Method", paymentMethod, isBadge: true),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(height: 1, thickness: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isBuying ? "Total Paid" : "Net Earnings",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            isBuying
                                ? "RM ${totalPaid.toStringAsFixed(2)}"
                                : "RM ${ownerNetEarnings.toStringAsFixed(2)}",
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF005A43),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Section 4: ESG Sustainability Highlight Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF81C784), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.eco, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ESG Carbon Metric",
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1B5E20),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Carbon Saved: ${carbonSaved.toStringAsFixed(1)} kg CO₂e",
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Thank you for promoting sustainable campus reuse!",
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: const Color(0xFF388E3C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Visual Barcode Aesthetic Stub
                    Center(
                      child: Column(
                        children: [
                          Container(
                            height: 36,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(24, (index) {
                                final widths = [1.0, 2.0, 3.0, 1.5, 4.0];
                                final w = widths[index % widths.length];
                                return Container(
                                  width: w,
                                  color: Colors.grey.shade800,
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "* CS-VERIFIED-RECEIPT-$txnId *",
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // ignore: deprecated_member_use
                              Share.share(
                                "Campus Swap E-Receipt\n"
                                "Txn ID: $txnId\n"
                                "Item: $itemName\n"
                                "Total Paid: RM ${totalPaid.toStringAsFixed(2)}\n"
                                "Carbon Saved: ${carbonSaved.toStringAsFixed(1)} kg CO2e\n"
                                "Meetup Zone: $meetupZone",
                              );
                            },
                            icon: const Icon(Icons.share, size: 18),
                            label: Text("Share Receipt", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF005A43),
                              side: const BorderSide(color: Color(0xFF005A43)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005A43),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text("Done", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowItem(String label, String value, {bool isBold = false, bool isSecondary = false, bool isBadge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: isSecondary ? Colors.grey.shade600 : Colors.grey.shade700,
            fontStyle: isSecondary ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0284C7),
              ),
            ),
          )
        else
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
      ],
    );
  }

  Widget _buildDottedDivider() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade300),
              ),
            );
          }),
        );
      },
    );
  }
}
