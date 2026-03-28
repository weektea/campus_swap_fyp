import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:google_fonts/google_fonts.dart';

class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _metrics = {};
  List<dynamic> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      // Use mock data if API fails to show UI for demo
      try {
        final metricsRes = await apiClient.get('/admin/metrics');
        _metrics = metricsRes;
      } catch (_) {
        _metrics = {
           'total_users': 142,
           'active_listings': 87,
           'total_transactions': 304,
           'monthly_revenue': 45.0
        };
      }

      try {
        final repRes = await apiClient.get('/admin/reports');
        _reports = repRes is List ? repRes : [];
      } catch (_) {
        _reports = [
            {'category': 'Fake Item', 'description': 'User says item is a drop-shipped fake', 'status': 'Pending'},
            {'category': 'Scam/Fraud', 'description': 'Asked to pay outside platform', 'status': 'Resolved'}
        ];
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerBackup() async {
    try {
      final apiClient = ApiClient();
      await apiClient.post('/admin/backup', {});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database Backup Triggered Successfully', style: TextStyle(color: Colors.green))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simulated Backup Complete (Mock)', style: GoogleFonts.outfit())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.cyanAccent,
          tabs: const [
            Tab(text: 'Overview (Admin)'),
            Tab(text: 'Reports (Moderator)'),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildReportsTab(),
            ],
          ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Metrics', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard('Total Users', _metrics['total_users']?.toString() ?? '0', Icons.people, Colors.blue),
              _buildMetricCard('Active Listings', _metrics['active_listings']?.toString() ?? '0', Icons.inventory_2, Colors.orange),
              _buildMetricCard('Transactions', _metrics['total_transactions']?.toString() ?? '0', Icons.swap_horiz, Colors.purple),
              _buildMetricCard('Ad Revenue', 'RM ${_metrics['monthly_revenue']?.toString() ?? '0.00'}', Icons.attach_money, Colors.green),
            ],
          ),
          const SizedBox(height: 32),
          Text('System Tasks', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.backup, color: Colors.blue),
            title: Text('Database Backup', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            subtitle: Text('Manual backup of SQL database', style: GoogleFonts.outfit()),
            trailing: ElevatedButton(
              onPressed: _triggerBackup,
              child: const Text('Run Now'),
            ),
          ),
           const SizedBox(height: 12),
           ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.people_outline, color: Colors.orange),
            title: Text('Manage Users', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            subtitle: Text('Promote moderators, ban spam accounts', style: GoogleFonts.outfit()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening User Management (Mock UI)')));
            },
          )
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    if (_reports.isEmpty) {
      return Center(child: Text('No reports pending validation.', style: GoogleFonts.outfit(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final rep = _reports[index];
        final isResolved = rep['status'] == 'Resolved';
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: Icon(
              isResolved ? Icons.check_circle : Icons.warning_rounded,
              color: isResolved ? Colors.green : Colors.red,
            ),
            title: Text(rep['category'] ?? 'General Report', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            subtitle: Text('Status: ${rep['status']}', style: GoogleFonts.outfit(color: isResolved ? Colors.green : Colors.red)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Description:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(rep['description'] ?? 'No details provided.', style: GoogleFonts.outfit()),
                    const SizedBox(height: 16),
                    if (!isResolved)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                               // Ignore logic mock
                            },
                            child: const Text('Dismiss'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                               // Resolve logic mock
                               setState(() {
                                   _reports[index]['status'] = 'Resolved';
                               });
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report marked as Resolved')));
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            child: const Text('Mark Resolved', style: TextStyle(color: Colors.white)),
                          )
                        ],
                      )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
