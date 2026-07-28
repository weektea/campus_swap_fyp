import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/core/api/api_client.dart';

class TermsGuidelinesPage extends StatefulWidget {
  const TermsGuidelinesPage({super.key});

  @override
  State<TermsGuidelinesPage> createState() => _TermsGuidelinesPageState();
}

class _TermsGuidelinesPageState extends State<TermsGuidelinesPage> {
  final ApiClient _apiClient = ApiClient();
  
  String _termsContent = '';
  String _privacyContent = '';
  String _guidelinesContent = '';
  
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchAllPolicies();
  }

  Future<void> _fetchAllPolicies() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final results = await Future.wait([
        _apiClient.get('/policies/TERMS'),
        _apiClient.get('/policies/PRIVACY'),
        _apiClient.get('/policies/COMMUNITY_RULES'),
      ]);

      if (mounted) {
        setState(() {
          _termsContent = results[0]?['content'] ?? '';
          _privacyContent = results[1]?['content'] ?? '';
          _guidelinesContent = results[2]?['content'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching all policies: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  List<Widget> _renderMarkdown(String content) {
    if (content.trim().isEmpty) return [];
    
    final lines = content.split('\n');
    return lines.map((line) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        return Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            trimmed.substring(2),
            style: GoogleFonts.outfit(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: const Color(0xFF006940)
            ),
          ),
        );
      } else if (trimmed.startsWith('## ')) {
        return Padding(
          padding: const EdgeInsets.only(top: 14.0, bottom: 6.0),
          child: Text(
            trimmed.substring(3),
            style: GoogleFonts.outfit(
              fontSize: 17, 
              fontWeight: FontWeight.bold, 
              color: Colors.black87
            ),
          ),
        );
      } else if (trimmed.startsWith('### ')) {
        return Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
          child: Text(
            trimmed.substring(4),
            style: GoogleFonts.outfit(
              fontSize: 15, 
              fontWeight: FontWeight.bold, 
              color: Colors.black87
            ),
          ),
        );
      } else if (trimmed.isEmpty) {
        return const SizedBox(height: 8);
      } else {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Text(
            line,
            style: GoogleFonts.outfit(
              fontSize: 14, 
              color: Colors.grey[800], 
              height: 1.5
            ),
          ),
        );
      }
    }).toList();
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF006940).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF006940).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF006940), size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF006940),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms & Conditions', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          "Failed to load Terms & Conditions",
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Please verify your network connection and try again.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchAllPolicies,
                          icon: const Icon(Icons.refresh),
                          label: Text("Retry", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006940),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Terms of Service
                      _buildSectionTitle('Terms of Service', Icons.gavel_rounded),
                      ..._renderMarkdown(_termsContent.isNotEmpty ? _termsContent : 'No terms content available.'),

                      // Section 2: Privacy Policy
                      _buildSectionTitle('Privacy Policy', Icons.security_rounded),
                      ..._renderMarkdown(_privacyContent.isNotEmpty ? _privacyContent : 'No privacy content available.'),

                      // Section 3: Community Guidelines
                      _buildSectionTitle('Community Guidelines', Icons.verified_user_rounded),
                      ..._renderMarkdown(_guidelinesContent.isNotEmpty ? _guidelinesContent : 'No community rules available.'),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}
