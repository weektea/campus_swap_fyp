import 'package:flutter/material.dart';
import 'package:campus_swap/core/theme/app_theme.dart';

class OpenDisputeScreen extends StatefulWidget {
  const OpenDisputeScreen({super.key});

  @override
  State<OpenDisputeScreen> createState() => _OpenDisputeScreenState();
}

class _OpenDisputeScreenState extends State<OpenDisputeScreen> {
  String? _selectedReason = 'Item not as described';
  final List<String> _reasons = [
    'Item not as described',
    'Item damaged in transit',
    'Seller uncooperative',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Dispute'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C2C),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Submit Dispute for Moderation'),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Target: Order #TRX-9824', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  SizedBox(height: 4),
                  Text('Item: Calculus Textbook', style: TextStyle(color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Reason for Dispute Dropdown
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: InputDecoration(
                labelText: 'Reason for Dispute',
                labelStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              items: _reasons.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedReason = newValue;
                });
              },
            ),
            const SizedBox(height: 32),

            // Details of the issue
            TextField(
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Details of the issue',
                labelStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                alignLabelWithHint: true,
                hintText: 'Please explain what happened...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),

            // Upload Evidence
            const Text(
              'Upload Evidence (Required)',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor,
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryColor, size: 36),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap to upload photos or screenshots of\nthe item/chat',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  
                  // Mockup Thumbnail
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryColor),
                        ),
                        alignment: Alignment.center,
                        child: const Text('IMG', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
