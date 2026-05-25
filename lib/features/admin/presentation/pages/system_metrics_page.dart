import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/core/api/api_client.dart';

class SystemMetricsPage extends StatefulWidget {
  const SystemMetricsPage({super.key});

  @override
  State<SystemMetricsPage> createState() => _SystemMetricsPageState();
}

class _SystemMetricsPageState extends State<SystemMetricsPage> {
  bool _isLoading = true;
  int _totalUsers = 0;
  int _activeDisputes = 0;
  int _totalTransactions = 0;
  double _co2Saved = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
  }

  Future<void> _fetchMetrics() async {
    try {
      final res = await ApiClient().get('/moderator/metrics');
      if (mounted) {
        setState(() {
          _totalUsers = res['total_users'] ?? 0;
          _activeDisputes = res['active_disputes'] ?? 0;
          _totalTransactions = res['total_transactions'] ?? 0;
          _co2Saved = (res['co2_saved_kg'] ?? 0).toDouble();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('System Metrics', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Last 30 Days', style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: Text('Export PDF', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D503C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: Text('Export CSV', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D503C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          // Metric Cards Row
          _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  Expanded(child: _buildMetricCard('Total Transactions', '$_totalTransactions', null)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildMetricCard('Total Users', '$_totalUsers', null)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildMetricCard('Platform CO2 Saved', '$_co2Saved kg', Colors.green)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildMetricCard('Open Disputes', '$_activeDisputes', Colors.red)),
                ],
              ),
          const SizedBox(height: 32),
          // Charts Row
          Row(
            children: [
              // Daily Transactions (Mock Bar Chart)
              Expanded(
                flex: 2,
                child: Container(
                  height: 350,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily Transactions', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(30, (index) {
                            final double heightPercent = 0.3 + (index * 0.02) + (index % 3 * 0.05); // pseudo-random growth
                            return Container(
                              width: 12,
                              height: 250 * heightPercent,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D503C),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Day 1', style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12)),
                          Text('Day 15', style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12)),
                          Text('Day 30', style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Listings by Category (Mock Donut Chart)
              Expanded(
                flex: 1,
                child: Container(
                  height: 350,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Listings by Category', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Center(
                           // Placeholder for donut chart
                           child: Stack(
                             alignment: Alignment.center,
                             children: [
                               SizedBox(
                                 width: 150, height: 150,
                                 child: CircularProgressIndicator(
                                   value: 1.0,
                                   strokeWidth: 24,
                                   color: Color(0xFF1976D2), // Blue
                                 ),
                               ),
                               SizedBox(
                                 width: 150, height: 150,
                                 child: CircularProgressIndicator(
                                   value: 0.65, // Remaining 65%
                                   strokeWidth: 24,
                                   color: Color(0xFFF57C00), // Orange
                                 ),
                               ),
                               SizedBox(
                                 width: 150, height: 150,
                                 child: CircularProgressIndicator(
                                   value: 0.40, // 40% 
                                   strokeWidth: 24,
                                   color: Color(0xFF0D503C), // Dark green
                                 ),
                               ),
                               Container(
                                 width: 100, height: 100,
                                 decoration: BoxDecoration(
                                   color: Colors.white,
                                   shape: BoxShape.circle,
                                 ),
                               )
                             ],
                           )
                        ),
                      ),
                      // Legend
                      _buildLegendItem(Colors.green[800]!, 'Books', '40%'),
                      const SizedBox(height: 8),
                      _buildLegendItem(Colors.blue, 'Electronics', '35%'),
                      const SizedBox(height: 8),
                      _buildLegendItem(Colors.orange, 'Furniture', '25%'),
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color? highlightColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: highlightColor?.withValues(alpha: 0.05) ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlightColor?.withValues(alpha: 0.3) ?? Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(color: highlightColor ?? Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w400, color: highlightColor ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String percentage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 12)),
          ],
        ),
        Text(percentage, style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 12)),
      ],
    );
  }
}
