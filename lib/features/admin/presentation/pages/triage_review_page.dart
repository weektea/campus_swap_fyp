import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TriageReviewPage extends StatelessWidget {
  const TriageReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            color: const Color(0xFFE8F5E9), // Light green
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: Color(0xFF2E7D32), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Ticket #REP-102 is currently locked by you.',
                  style: GoogleFonts.outfit(color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - Content Snapshot
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('Reported Content Snapshot', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(child: Text('Chair Image', style: GoogleFonts.outfit(color: Colors.grey[500]))),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Vintage Wooden Chair', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Text('Price: RM 45', style: GoogleFonts.outfit(color: Colors.grey[700])),
                                        const SizedBox(height: 4),
                                        Text('Seller: @student_seller', style: GoogleFonts.outfit(color: Colors.grey[700])),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Beautiful vintage wooden chair in excellent condition. Perfect for study or dining. Sturdy construction with minor wear consistent with age.',
                                style: GoogleFonts.outfit(color: Colors.grey[700], height: 1.5),
                              ),
                              const SizedBox(height: 32),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.outfit(color: Colors.black87, fontSize: 14, height: 1.5),
                                        children: const [
                                          TextSpan(text: "Reporter's Claim: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                          TextSpan(text: "Item is completely broken, not as described. Chair leg is cracked and unusable."),
                                        ]
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text('Evidence Photo: Broken\nChair Leg', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12)),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                // Right Column - Moderation Terminal
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Moderation Terminal', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 32),
                        Text('Select Violation Category', style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: 'Item Condition Misrepresented',
                              isExpanded: true,
                              items: ['Item Condition Misrepresented', 'Fake Item', 'Scam', 'Inappropriate Content']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.outfit())))
                                  .toList(),
                              onChanged: (_) {},
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Internal Mod Notes', style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        TextField(
                          maxLines: 8,
                          decoration: InputDecoration(
                            hintText: 'Document your findings and reasoning...',
                            hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ),
                            child: Text('Dismiss Report', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD32F2F), // Red
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ),
                            child: Text('Uphold & Suspend Listing', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
