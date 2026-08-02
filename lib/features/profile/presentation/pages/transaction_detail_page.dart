import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/open_dispute_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/rate_experience_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/e_receipt_modal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:campus_swap/core/services/socket_service.dart';
import 'package:campus_swap/features/product/presentation/pages/product_details_page.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';

class TransactionDetailPage extends StatefulWidget {
  final String transactionId;

  const TransactionDetailPage({super.key, required this.transactionId});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  bool _isLoading = true;
  dynamic _transaction;
  final session = UserSession();
  String? _uploadedProofUrl;
  bool _isUploadingProof = false;
  bool _isUpdatingStatus = false;

  @override
  void dispose() {
    SocketService().socket?.off('transaction_status_updated');
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchTransactionDetails();

    // Listen for WebSocket status updates dynamically
    SocketService().socket?.on('transaction_status_updated', (data) {
      if (mounted && data != null) {
        final txId = data['transaction_id']?.toString() ?? data['id']?.toString();
        if (txId == widget.transactionId.toString()) {
          _fetchTransactionDetailsSilently();
        }
      }
    });
  }

  Future<void> _fetchTransactionDetailsSilently() async {
    try {
      final apiClient = ApiClient();
      final res = await apiClient.get('/transactions/${widget.transactionId}');
      if (mounted) {
        setState(() {
          _transaction = res;
        });
      }
    } catch (e) {
      // Silently ignore background failures
    }
  }

  Future<void> _fetchTransactionDetails() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      final res = await apiClient.get('/transactions/${widget.transactionId}');
      if (mounted) {
        setState(() {
          _transaction = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading details: ${_getFriendlyErrorMessage(e)}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
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

  Future<void> _updateStatus(String newStatus, [Map<String, dynamic>? extraData, bool skipConfirm = false]) async {
      if (_isUpdatingStatus) return;

      // Destructive Confirmation Dialog for Cancelled or Disputed status
      if (!skipConfirm && (newStatus == 'Cancelled' || newStatus == 'Disputed')) {
          final title = newStatus == 'Cancelled' ? 'Cancel Transaction?' : 'Dispute Transaction?';
          final message = newStatus == 'Cancelled' 
              ? 'Are you sure you want to cancel this transaction? This action is irreversible.'
              : 'Are you sure you want to open a dispute for this transaction? Support staff will review this request.';
          
          final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                  title: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  content: Text(message),
                  actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Go Back'),
                      ),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(newStatus == 'Cancelled' ? 'Cancel Order' : 'Open Dispute', style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
                      ),
                  ],
              ),
          );
          if (confirm != true) return;
      }

      setState(() => _isUpdatingStatus = true);
      try {
          final apiClient = ApiClient();
          final Map<String, dynamic> body = {'status': newStatus};
          if (extraData != null) {
              body.addAll(extraData);
          }
          final res = await apiClient.patch('/transactions/${widget.transactionId}/status', body);
          _fetchTransactionDetails(); // Refresh
          final msg = (res != null && res['message'] != null) ? res['message'].toString() : 'Status updated to $newStatus';
          if(mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
      } catch (e) {
          if(mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed: ${_getFriendlyErrorMessage(e)}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
      } finally {
          if (mounted) {
              setState(() => _isUpdatingStatus = false);
          }
      }
  }

  Future<void> _pickAndUploadProof() async {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploadingProof = true);
      try {
          final apiClient = ApiClient();
          final uploadRes = await apiClient.postMultipart('/upload', image);
          if (uploadRes != null && uploadRes['url'] != null) {
              setState(() {
                  _uploadedProofUrl = uploadRes['url'];
              });
              if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Payment proof uploaded successfully!'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              }
          }
      } catch (e) {
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Upload failed: ${_getFriendlyErrorMessage(e)}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
      } finally {
          setState(() => _isUploadingProof = false);
      }
  }

  Widget _buildStatusStepper(String status) {
      if (status == 'Cancelled' || status == 'Disputed') {
          return Center(child: Text('Transaction $status', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)));
      }
      
      final product = _transaction['product'] ?? {};
      final isRent = product['type'] == 'Rent';
      final stages = isRent 
          ? ['Pending', 'Scheduled', 'To Confirm', 'On Rent', 'Completed'] 
          : ['Pending', 'Scheduled', 'To Confirm', 'Completed'];
      final labels = isRent 
          ? ['Pending', 'Scheduled', 'To Confirm', 'On Rent', 'Done'] 
          : ['Pending', 'Scheduled', 'To Confirm', 'Done'];

      int currentIndex = stages.indexOf(status);
      if (currentIndex == -1) currentIndex = 0;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(stages.length, (index) {
             bool isPassed = currentIndex > index;
             bool isCurrent = currentIndex == index;
             Color nodeColor = isPassed || isCurrent ? Theme.of(context).colorScheme.primary : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white);
             Color borderColor = isPassed || isCurrent ? Theme.of(context).colorScheme.primary : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.outlineVariant : Colors.grey[300]!);

             return Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Column(
                   children: [
                     Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                           color: nodeColor,
                           shape: BoxShape.circle,
                           border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: isPassed 
                           ? const Icon(Icons.check, size: 16, color: Colors.white) 
                           : (isCurrent 
                               ? const Icon(Icons.check, size: 16, color: Colors.white) 
                               : Center(child: Text('${index + 1}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)))),
                     ),
                     if (index < stages.length - 1)
                       Container(
                         width: 2,
                         height: 32,
                         color: (currentIndex > index) ? Theme.of(context).colorScheme.primary : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.outlineVariant : Colors.grey[300]),
                       )
                   ],
                 ),
                 const SizedBox(width: 16),
                 Padding(
                   padding: const EdgeInsets.only(top: 4.0),
                   child: Text(
                      labels[index], 
                      style: GoogleFonts.outfit(
                         fontSize: 15, 
                         fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                         color: isPassed || isCurrent ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant
                      )
                   ),
                 )
               ],
             );
          }),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Order Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_transaction == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Order Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
        body: Center(child: Text('Transaction not found', style: GoogleFonts.outfit())),
      );
    }

    final product = _transaction['product'] ?? {};
    final bool isBuying = _transaction['buyer_id'] == session.userId;
    final otherParty = isBuying ? _transaction['seller'] : _transaction['buyer'];
    final status = _transaction['status'];
    final productImg = product['image_urls'] != null && (product['image_urls'] as List).isNotEmpty ? product['image_urls'][0] : '';
    final String otherPartyName = otherParty['full_name'] ?? (otherParty['username'] != null ? '@${otherParty['username']}' : 'Unknown User');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          status == 'Pending' 
              ? 'Offer #...${widget.transactionId.substring(widget.transactionId.length - 6)}' 
              : 'Order #...${widget.transactionId.substring(widget.transactionId.length - 6)}', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Stepper
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface, 
                    borderRadius: BorderRadius.circular(16), 
                    boxShadow: Theme.of(context).brightness == Brightness.dark 
                        ? [] 
                        : [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                    children: [
                        Text('Transaction Progress', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildStatusStepper(status),
                    ],
                )
            ),
            const SizedBox(height: 24),

            // Order/Offer Summary
            Text(status == 'Pending' ? 'Offer Summary' : 'Order Summary', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface, 
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.outlineVariant : Colors.grey.shade200)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Text('Meetup Location:', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                Text(_transaction['meetup_location'] ?? 'Not specified', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Text('Payment Method:', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                Text(_transaction['selected_payment_method'] ?? 'Cash', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.teal)),
                            ],
                        ),
                        if (_transaction['rental_start_date'] != null || _transaction['product']?['type'] == 'Rent') ...[
                            const SizedBox(height: 8),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                    Text('Deposit Status:', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                    _buildDepositBadge(_transaction['deposit_status']?.toString() ?? 'Held'),
                                ],
                            ),
                        ],
                        const Divider(height: 24),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Text('Item Price:', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                Text('RM ${(_transaction['item_price'] ?? _transaction['amount']).toString()}', style: GoogleFonts.outfit()),
                            ],
                        ),
                        if (isBuying) ...[
                            const SizedBox(height: 8),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                    Text('Total Paid by Buyer:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                    Text(
                                        'RM ${(_transaction['item_price'] ?? _transaction['amount']).toString()}',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 16)
                                    ),
                                ],
                            ),
                        ] else ...[
                            const SizedBox(height: 8),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                    Row(
                                        children: [
                                            Text('Platform Service Fee (2%):', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                                onTap: () {
                                                    showDialog(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                            title: Row(
                                                                children: [
                                                                    Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                                                                    const SizedBox(width: 8),
                                                                    Text('Platform Service Fee', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                                                                ],
                                                            ),
                                                            content: Text('A 2% fee to support platform servers and campus green initiatives.', style: GoogleFonts.outfit(fontSize: 14)),
                                                            actions: [
                                                                TextButton(
                                                                    onPressed: () => Navigator.pop(context),
                                                                    child: Text('Got it', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                                                ),
                                                            ],
                                                        ),
                                                    );
                                                },
                                                child: Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                                            ),
                                        ],
                                    ),
                                    Text(
                                        '- RM ${(_transaction['platform_fee'] ?? (double.parse((_transaction['item_price'] ?? _transaction['amount']).toString()) * 0.02).toStringAsFixed(2)).toString()}',
                                        style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w600)
                                    ),
                                ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                    Text('Your Net Earnings:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                    Text(
                                        'RM ${(_transaction['seller_net_earnings'] ?? (double.parse((_transaction['item_price'] ?? _transaction['amount']).toString()) * 0.98).toStringAsFixed(2)).toString()}',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 16)
                                    ),
                                ],
                            ),
                        ],
                        if (status == 'Completed') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => EReceiptModal.show(context, _transaction),
                              icon: const Icon(Icons.receipt_long),
                              label: Text('View Campus Swap E-Receipt', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF005A43),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                    ],
                )
            ),
            const SizedBox(height: 24),

            // Product Brief
            Text('Item Summary', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                   color: Theme.of(context).colorScheme.surface, 
                   borderRadius: BorderRadius.circular(12), 
                   border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.outlineVariant : Colors.grey.shade200)),
               child: Row(
                   children: [
                       ClipRRect(
                           borderRadius: BorderRadius.circular(8),
                           child: productImg.isNotEmpty 
                             ? Image.network('${ApiClient.baseUrl.replaceAll('/api', '')}$productImg', width: 60, height: 60, fit: BoxFit.cover)
                             : Container(width: 60, height: 60, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey.shade200)
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                           child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                   Text(product['title'] ?? 'Unknown Item', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                                   Text('${product['type'] ?? 'Sale'} Request', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                               ]
                           )
                       ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                                Text('RM ${_transaction['amount']}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
                                if (double.tryParse(_transaction['amount'].toString()) != null &&
                                    product['price'] != null &&
                                    double.tryParse(_transaction['amount'].toString()) != double.tryParse(product['price'].toString())) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                            'Offer Price',
                                            style: GoogleFonts.outfit(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                    ),
                                ],
                            ],
                        ),
                    ]
                )
             ),
            const SizedBox(height: 24),

            // Party Info & Chat
            Text(isBuying ? 'Seller Info' : 'Buyer Info', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  backgroundImage: otherParty['profile_image_url'] != null
                      ? NetworkImage('${ApiClient.baseUrl.replaceAll('/api', '')}${otherParty['profile_image_url']}')
                      : null,
                  child: otherParty['profile_image_url'] == null
                      ? Text(otherPartyName[0].toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))
                      : null,
              ),
              title: Text(otherPartyName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              subtitle: Text('${otherParty['username'] != null ? '@${otherParty['username']} • ' : ''}${otherParty['email'] ?? ''}', style: GoogleFonts.outfit(fontSize: 12)),
              trailing: ElevatedButton.icon(
                  onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailPage(
                            sellerName: otherParty['username'] != null ? '@${otherParty['username']}' : 'Unknown User',
                            otherUserId: otherParty['id']?.toString() ?? '',
                            otherUserAvatar: otherParty['profile_image_url']?.toString(),
                        )));
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 24),

            // Actions Based on Status
            Text('Actions Required', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildActionPanel(status, isBuying),
            const SizedBox(height: 24),
            if (status != 'Cancelled' && status != 'Disputed')
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => OpenDisputePage(
                        transaction: _transaction
                      )
                    ));
                    if (result == true) {
                      _fetchTransactionDetails(); // refresh if dispute opened
                    }
                  },
                  icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  label: Text('Report Issue / Open Dispute', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
            
            if (status == 'Completed') ...[
              const SizedBox(height: 24),
              Text('Transaction Feedback', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.outlineVariant : Colors.grey.shade200),
                ),
                child: () {
                  final isPublished = _transaction['review_status'] == 'PUBLISHED';
                  final rating = isBuying 
                      ? _transaction['rating_from_seller'] 
                      : _transaction['rating_from_buyer'];
                  final comment = isBuying 
                      ? _transaction['seller_comment'] 
                      : _transaction['buyer_comment'];

                  if (isPublished) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Feedback from $otherPartyName',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                            Row(
                              children: List.generate(5, (starIndex) {
                                final int starVal = rating is num ? rating.toInt() : 5;
                                return Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: starIndex < starVal ? Colors.amber : (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade300),
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          comment ?? 'No comment provided.',
                          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock_outline, size: 18, color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Feedback Locked',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Waiting for the counterparty to submit their review to unlock feedback.',
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
                        ),
                      ],
                    );
                  }
                }(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionPanel(String status, bool isBuying) {
      if (status == 'Cancelled') {
          final currentUserId = UserSession().userId?.toString();
          final cancelledById = _transaction['cancelled_by_id']?.toString();
          final buyerId = _transaction['buyer_id']?.toString();
          final cancellationReason = _transaction['cancellation_reason']?.toString();

          String cancelText = 'This request has been cancelled.';
          if (cancelledById != null && currentUserId != null) {
              if (cancelledById == currentUserId) {
                  cancelText = 'You have cancelled/declined this request.';
              } else if (cancelledById == buyerId) {
                  cancelText = 'The buyer has cancelled this request.';
              } else {
                  cancelText = 'The seller has declined this request.';
              }
          } else {
              cancelText = 'This transaction has been cancelled.';
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cancel_outlined, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cancelText,
                            style: GoogleFonts.outfit(color: Colors.red[800], fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (cancellationReason != null && cancellationReason.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Reason: $cancellationReason',
                                style: GoogleFonts.outfit(color: Colors.red[900], fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isBuying && _transaction['product_id'] != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                  onPressed: () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => const Center(child: CircularProgressIndicator()),
                      );
                      try {
                        final apiClient = ApiClient();
                        final res = await apiClient.get('/products/${_transaction['product_id']}');
                        if (mounted) {
                          navigator.pop(); // close loader
                          final product = Product.fromJson(res);
                          navigator.push(MaterialPageRoute(
                            builder: (_) => ProductDetailsPage(product: product)
                          ));
                        }
                      } catch (e) {
                        if (mounted) {
                          navigator.pop(); // close loader
                          messenger.showSnackBar(SnackBar(
                            content: Text('Failed to load item: $e'),
                            backgroundColor: Colors.red,
                          ));
                        }
                      }
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: Text('Adjust Offer & Resubmit', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          );
      }

      if (status == 'Disputed') {
          return const SizedBox.shrink();
      }

      if (status == 'On Rent') {
          if (isBuying) {
              return Column(
                  children: [
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                              'You are currently renting this item. Once you return the item to the seller, the seller will confirm the return to refund your deposit.', 
                              style: GoogleFonts.outfit(color: Colors.blue[800])
                          ),
                      ),
                  ],
              );
          } else {
              return Column(
                  children: [
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                              'Item is currently rented. Once the buyer has safely returned the item, confirm item return to release/refund the security deposit.', 
                              style: GoogleFonts.outfit(color: Colors.amber[800])
                          ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                              onPressed: _confirmReturnRentalAndRefundDeposit,
                              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              label: Text('Confirm Item Return & Refund Deposit', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                              onPressed: _confirmClaimRentalDeposit,
                              icon: const Icon(Icons.broken_image_outlined, color: Colors.red),
                              label: Text('Report Damage & Claim Deposit', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                          ),
                      ),
                  ],
              );
          }
      }

      if (status == 'Completed') {
          final isBuyer = isBuying;
          final hasRated = isBuyer 
              ? _transaction['rating_from_buyer'] != null 
              : _transaction['rating_from_seller'] != null;

          if (hasRated) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2))
                ),
                child: Text('You have already submitted a review for this transaction. Thank you!', style: GoogleFonts.outfit(color: Colors.green[800], fontWeight: FontWeight.w600))
              );
          } else {
              final product = _transaction['product'] ?? {};
              final otherParty = isBuying ? _transaction['seller'] : _transaction['buyer'];
              final String otherPartyName = otherParty != null ? (otherParty['username'] != null ? '@${otherParty['username']}' : 'Unknown User') : 'Unknown User';

              return Column(
                  children: [
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2))
                          ),
                          child: Text('Order completed! Please rate your experience with the other student.', style: GoogleFonts.outfit())
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                              onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => RateExperiencePage(
                                          transactionId: _transaction['id'].toString(),
                                          revieweeId: otherParty['id']?.toString() ?? '',
                                          isSeller: !isBuying,
                                          revieweeName: otherPartyName,
                                          productName: product['title'] ?? 'Item',
                                          onSubmitted: () {
                                              _fetchTransactionDetails();
                                          },
                                      )
                                  ));
                              },
                              icon: const Icon(Icons.star_rate_rounded, color: Colors.white),
                              label: Text('Rate Experience', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D503C), // Matching RateExperiencePage button
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                          ),
                      ),
                  ],
              );
          }
      }

      if (status == 'Pending') {
          if (isBuying) {
              return Column(
                  children: [
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.2)),
                          ),
                          child: Text('Waiting for seller to accept your request...', style: GoogleFonts.outfit(color: Theme.of(context).brightness == Brightness.dark ? Colors.blue[200] : Colors.blue[800])),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                              onPressed: () => _updateStatus('Cancelled'),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Cancel Request', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                      ),
                  ],
              );
          } else {
              return Column(
                  children: [
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                          ),
                          child: Text('You have received a new request. Please accept or decline the transaction.', style: GoogleFonts.outfit(color: Colors.amber[800])),
                      ),
                      const SizedBox(height: 16),
                      Row(
                          children: [
                              Expanded(
                                  child: SizedBox(
                                      height: 48,
                                      child: OutlinedButton(
                                          onPressed: () => _showDeclineReasonModal(context, isDecline: true),
                                          style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: Text('Decline Request', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                      ),
                                  ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                          onPressed: () => _updateStatus('Scheduled'),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context).colorScheme.primary,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: Text('Accept Request', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                  ),
                              ),
                          ],
                      ),
                  ],
              );
          }
      }

      if (status == 'Scheduled') {
          final String paymentMethod = _transaction['selected_payment_method']?.toString() ?? 'Cash';
          final bool isCash = paymentMethod == 'Cash';
          final String proofTitle = isCash ? "Upload Handover Proof (Item Photo)" : "Upload Payment Receipt";
          final String proofHelper = isCash 
              ? "Please take a photo of the received item at the meetup zone to confirm successful handover." 
              : "Please upload a screenshot of your successful transfer.";
          final String proofHint = isCash ? "Click to upload handover photo" : "Click to upload payment receipt";
          final IconData proofIcon = isCash ? Icons.camera_alt_outlined : Icons.upload_file_outlined;

          if (isBuying) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      isCash 
                          ? 'Please take a photo of the received item at the meetup zone to confirm handover (Optional).'
                          : 'Please upload payment receipt to proceed to the next step.',
                      style: GoogleFonts.outfit(color: Colors.blue[800]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(proofTitle, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(proofHelper, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _isUploadingProof ? null : _pickAndUploadProof,
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      child: _isUploadingProof
                          ? const Center(child: CircularProgressIndicator())
                          : _uploadedProofUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    '${ApiClient.baseUrl.replaceAll('/api', '')}$_uploadedProofUrl',
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(proofIcon, color: Colors.grey[600], size: 32),
                                    const SizedBox(height: 8),
                                    Text(proofHint, style: GoogleFonts.outfit(color: Colors.grey[600])),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                          if (!isCash && _uploadedProofUrl == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Please upload a screenshot of your successful transfer first!'),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                          }
                          final extra = _uploadedProofUrl != null ? {'payment_proof_url': _uploadedProofUrl} : null;
                          _updateStatus('To Confirm', extra);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: Text(
                        isCash ? 'Confirm Handover & Proceed' : 'Submit Payment Receipt', 
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _updateStatus('Cancelled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: Text('Cancel Order', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              );
          } else {
              return Column(
                  children: [
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                              isCash 
                                  ? 'Cash Payment Selected: Meet up at the scheduled zone. Once cash is received, click "Confirm Cash Received & Complete".'
                                  : 'Waiting for buyer to upload payment receipt...', 
                              style: GoogleFonts.outfit(color: Colors.blue[800])
                          ),
                      ),
                      const SizedBox(height: 16),
                      if (isCash) ...[
                          SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                  onPressed: () => _updateStatus('Completed'),
                                  icon: const Icon(Icons.payments_outlined, color: Colors.white),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  label: Text('Confirm Cash Received & Complete', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                          ),
                          const SizedBox(height: 12),
                      ],
                      SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                              onPressed: () => _showDeclineReasonModal(context, isDecline: false),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Cancel Order', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                      ),
                  ],
              );
          }
      }

      if (status == 'To Confirm') {
          final String paymentMethod = _transaction['selected_payment_method']?.toString() ?? 'Cash';
          final bool isCash = paymentMethod == 'Cash';

          if (isBuying) {
              return Column(
                  children: [
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                              isCash 
                                  ? 'Handover proof submitted. Waiting for seller to confirm cash receipt and complete...'
                                  : 'Waiting for seller to verify your payment receipt and complete the order...', 
                              style: GoogleFonts.outfit(color: Colors.blue[800])
                          ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                              onPressed: () => _updateStatus('Cancelled'),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Cancel Order', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                      ),
                  ],
              );
          } else {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                              isCash 
                                  ? 'Buyer has submitted handover proof. Please verify cash received and confirm completion.'
                                  : 'Buyer has submitted payment receipt. Please verify transfer and confirm completion.', 
                              style: GoogleFonts.outfit(color: Colors.amber[800])
                          ),
                      ),
                      const SizedBox(height: 16),
                      if (_transaction['payment_proof_url'] != null) ...[
                          Text(isCash ? 'Uploaded Handover Photo (Item Photo):' : 'Uploaded Payment Receipt:', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                  '${ApiClient.baseUrl.replaceAll('/api', '')}${_transaction['payment_proof_url']}',
                                  width: double.infinity,
                                  height: 220,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                  ),
                              ),
                          ),
                          const SizedBox(height: 24),
                      ],
                      Row(
                          children: [
                              Expanded(
                                  child: SizedBox(
                                      height: 48,
                                      child: OutlinedButton(
                                          onPressed: () => _updateStatus('Disputed'),
                                          style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: Text('Report Issue / Dispute', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                  ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                          onPressed: () => _updateStatus('Completed'),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context).colorScheme.primary,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: Text(
                                              isCash ? 'Confirm Cash & Complete' : 'Confirm & Complete', 
                                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)
                                          ),
                                      ),
                                  ),
                              ),
                          ],
                      ),
                  ],
              );
          }
      }

      return const SizedBox.shrink();
  }

  Widget _buildDepositBadge(String status) {
    Color bg = Colors.amber.withValues(alpha: 0.1);
    Color fg = Colors.amber[900]!;
    String text = 'Held';

    if (status == 'Waived') {
      bg = Colors.blue.withValues(alpha: 0.1);
      fg = Colors.blue[800]!;
      text = 'Waived (High Trust)';
    } else if (status == 'Refunded') {
      bg = Colors.green.withValues(alpha: 0.1);
      fg = Colors.green[800]!;
      text = 'Refunded';
    } else if (status == 'Claimed_Forfeited') {
      bg = Colors.red.withValues(alpha: 0.1);
      fg = Colors.red[800]!;
      text = 'Claimed / Forfeited';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Future<void> _confirmReturnRentalAndRefundDeposit() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Return & Refund Deposit', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure the rental item has been returned safely and in good condition? This will mark deposit as Refunded and complete the order.',
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
            child: Text('Confirm Return', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final apiClient = ApiClient();
        await apiClient.post('/transactions/${widget.transactionId}/return-rental', {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Rental item marked as returned! Deposit status: Refunded.', style: GoogleFonts.outfit()),
            backgroundColor: Colors.green,
          ));
          _fetchTransactionDetails();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to process return: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  Future<void> _confirmClaimRentalDeposit() async {
    final TextEditingController reasonController = TextEditingController();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Report Damage & Claim Deposit', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Describe the damage or reason for claiming the security deposit:', style: GoogleFonts.outfit(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Item returned damaged or unreturned...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              style: GoogleFonts.outfit(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Claim Deposit', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final apiClient = ApiClient();
        await apiClient.post('/transactions/${widget.transactionId}/claim-deposit', {
          'reason': reasonController.text.trim(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Deposit claim recorded and dispute initiated for moderator review.', style: GoogleFonts.outfit()),
            backgroundColor: Colors.amber[900],
          ));
          _fetchTransactionDetails();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to claim deposit: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  Future<void> _showDeclineReasonModal(BuildContext context, {bool isDecline = true}) async {
    String selectedPreset = 'Price offered is too low';
    final List<String> presets = [
      'Price offered is too low',
      'Meetup location or schedule is unsuitable',
      'Item is no longer available',
      'Other reason'
    ];
    final noteController = TextEditingController();

    final String? finalReason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDecline ? 'Decline Request Reason' : 'Cancel Order Reason',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please select or enter a reason to inform the other party:',
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  ...presets.map((preset) => RadioListTile<String>(
                    title: Text(preset, style: GoogleFonts.outfit(fontSize: 14)),
                    value: preset,
                    groupValue: selectedPreset,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedPreset = val);
                    },
                  )),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Additional notes (optional)...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    style: GoogleFonts.outfit(fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        String reason = selectedPreset;
                        if (noteController.text.trim().isNotEmpty) {
                          reason += " - ${noteController.text.trim()}";
                        }
                        Navigator.pop(ctx, reason);
                      },
                      child: Text(
                        isDecline ? 'Confirm Decline' : 'Confirm Cancel',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (finalReason != null && finalReason.isNotEmpty) {
      _updateStatus('Cancelled', {'cancellation_reason': finalReason}, true);
    }
  }
}
