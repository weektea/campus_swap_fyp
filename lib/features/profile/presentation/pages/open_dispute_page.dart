import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class OpenDisputePage extends StatefulWidget {
  final Map<String, dynamic> transaction;
  
  const OpenDisputePage({super.key, required this.transaction});

  @override
  State<OpenDisputePage> createState() => _OpenDisputePageState();
}

class _OpenDisputePageState extends State<OpenDisputePage> {
  final _detailsController = TextEditingController();
  String _selectedReason = 'Item not as described';
  final List<String> _reasons = [
    'Item not as described',
    'Damaged',
    'Not Received',
    'Fraud',
    'Other'
  ];
  
  bool _isLoading = false;
  
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _submitDispute() async {
    if (_detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide details of the issue.')),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one image as evidence.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final session = UserSession();
      List<String> evidenceUrls = [];
      if (_selectedImages.isNotEmpty) {
        final uploadFutures = _selectedImages.map((img) => ApiClient().postMultipart('/upload', img));
        final uploadResults = await Future.wait(uploadFutures);
        for (final res in uploadResults) {
          if (res != null && res['url'] != null) {
            evidenceUrls.add(res['url']);
          }
        }
      }

      final body = {
        'transaction_id': widget.transaction['id'],
        'complainant_id': session.userId,
        'reason': _selectedReason == 'Item not as described' ? 'Other' : _selectedReason,
        'description': _detailsController.text.trim(),
        'evidence_urls': evidenceUrls,
      };
      
      await ApiClient().post('/disputes', body);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispute submitted for moderation.')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryGreen = const Color(0xFF006940); // Standard green from UI
    
    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Open Dispute', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white : Colors.black87),
                      children: [
                        const TextSpan(text: 'Target: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: 'Order #${widget.transaction['id'].toString().substring(0, 8).toUpperCase()}'),
                      ]
                    )
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white : Colors.black87),
                      children: [
                        const TextSpan(text: 'Item: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: widget.transaction['product']?['title'] ?? 'Unknown Item'),
                      ]
                    )
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Reason Dropdown
            Text('Reason for Dispute', style: theme.textTheme.titleSmall?.copyWith(color: primaryGreen, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: primaryGreen),
                borderRadius: BorderRadius.circular(8),
                color: isDark ? Colors.grey[900] : Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  items: _reasons.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedReason = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Details
            Text('Details of the issue', style: theme.textTheme.titleSmall?.copyWith(color: primaryGreen, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Please explain what happened...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryGreen),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryGreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryGreen, width: 2),
                ),
                fillColor: isDark ? Colors.grey[900] : Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            
            // Upload Evidence
            const Text('Upload Evidence (Required)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryGreen,
                    style: BorderStyle.solid,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 36, color: primaryGreen),
                    const SizedBox(height: 8),
                    const Text('Tap to upload photos or screenshots of the item/chat', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedImages.isNotEmpty) ...[
              Text('Selected Evidence (${_selectedImages.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    final xfile = _selectedImages[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: primaryGreen),
                              image: DecorationImage(
                                image: kIsWeb ? NetworkImage(xfile.path) : FileImage(File(xfile.path)) as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 40),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitDispute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2C), // Blackish background
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Dispute for Moderation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
