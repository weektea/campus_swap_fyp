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
  String _content = '';
  String _version = '';
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchTerms();
  }

  Future<void> _fetchTerms() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final res = await _apiClient.get('/policies/TERMS');
      if (res != null && res['content'] != null) {
        setState(() {
          _content = res['content'];
          _version = res['version'] ?? '1.0.0';
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching terms: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  List<Widget> _renderContent(String content) {
    if (content.trim().isEmpty) return [];
    
    final lines = content.split('\n');
    return lines.map((line) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        return Padding(
          padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
          child: Text(
            trimmed.substring(2),
            style: GoogleFonts.outfit(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: const Color(0xFF006940)
            ),
          ),
        );
      } else if (trimmed.startsWith('## ')) {
        return Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 6.0),
          child: Text(
            trimmed.substring(3),
            style: GoogleFonts.outfit(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: Colors.black87
            ),
          ),
        );
      } else if (trimmed.startsWith('### ')) {
        return Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
          child: Text(
            trimmed.substring(4),
            style: GoogleFonts.outfit(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: Colors.black87
            ),
          ),
        );
      } else if (trimmed.isEmpty) {
        return const SizedBox(height: 10);
      } else {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            line,
            style: GoogleFonts.outfit(
              fontSize: 15, 
              color: Colors.grey[800], 
              height: 1.5
            ),
          ),
        );
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Terms & Guidelines', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                          "Failed to load Policy Guidelines",
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
                          onPressed: _fetchTerms,
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
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Version info header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Version: $_version",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.grey[800]
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Parsed Markdown elements
                      ..._renderContent(_content),
                    ],
                  ),
                ),
    );
  }
}
