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

  Future<void> _updateStatus(String newStatus, [Map<String, dynamic>? extraData]) async {
      if (_isUpdatingStatus) return;

      // Destructive Confirmation Dialog for Cancelled or Disputed status
      if (newStatus == 'Cancelled' || newStatus == 'Disputed') {
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
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
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

          String cancelText = 'This request has been cancelled.';
          if (cancelledById != null && currentUserId != null) {
              if (cancelledById == currentUserId) {
                  cancelText = 'You have cancelled/declined this request.';
              } else if (cancelledById == buyerId) {
                  cancelText = 'The buyer has cancelled this request. No further action can be taken.';
              } else {
                  cancelText = 'The seller has declined this request. No further action can be taken.';
              }
          } else {
              cancelText = 'This transaction has been cancelled. No further action can be taken.';
          }

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cancelText,
                    style: GoogleFonts.outfit(color: Colors.red[800], fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
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
                              'Item is currently rented. Once the buyer has safely returned the item, click "Confirm Safe Return" to release the security deposit and complete the transaction.', 
                              style: GoogleFonts.outfit(color: Colors.amber[800])
                          ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                              onPressed: () => _updateStatus('Completed'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Confirm Safe Return & Complete', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                              onPressed: () async {
                                  final result = await Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => OpenDisputePage(
                                          transaction: _transaction,
                                          prefilledCategory: 'Rental Damage',
                                      )
                                  ));
                                  if (result == true) {
                                      _fetchTransactionDetails();
                                  }
                              },
                              icon: const Icon(Icons.broken_image_outlined, color: Colors.red),
                              label: Text('Report Damage (Open Dispute)', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
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
                                          onPressed: () => _updateStatus('Cancelled'),
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
                      'Please upload payment proof to proceed to the next step.',
                      style: GoogleFonts.outfit(color: Colors.blue[800]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Upload Payment Proof', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                    Icon(Icons.upload_file_outlined, color: Colors.grey[600], size: 32),
                                    const SizedBox(height: 8),
                                    Text('Click to upload payment proof', style: GoogleFonts.outfit(color: Colors.grey[600])),
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
                          if (_uploadedProofUrl == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Please upload payment proof image first!'),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                          }
                          _updateStatus('To Confirm', {'payment_proof_url': _uploadedProofUrl});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: Text('Submit Proof', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
                          child: Text('Waiting for buyer to upload payment/meetup proof...', style: GoogleFonts.outfit(color: Colors.blue[800])),
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
          }
      }

      if (status == 'To Confirm') {
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
                          child: Text('Waiting for seller to verify your payment/meetup proof and complete the order...', style: GoogleFonts.outfit(color: Colors.blue[800])),
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
                          child: Text('Buyer has submitted payment/meetup proof. Please verify and confirm completion.', style: GoogleFonts.outfit(color: Colors.amber[800])),
                      ),
                      const SizedBox(height: 16),
                      if (_transaction['payment_proof_url'] != null) ...[
                          Text('Uploaded Payment Proof:', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
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
                                          child: Text('Report Issue / Dispute Payment', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
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
                                          child: Text('Confirm & Complete', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
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
}
