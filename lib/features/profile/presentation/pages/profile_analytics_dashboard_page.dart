import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/theme/app_theme.dart';

class ProfileAnalyticsDashboardPage extends StatefulWidget {
  const ProfileAnalyticsDashboardPage({super.key});

  @override
  State<ProfileAnalyticsDashboardPage> createState() => _ProfileAnalyticsDashboardPageState();
}

class _ProfileAnalyticsDashboardPageState extends State<ProfileAnalyticsDashboardPage> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _monthlyStats = [];
  Map<String, dynamic> _ratingsDistribution = {"fiveStars": 0, "others": 0};
  List<dynamic> _timelineEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    try {
      final res = await _apiClient.get('/profile/analytics');
      if (mounted) {
        setState(() {
          _monthlyStats = res['monthlyStats'] ?? [];
          _ratingsDistribution = Map<String, dynamic>.from(res['ratingsDistribution'] ?? {});
          _timelineEvents = res['timeline'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getHumanFriendlyAction(String action) {
    switch (action) {
      case 'ITEM_LISTED':
        return 'You listed an item for sale';
      case 'ITEM_SOLD':
        return 'You successfully sold an item';
      case 'ITEM_BOUGHT':
        return 'You successfully bought an item';
      case 'TICKET_OPENED':
        return 'You opened a support ticket';
      case 'ACCOUNT_REACTIVATED':
        return 'Your account was reactivated';
      default:
        return action.replaceAll('_', ' ').toLowerCase().split(' ').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'ITEM_LISTED':
        return Icons.add_to_photos_outlined;
      case 'ITEM_SOLD':
        return Icons.monetization_on_outlined;
      case 'ITEM_BOUGHT':
        return Icons.shopping_bag_outlined;
      case 'TICKET_OPENED':
        return Icons.support_agent_rounded;
      case 'ACCOUNT_REACTIVATED':
        return Icons.lock_open_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'ITEM_LISTED':
        return Colors.teal;
      case 'ITEM_SOLD':
        return Colors.green;
      case 'ITEM_BOUGHT':
        return Colors.blue;
      case 'TICKET_OPENED':
        return Colors.amber[800]!;
      case 'ACCOUNT_REACTIVATED':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(String timestampStr) {
    try {
      final dt = DateTime.parse(timestampStr).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Analytics & Impact',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error loading dashboard: $_errorMessage', style: GoogleFonts.outfit()))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Earnings vs ESG stats card
                      _buildBarChartSection(isDark),
                      const SizedBox(height: 20),

                      // Ratings Breakdown Card
                      _buildRatingsBreakdown(isDark),
                      const SizedBox(height: 20),

                      // Timeline Activity Card
                      _buildActivityTimeline(isDark),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBarChartSection(bool isDark) {
    // Determine maximum value for Y-axis scaling
    double maxVal = 10.0;
    for (var m in _monthlyStats) {
      final e = (m['earnings'] as num?)?.toDouble() ?? 0.0;
      final c = (m['carbonSaved'] as num?)?.toDouble() ?? 0.0;
      if (e > maxVal) maxVal = e;
      if (c > maxVal) maxVal = c;
    }
    // Scale max val with some padding
    maxVal = (maxVal * 1.2).ceilToDouble();

    return Card(
      elevation: 0,
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings vs. Carbon Saved',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Your past 6 months eco-impact & marketplace sales',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: _monthlyStats.isEmpty
                  ? Center(child: Text('No transaction history.', style: GoogleFonts.outfit(color: Colors.grey)))
                  : BarChart(
                      BarChartData(
                        maxY: maxVal,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < _monthlyStats.length) {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      _monthlyStats[index]['month'] ?? '',
                                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[600]),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              reservedSize: 24,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    value.toInt().toString(),
                                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[600]),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(_monthlyStats.length, (index) {
                          final m = _monthlyStats[index];
                          final earnings = (m['earnings'] as num?)?.toDouble() ?? 0.0;
                          final carbonSaved = (m['carbonSaved'] as num?)?.toDouble() ?? 0.0;

                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: earnings,
                                color: AppTheme.secondaryColor,
                                width: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              BarChartRodData(
                                toY: carbonSaved,
                                color: AppTheme.primaryColor,
                                width: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            // Legends
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(AppTheme.secondaryColor, 'Earnings (RM)'),
                const SizedBox(width: 24),
                _buildLegendItem(AppTheme.primaryColor, 'Carbon Saved (kg CO2e)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildRatingsBreakdown(bool isDark) {
    final int fiveStars = _ratingsDistribution['fiveStars'] ?? 0;
    final int others = _ratingsDistribution['others'] ?? 0;
    final int total = fiveStars + others;

    return Card(
      elevation: 0,
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reputation Breakdown',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Ratio of your 5-star ratings vs other ratings',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            total == 0
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('No reviews received yet.', style: GoogleFonts.outfit(color: Colors.grey)),
                    ),
                  )
                : Row(
                    children: [
                      // Pie Chart
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                            sections: [
                              PieChartSectionData(
                                color: Colors.teal[600],
                                value: fiveStars.toDouble(),
                                title: '${((fiveStars / total) * 100).toStringAsFixed(0)}%',
                                radius: 30,
                                titleStyle: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                color: Colors.grey[400],
                                value: others.toDouble(),
                                title: others > 0 ? '${((others / total) * 100).toStringAsFixed(0)}%' : '',
                                radius: 25,
                                titleStyle: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Details List
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRatingStatRow(Colors.teal[600]!, '5-Star Ratings', '$fiveStars reviews'),
                            const SizedBox(height: 8),
                            _buildRatingStatRow(Colors.grey[400]!, 'Other Ratings', '$others reviews'),
                            const Divider(height: 24),
                            Text(
                              'Total Verified Reviews: $total',
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStatRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildActivityTimeline(bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity History',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Timeline of your recent trading & support actions',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _timelineEvents.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('No recent activities logged.', style: GoogleFonts.outfit(color: Colors.grey)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _timelineEvents.length,
                    itemBuilder: (context, index) {
                      final event = _timelineEvents[index];
                      final action = event['action'] ?? '';
                      final timestamp = event['timestamp'] ?? '';
                      final isFirst = index == 0;
                      final isLast = index == _timelineEvents.length - 1;

                      final actionColor = _getActionColor(action);

                      return SizedBox(
                        height: 70,
                        child: TimelineTile(
                          alignment: TimelineAlign.start,
                          isFirst: isFirst,
                          isLast: isLast,
                          indicatorStyle: IndicatorStyle(
                            width: 28,
                            height: 28,
                            color: actionColor,
                            iconStyle: IconStyle(
                              iconData: _getActionIcon(action),
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          beforeLineStyle: LineStyle(color: Colors.grey.withValues(alpha: 0.3), thickness: 2),
                          afterLineStyle: LineStyle(color: Colors.grey.withValues(alpha: 0.3), thickness: 2),
                          endChild: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getHumanFriendlyAction(action),
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatTimestamp(timestamp),
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
