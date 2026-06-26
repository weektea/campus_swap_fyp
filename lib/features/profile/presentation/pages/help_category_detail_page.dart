import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/features/profile/presentation/pages/submit_ticket_page.dart';

class HelpFaqItem {
  final String question;
  final String answer;
  HelpFaqItem({required this.question, required this.answer});
}

class HelpCategoryDetailPage extends StatefulWidget {
  final String categoryName;
  final String introduction;
  final List<HelpFaqItem> faqs;

  const HelpCategoryDetailPage({
    super.key,
    required this.categoryName,
    required this.introduction,
    required this.faqs,
  });

  @override
  State<HelpCategoryDetailPage> createState() => _HelpCategoryDetailPageState();
}

class _HelpCategoryDetailPageState extends State<HelpCategoryDetailPage> {
  final TextEditingController _searchController = TextEditingController();
  List<HelpFaqItem> _filteredFaqs = [];

  @override
  void initState() {
    super.initState();
    _filteredFaqs = widget.faqs;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFaqs = widget.faqs.where((faq) {
        return faq.question.toLowerCase().contains(query) ||
               faq.answer.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryGreen = const Color(0xFF006940);
    final accentGreen = const Color(0xFF0D503C);

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: Text(widget.categoryName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Introduction Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen, accentGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.categoryName.contains('Order') 
                            ? Icons.shopping_bag_rounded 
                            : Icons.account_circle_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'About ${widget.categoryName}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.introduction,
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: primaryGreen),
                  hintText: 'Search for questions...',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[500]),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Q&A List Header
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Q&A Expandable Items
            _filteredFaqs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No matches found.',
                        style: GoogleFonts.outfit(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final item = _filteredFaqs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            iconColor: primaryGreen,
                            collapsedIconColor: Colors.grey,
                            title: Text(
                              item.question,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Text(
                                  item.answer,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 32),

            // Need More Help Footer
            Center(
              child: Column(
                children: [
                  Text(
                    "Still need help?",
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SubmitTicketPage()),
                      );
                    },
                    icon: const Icon(Icons.headset_mic_rounded, color: Colors.white),
                    label: Text(
                      'Contact Support',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
