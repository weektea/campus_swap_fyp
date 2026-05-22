import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DisputeArbitrationPage extends StatelessWidget {
  const DisputeArbitrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            color: const Color(0xFFFFF3E0), // Light orange
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_outlined, color: Color(0xFFE65100), size: 20),
                const SizedBox(width: 12),
                Text(
                  'ESCALATED DISPUTE: Requires Admin Final Arbitration',
                  style: GoogleFonts.outfit(color: const Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 16),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Moderator Notes
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MODERATOR NOTES', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1)),
                            const SizedBox(height: 16),
                            Text(
                              'Unable to verify item condition from provided evidence. Both parties have conflicting claims with supporting documentation. Escalating to Admin for final decision.',
                              style: GoogleFonts.outfit(fontSize: 15, color: Colors.black87, height: 1.5),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Dispute Timeline
                      Container(
                        width: double.infinity,
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
                              child: Text('Dispute Timeline', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTimelineItem('Oct 15, 2026 - 2:45 PM', 'Buyer initiated dispute', '"Received broken textbook with missing pages. Not as described."'),
                                  const SizedBox(height: 24),
                                  _buildTimelineItem('Oct 15, 2026 - 4:20 PM', 'Seller response', '"Book was in perfect condition when shipped. Provided photos from before shipping."'),
                                  const SizedBox(height: 32),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('CHAT LOGS', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1)),
                                        const SizedBox(height: 12),
                                        _buildChatLine('buyer', 'The book arrived damaged'),
                                        _buildChatLine('seller', 'I packaged it carefully with bubble wrap'),
                                        _buildChatLine('buyer', 'Pages 45-60 are completely torn out'),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Right Column
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Financial Resolution
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Financial Resolution', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1976D2), // Blue
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Column(
                                      children: [
                                        Text('Force Refund', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('(Buyer)', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF388E3C), // Green
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Column(
                                      children: [
                                        Text('Release Funds', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('(Seller)', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Punitive Actions
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFCDD2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Punitive Actions', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFC62828))),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.check_box_outline_blank, color: Colors.grey, size: 20),
                                const SizedBox(width: 12),
                                Text('Ban @student_seller', style: GoogleFonts.outfit(color: Colors.black87)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.check_box_outline_blank, color: Colors.grey, size: 20),
                                const SizedBox(width: 12),
                                Text('Ban @student_buyer', style: GoogleFonts.outfit(color: Colors.black87)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Execute Action
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB71C1C), // Dark Red
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Execute Admin Decision', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String date, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(date, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(description, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildChatLine(String user, String msg) {
    bool isBuyer = user == 'buyer';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.outfit(fontSize: 14),
          children: [
            TextSpan(
              text: '@$user: ',
              style: TextStyle(fontWeight: FontWeight.bold, color: isBuyer ? Colors.blue[700] : Colors.green[700]),
            ),
            TextSpan(
              text: msg,
              style: const TextStyle(color: Colors.black87),
            )
          ]
        ),
      ),
    );
  }
}
