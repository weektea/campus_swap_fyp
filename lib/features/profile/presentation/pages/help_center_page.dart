import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/features/profile/presentation/pages/ticket_chat_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/my_purchases_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/settings_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/submit_ticket_page.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();
  
  List<dynamic> _reports = [];
  List<dynamic> _disputes = [];
  List<dynamic> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final reportsRes = await _apiClient.get('/tickets/my-reports');
      final disputesRes = await _apiClient.get('/tickets/my-disputes');
      final ticketsRes = await _apiClient.get('/tickets/my-tickets');
      
      if (mounted) {
        setState(() {
          _reports = reportsRes is List ? reportsRes : [];
          _disputes = disputesRes is List ? disputesRes : [];
          _tickets = ticketsRes is List ? ticketsRes : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getBadgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'uphold':
      case 'completed':
        return const Color(0xFF4CAF50); // Green
      case 'in-progress':
      case 'investigating':
      case 'escalated':
        return const Color(0xFF2196F3); // Blue
      case 'dismissed':
      case 'cancelled':
        return const Color(0xFFF44336); // Red
      case 'pending':
      case 'new':
      case 'open':
      default:
        return const Color(0xFFFFC107); // Yellow
    }
  }

  Widget _buildGridButton(IconData icon, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (label == 'Orders') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTransactionsPage()));
            } else if (label == 'App Issues') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitTicketPage()));
            } else if (label == 'Account') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
            } else if (label == 'Report User') {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Report User', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const Text('To report a user for misconduct or fraud, please navigate to their public profile and click the "Report" icon in the top right corner.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))
                  ]
                )
              );
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF006940), size: 32),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(dynamic item, String type) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    String title = '';
    String status = item['status'] ?? 'Unknown';
    String dateStr = item['createdAt'] != null ? item['createdAt'].toString().substring(0, 10) : 'Unknown date';
    String esgMessage = '';
    
    if (type == 'Report') {
      title = 'Reported Listing #${item['id'].toString().substring(0, 6).toUpperCase()}';
      if (status == 'Uphold') {
        esgMessage = "Thank you for your contribution to a safer, greener campus.";
      }
    } else if (type == 'Dispute') {
      title = 'Dispute on Order #${item['transaction_id'].toString().substring(0, 6).toUpperCase()}';
    } else {
      title = item['subject'] ?? 'Support Ticket #${item['id'].toString().substring(0, 6).toUpperCase()}';
    }

    return GestureDetector(
      onTap: () {
        if (type == 'Dispute' || type == 'SupportTicket') {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => TicketChatPage(
              referenceId: item['id'],
              referenceType: type,
              title: title,
              status: status,
            )
          )).then((_) => _fetchData());
        } else {
          // For Reports, just show dialog since it's one-way
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Report Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Reason: ${item['violation_type'] ?? 'Violation'}'),
                  const SizedBox(height: 8),
                  Text('Status: $status'),
                  if (esgMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(esgMessage, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    )
                  ]
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
              ],
            )
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getBadgeColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text('Created $dateStr', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            if (esgMessage.isNotEmpty)
               Padding(
                 padding: const EdgeInsets.only(top: 8.0),
                 child: Text(esgMessage, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
               )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryGreen = const Color(0xFF006940);
    final bgColor = isDark ? theme.colorScheme.surface : const Color(0xFFF9F9F9);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Help Center', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitTicketPage()));
        },
        backgroundColor: primaryGreen,
        child: const Icon(Icons.headset_mic, color: Colors.white),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          // Top section with search and grid
          Container(
            color: bgColor,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      icon: Icon(Icons.search, color: Colors.grey),
                      hintText: 'Search for help...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Grid Options
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.0,
                  children: [
                    _buildGridButton(Icons.receipt_long, 'Orders'),
                    _buildGridButton(Icons.person_outline, 'Account'),
                    _buildGridButton(Icons.flag_outlined, 'Report User'),
                    _buildGridButton(Icons.error_outline, 'App Issues'),
                  ],
                ),
                const SizedBox(height: 32),
                
                const Text('My Support Tickets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          
          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryGreen,
            tabs: const [
              Tab(text: 'Reports'),
              Tab(text: 'Disputes'),
              Tab(text: 'Tickets'),
            ],
          ),
          
          // Tab Views
          Expanded(
            child: Container(
              color: isDark ? theme.colorScheme.surface : const Color(0xFFF0F2F0),
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Reports Tab
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) => _buildTicketCard(_reports[index], 'Report'),
                  ),
                  
                  // Disputes Tab
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _disputes.length,
                    itemBuilder: (context, index) => _buildTicketCard(_disputes[index], 'Dispute'),
                  ),
                  
                  // Tickets Tab
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tickets.length,
                    itemBuilder: (context, index) => _buildTicketCard(_tickets[index], 'SupportTicket'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
