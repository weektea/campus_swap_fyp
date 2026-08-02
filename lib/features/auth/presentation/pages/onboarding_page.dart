import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/home/presentation/pages/home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentStep = 1; // 1: Intent, 2: Preferences
  String _selectedIntent = 'buy';
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;
  bool _isLoadingOptions = true;

  final List<Map<String, String>> _intents = [
    {
      'id': 'buy',
      'emoji': '🛍️',
      'title': "I'm looking to buy",
      'subtitle': 'Discover great deals on textbooks, electronics, & dorm items',
    },
    {
      'id': 'rent',
      'emoji': '🔑',
      'title': 'I want to rent items',
      'subtitle': 'Short-term & semester rentals for gadgets, tools & books',
    },
    {
      'id': 'sell',
      'emoji': '📦',
      'title': 'I want to sell items',
      'subtitle': 'Declutter your room and earn extra cash from verified peers',
    },
    {
      'id': 'browse',
      'emoji': '👀',
      'title': 'Just browsing around',
      'subtitle': 'Explore campus market trends & eco-friendly swaps',
    },
  ];

  // Flat sub-categories list fetched dynamically from backend DB
  final List<Map<String, String>> _subcategories = [];

  // Fallback sub-categories if network/offline
  final List<Map<String, String>> _defaultSubcategories = [
    {'name': 'Audio', 'icon': '🎧'},
    {'name': 'Laptops', 'icon': '💻'},
    {'name': 'PC Accessories', 'icon': '⌨️'},
    {'name': 'Smartphones', 'icon': '📱'},
    {'name': 'Tablets', 'icon': '📲'},
    {'name': 'Bags & Luggage', 'icon': '🎒'},
    {'name': 'Clothing', 'icon': '👕'},
    {'name': 'Fashion Accessories', 'icon': '🕶️'},
    {'name': 'Shoes', 'icon': '👟'},
    {'name': 'Appliances', 'icon': '🔌'},
    {'name': 'Chairs', 'icon': '🪑'},
    {'name': 'Sofas', 'icon': '🛋️'},
    {'name': 'Storage', 'icon': '📦'},
    {'name': 'Tables & Desks', 'icon': '🖥️'},
    {'name': 'Books', 'icon': '📚'},
    {'name': 'Calculators', 'icon': '🧮'},
    {'name': 'Notes & Past Papers', 'icon': '📝'},
    {'name': 'Apparel', 'icon': '🎽'},
    {'name': 'Bicycles', 'icon': '🚲'},
    {'name': 'Equipment', 'icon': '⚽'},
    {'name': 'Art Supplies', 'icon': '🎨'},
    {'name': 'Paper', 'icon': '📄'},
    {'name': 'Writing', 'icon': '✏️'},
    {'name': 'Cosmetics & Beauty', 'icon': '💄'},
    {'name': 'Drinkware', 'icon': '🥤'},
    {'name': 'Miscellaneous', 'icon': '🏷️'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchOnboardingOptions();
  }

  Future<void> _fetchOnboardingOptions() async {
    try {
      final response = await ApiClient().get('/onboarding/options');
      if (mounted && response != null) {
        if (response['intents'] != null) {
          final List dynamicIntents = response['intents'];
          _intents.clear();
          for (var item in dynamicIntents) {
            _intents.add({
              'id': item['id'].toString(),
              'emoji': item['emoji'].toString(),
              'title': item['title'].toString(),
              'subtitle': item['subtitle'].toString(),
            });
          }
        }
        final List? dynamicSubs = response['subcategories'] ?? response['categories'];
        if (dynamicSubs != null && dynamicSubs.isNotEmpty) {
          _subcategories.clear();
          for (var item in dynamicSubs) {
            _subcategories.add({
              'id': item['id']?.toString() ?? '',
              'name': item['name'].toString(),
              'icon': item['icon']?.toString() ?? '🏷️',
              'category_name': item['category_name']?.toString() ?? '',
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Using default onboarding options fallback: $e");
    } finally {
      if (mounted) {
        if (_subcategories.isEmpty) {
          _subcategories.addAll(_defaultSubcategories);
        }
        setState(() {
          _isLoadingOptions = false;
        });
      }
    }
  }

  /// Edge Case 1: Skip Action with Backend Sync
  Future<void> _skipOnboarding() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Fire API call to mark user as onboarded on backend with empty preferences
      await ApiClient().post('/onboarding/preferences', {
        'primary_intent': _selectedIntent,
        'preference_tags': [],
      });
    } catch (e) {
      debugPrint("Skip onboarding backend sync error: $e");
    } finally {
      if (mounted) {
        // Sync local session & persist to storage
        final session = UserSession();
        session.isOnboarded = true;
        session.primaryIntent = _selectedIntent;
        session.preferenceTags = [];
        await session.saveToStorage();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        }
      }
    }
  }

  /// Edge Case 2 & 3: Save Action with Local Session Sync & Zero-Selection Handling
  Future<void> _submitOnboarding() async {
    // If 0 tags selected, treat as Skip action
    if (_selectedTags.isEmpty) {
      return _skipOnboarding();
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await ApiClient().post('/onboarding/preferences', {
        'primary_intent': _selectedIntent,
        'preference_tags': _selectedTags,
      });

      if (mounted) {
        // Edge Case 2: Set session.isOnboarded = true locally & persist to storage before routing
        final session = UserSession();
        session.isOnboarded = true;
        session.primaryIntent = _selectedIntent;
        session.preferenceTags = List<String>.from(_selectedTags);

        if (response != null && response['user'] != null) {
          final u = response['user'];
          session.primaryIntent = u['primary_intent'] ?? _selectedIntent;
          session.preferenceTags = List<String>.from(u['preference_tags'] ?? _selectedTags);
        }
        await session.saveToStorage();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete onboarding: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF005A43).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF005A43), size: 24),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                "Campus Swap",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "Step $_currentStep of 2",
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF005A43)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSubmitting ? null : _skipOnboarding,
              child: Text(
                "Skip",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingOptions
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF005A43)))
            : Column(
                children: [
                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: LinearProgressIndicator(
                      value: _currentStep / 2.0,
                      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      color: const Color(0xFF005A43),
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 6,
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _currentStep == 1 ? _buildStep1Intent(isDark) : _buildStep2Preferences(isDark),
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                      ],
                    ),
                    child: SafeArea(
                      child: _currentStep == 1
                          ? ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _currentStep = 2;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF005A43),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                              ),
                              child: Text(
                                "Next: Select Interests",
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitOnboarding,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF005A43),
                                disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : Text(
                                      _selectedTags.isNotEmpty ? "Complete & Start Swapping" : "Skip & Continue",
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStep1Intent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What brings you to Campus Swap?",
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        Text(
          "Select your main goal so our Recommendation Engine can customize your feed.",
          style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
        const SizedBox(height: 28),

        ..._intents.map((item) {
          final isSelected = _selectedIntent == item['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedIntent = item['id']!;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF005A43).withValues(alpha: 0.2) : const Color(0xFFE6F4F1))
                      : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF005A43) : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: const Color(0xFF005A43).withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))]
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Text(item['emoji']!, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? const Color(0xFF005A43)
                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['subtitle']!,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? const Color(0xFF005A43) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF005A43) : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                          width: 2,
                        ),
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep2Preferences(bool isDark) {
    final count = _selectedTags.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "What categories interest you?",
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                });
              },
              icon: const Icon(Icons.arrow_back, size: 20),
              tooltip: "Back to Step 1",
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Our Machine Learning recommendation engine uses these tags to personalize your 'For You' feed from day 1.",
          style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
        const SizedBox(height: 16),

        // Counter Banner Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: count > 0
                ? (isDark ? const Color(0xFF14532D).withValues(alpha: 0.3) : const Color(0xFFDCFCE7))
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: count > 0
                  ? (isDark ? const Color(0xFF166534) : const Color(0xFFBBF7D0))
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Icon(
                count > 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: count > 0 ? const Color(0xFF15803D) : const Color(0xFF64748B),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  count > 0
                      ? "Great job! Selected $count sub-categories."
                      : "Tap any sub-categories below to personalize your feed (or tap Skip).",
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: count > 0
                        ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D))
                        : (isDark ? Colors.grey.shade300 : const Color(0xFF475569)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Giant Fluid Tag Cloud (No Parent Category Headers)
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: _subcategories.map((subCat) {
            final name = subCat['name']!;
            final icon = subCat['icon'] ?? '🏷️';
            final isSelected = _selectedTags.contains(name);

            return FilterChip(
              avatar: Text(icon, style: const TextStyle(fontSize: 15)),
              label: Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey.shade300 : const Color(0xFF334155)),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (!_selectedTags.contains(name)) {
                      _selectedTags.add(name);
                    }
                  } else {
                    _selectedTags.remove(name);
                  }
                });
              },
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              selectedColor: const Color(0xFF005A43),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF005A43)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                width: isSelected ? 1.5 : 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: isSelected ? 2 : 0,
            );
          }).toList(),
        ),
      ],
    );
  }
}
