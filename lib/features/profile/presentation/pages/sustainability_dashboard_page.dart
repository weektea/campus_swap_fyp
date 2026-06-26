import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';

class SustainabilityDashboardPage extends StatefulWidget {
  final int itemsReused;
  final double co2Saved;
  final double co2Bought;
  final double co2Sold;

  const SustainabilityDashboardPage({
    super.key, 
    required this.itemsReused, 
    required this.co2Saved,
    required this.co2Bought,
    required this.co2Sold
  });

  @override
  State<SustainabilityDashboardPage> createState() => _SustainabilityDashboardPageState();
}

class _SustainabilityDashboardPageState extends State<SustainabilityDashboardPage> {
  Map<String, double> _categoryData = {};
  List<dynamic> _leaderboard = [];
  bool _isLoadingCategories = true;
  bool _isLoadingLeaderboard = true;

  // Dynamic user stats to keep them in sync with backend
  int _itemsReused = 0;
  double _co2Saved = 0.0;
  double _co2Bought = 0.0;
  double _co2Sold = 0.0;

  @override
  void initState() {
    super.initState();
    _itemsReused = widget.itemsReused;
    _co2Saved = widget.co2Saved;
    _co2Bought = widget.co2Bought;
    _co2Sold = widget.co2Sold;
    _fetchUserStats();
    _fetchCategoryImpact();
    _fetchLeaderboard();
  }

  Future<void> _fetchUserStats() async {
    try {
      final session = UserSession();
      if (!session.isLoggedIn) return;
      final apiClient = ApiClient();
      final resData = await apiClient.get('/auth/user/${session.userId}');
      if (resData != null && resData['user'] != null) {
          final userData = resData['user'];
          if (mounted) {
              setState(() {
                  _co2Saved = double.tryParse(userData['total_carbon_saved'].toString()) ?? 0.0;
                  _co2Bought = double.tryParse(userData['carbon_saved_buyer'].toString()) ?? 0.0;
                  _co2Sold = double.tryParse(userData['carbon_saved_seller'].toString()) ?? 0.0;
                  _itemsReused = int.tryParse(userData['items_reused'].toString()) ?? 0;
              });
          }
      }
    } catch (e) {
      debugPrint('Error fetching user stats in dashboard: $e');
    }
  }

  Future<void> _fetchCategoryImpact() async {
    try {
      final apiClient = ApiClient();
      final res = await apiClient.get('/sustainability/category-impact');
      
      if (res != null && res is Map) {
         Map<String, double> parsed = {};
         res.forEach((k, v) {
            parsed[k.toString()] = double.tryParse(v.toString()) ?? 0.0;
         });
         if (mounted) {
            setState(() {
               _categoryData = parsed;
               _isLoadingCategories = false;
            });
         }
      }
    } catch (e) {
      debugPrint('Error fetching category impact: $e');
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final apiClient = ApiClient();
      final res = await apiClient.get('/sustainability/leaderboard');
      
      if (res != null && res is List) {
         if (mounted) {
            setState(() {
               _leaderboard = res;
               _isLoadingLeaderboard = false;
            });
         }
      }
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      if (mounted) setState(() => _isLoadingLeaderboard = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double treesPlanted = _co2Saved / 21.0; 
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Sustainability Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                   _buildStatMetric("Total Impact", "${_co2Saved.toStringAsFixed(1)} kg", Icons.public),
                   const SizedBox(height: 16),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: [
                        _buildStatMetric("Emissions Avoided\n(Bought)", "${_co2Bought.toStringAsFixed(1)} kg", Icons.shopping_bag_outlined, isSub: true),
                        Container(width: 1, height: 40, color: Colors.white30),
                        _buildStatMetric("Waste Diverted\n(Sold)", "${_co2Sold.toStringAsFixed(1)} kg", Icons.sell_outlined, isSub: true),
                     ],
                   ),
                   const SizedBox(height: 24),
                   Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16)
                      ),
                      child: Row(
                          children: [
                              const Icon(Icons.park, color: Colors.white, size: 40),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                          Text("Tree Equivalent", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                                          Text("You've saved the equivalent of ${treesPlanted.toStringAsFixed(1)} trees!", style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                  )
                              )
                          ],
                      )
                   )
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text("Impact by Category", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _isLoadingCategories 
                        ? const Center(child: CircularProgressIndicator()) 
                        : _categoryData.isEmpty 
                            ? const Text("No transactions yet.")
                            : _buildCustomBarChart(),
                    const SizedBox(height: 32),
                    Text("Campus Leaderboard", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _isLoadingLeaderboard
                        ? const Center(child: CircularProgressIndicator())
                        : _leaderboard.isEmpty
                            ? const Text("No leaderboard data.")
                            : _buildLeaderboard(),
                 ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatMetric(String label, String value, IconData icon, {bool isSub = false}) {
      return Column(
          children: [
              Icon(icon, color: Colors.white, size: isSub ? 20 : 28),
              const SizedBox(height: 8),
              Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: isSub ? 18 : 28, fontWeight: FontWeight.bold)),
              Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: isSub ? 10 : 14), textAlign: TextAlign.center),
          ]
      );
  }

  Widget _buildCustomBarChart() {
      // Find max value for scaling
      double maxVal = 1.0;
      if (_categoryData.isNotEmpty) {
          maxVal = _categoryData.values.reduce((curr, next) => curr > next ? curr : next);
      }

      return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0,4))]
          ),
          child: Column(
              children: _categoryData.entries.map((e) {
                  final pct = e.value / maxVal;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                        children: [
                            SizedBox(width: 80, child: Text(e.key, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500))),
                            Expanded(
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 12,
                                        backgroundColor: Colors.grey.shade200,
                                        color: Colors.green.shade400,
                                    ),
                                )
                            ),
                            const SizedBox(width: 12),
                            SizedBox(width: 40, child: Text("${e.value.toStringAsFixed(1)}kg", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.right)),
                        ]
                    ),
                  );
              }).toList(),
          ),
      );
  }

  Widget _buildLeaderboard() {
      final session = UserSession();

      return Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0,4))]
          ),
          child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _leaderboard.length,
              separatorBuilder: (_,__) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                  final l = _leaderboard[index];
                  final isMe = l['id']?.toString() == session.userId?.toString();
                  final rank = l['rank'] ?? (index + 1);
                  final name = isMe ? "You (${l['name']})" : l['name'].toString();
                  final co2 = double.tryParse(l['co2'].toString()) ?? 0.0;

                  return ListTile(
                      leading: CircleAvatar(
                          backgroundColor: _getRankColor(rank as int),
                          child: Text("#$rank", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      title: Text(name, style: GoogleFonts.outfit(fontWeight: isMe ? FontWeight.bold : FontWeight.normal, color: isMe ? Colors.green.shade700 : Colors.black87)),
                      trailing: Text("${co2.toStringAsFixed(1)} kg", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.green.shade600)),
                      tileColor: isMe ? Colors.green.shade50 : null,
                      shape: isMe ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)) : null,
                  );
              },
          ),
      );
  }

  Color _getRankColor(int rank) {
      if (rank == 1) return Colors.amber;
      if (rank == 2) return Colors.blueGrey;
      if (rank == 3) return Colors.brown.shade400;
      return Colors.grey.shade400;
  }
}
