import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/open_dispute_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/rate_experience_page.dart';
import 'package:image_picker/image_picker.dart';

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
  void initState() {
    super.initState();
    _fetchTransactionDetails();
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading details: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String newStatus, [Map<String, dynamic>? extraData]) async {
      if (_isUpdatingStatus) return;
      setState(() => _isUpdatingStatus = true);
      try {
          final apiClient = ApiClient();
          final Map<String, dynamic> body = {'status': newStatus};
          if (extraData != null) {
              body.addAll(extraData);
          }
          await apiClient.patch('/transactions/${widget.transactionId}/status', body);
          _fetchTransactionDetails(); // Refresh
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      } catch (e) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment proof uploaded successfully!')));
              }
          }
      } catch (e) {
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
          }
      } finally {
          setState(() => _isUploadingProof = false);
      }
  }

  Widget _buildStatusStepper(String status) {
      if (status == 'Cancelled' || status == 'Disputed') {
          return Center(child: Text('Transaction $status', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)));
      }
      
      final stages = ['Pending', 'Scheduled', 'To Confirm', 'Completed'];
      final labels = ['Pending', 'Scheduled', 'To Confirm', 'Done'];
      int currentIndex = stages.indexOf(status);
      if (currentIndex == -1) currentIndex = 0;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(stages.length, (index) {
             bool isPassed = currentIndex > index;
             bool isCurrent = currentIndex == index;
             Color nodeColor = isPassed || isCurrent ? Theme.of(context).colorScheme.primary : Colors.white;
             Color borderColor = isPassed || isCurrent ? Theme.of(context).colorScheme.primary : Colors.grey[300]!;

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
                               : Center(child: Text('${index + 1}', style: TextStyle(color: Colors.grey[400], fontSize: 12)))),
                     ),
                     if (index < stages.length - 1)
                       Container(
                         width: 2,
                         height: 32,
                         color: (currentIndex > index) ? Theme.of(context).colorScheme.primary : Colors.grey[300],
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
                         color: isPassed || isCurrent ? Colors.black87 : Colors.grey[600]
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
        title: Text('Order #...${widget.transactionId.substring(widget.transactionId.length - 6)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Stepper
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                    children: [
                        Text('Transaction Progress', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildStatusStepper(status),
                    ],
                )
            ),
            const SizedBox(height: 24),

            // Product Brief
            Text('Item Summary', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
               child: Row(
                   children: [
                       ClipRRect(
                           borderRadius: BorderRadius.circular(8),
                           child: productImg.isNotEmpty 
                             ? Image.network('${ApiClient.baseUrl.replaceAll('/api', '')}$productImg', width: 60, height: 60, fit: BoxFit.cover)
                             : Container(width: 60, height: 60, color: Colors.grey.shade200)
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                           child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                   Text(product['title'] ?? 'Unknown Item', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                                   Text('${product['type'] ?? 'Sale'} Request', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
                               ]
                           )
                       ),
                       Text('RM ${_transaction['amount']}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
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
                  child: Text(otherPartyName[0].toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
              ),
              title: Text(otherPartyName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              subtitle: Text('${otherParty['username'] != null ? '@${otherParty['username']} • ' : ''}${otherParty['email'] ?? ''}', style: GoogleFonts.outfit(fontSize: 12)),
              trailing: ElevatedButton.icon(
                  onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailPage(
                           sellerName: otherParty['username'] != null ? '@${otherParty['username']}' : 'Unknown User',
                           otherUserId: otherParty['id']?.toString() ?? ''
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
          ],
        ),
      ),
    );
  }

  Widget _buildActionPanel(String status, bool isBuying) {
      if (status == 'Cancelled' || status == 'Disputed') {
          return const SizedBox.shrink();
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
                              color: Colors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                          ),
                          child: Text('Waiting for seller to accept your request...', style: GoogleFonts.outfit(color: Colors.blue[800])),
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
                                          child: Text('Decline', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload payment proof image first!'), backgroundColor: Colors.red));
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
                              child: Text('Cancel Transaction', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                          onPressed: () => _updateStatus('Cancelled'),
                                          style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: Text('Decline & Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                                          child: Text('Verify & Complete', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
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
