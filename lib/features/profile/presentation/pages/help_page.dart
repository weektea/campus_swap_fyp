import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/features/profile/presentation/pages/submit_ticket_page.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Help & Support', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Frequently Asked Questions", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildFaqItem("How do I sell an item?", "Go to the Sell tab, take a photo, and our AI will help you list it."),
            _buildFaqItem("Is payment secure?", "Yes! We use an Escrow system. Money is held until you meet and confirm the item."),
            _buildFaqItem("Where should I meet?", "We recommend the Student Center or Library for safe public meetups."),
            _buildFaqItem("How is my Carbon Footprint calculated?", "We estimate the carbon saved (in kg CO2e) for every item you reuse instead of buying new, based on category settings configured by the administrator."),

            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitTicketPage()));
                }, 
                icon: const Icon(Icons.email_outlined),
                label: const Text("Contact Support"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(answer, style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey[700], height: 1.5)),
        ],
      ),
    );
  }
}
