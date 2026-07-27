import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReputationBadge extends StatelessWidget {
  final int completedTransactionsCount;
  final double score;
  final String? customLevel;

  const ReputationBadge({
    super.key,
    required this.completedTransactionsCount,
    required this.score,
    this.customLevel,
  });

  factory ReputationBadge.fromUser(Map<String, dynamic> userData) {
    final int count = int.tryParse(
      (userData['completed_transactions_count'] ??
              userData['successful_transactions_count'] ??
              userData['total_reviews'] ??
              0)
          .toString(),
    ) ?? 0;
    final double score = double.tryParse((userData['reputation_score'] ?? 5.0).toString()) ?? 5.0;
    final String? level = userData['reputation_level']?.toString();

    return ReputationBadge(
      completedTransactionsCount: count,
      score: score,
      customLevel: level,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String label;
    Color bgColor;
    Color borderColor;
    Color textColor;

    // Minimum 1 Transaction Rule
    if (completedTransactionsCount == 0) {
      label = "🌱 New Member";
      bgColor = isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9);
      borderColor = isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1);
      textColor = isDark ? Colors.grey.shade300 : const Color(0xFF475569);
    } else if (score >= 4.5) {
      label = customLevel ?? "🏆 Exemplary Trader";
      bgColor = isDark ? const Color(0xFF14532D).withValues(alpha: 0.3) : const Color(0xFFDCFCE7);
      borderColor = isDark ? const Color(0xFF166534) : const Color(0xFFBBF7D0);
      textColor = isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);
    } else if (score >= 3.0) {
      label = customLevel ?? "⭐ Average Trader";
      bgColor = isDark ? const Color(0xFF713F12).withValues(alpha: 0.3) : const Color(0xFFFEF9C3);
      borderColor = isDark ? const Color(0xFF854D0E) : const Color(0xFFFEF08A);
      textColor = isDark ? const Color(0xFFFDE047) : const Color(0xFFA16207);
    } else {
      label = customLevel ?? "⛔ Poor Rating";
      bgColor = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEE2E2);
      borderColor = isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA);
      textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
