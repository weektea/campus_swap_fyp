import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';

class ModeratorDashboardPage extends StatefulWidget {
  const ModeratorDashboardPage({super.key});

  @override
  State<ModeratorDashboardPage> createState() => _ModeratorDashboardPageState();
}

class _ModeratorDashboardPageState extends State<ModeratorDashboardPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _reports = [];
  List<dynamic> _disputes = [];
  List<dynamic> _tickets = [];
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();
  final String _currentUserId = UserSession().userId ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiClient.get('/moderator/dashboard');
      setState(() {
        _reports = data['reports'] ?? [];
        _disputes = data['disputes'] ?? [];
        _tickets = data['tickets'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load dashboard: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text('Moderator Dashboard', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
        ),
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0D503C),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0D503C),
          tabs: [
            Tab(text: 'Reports (${_reports.length})'),
            Tab(text: 'Disputes (${_disputes.length})'),
            Tab(text: 'Tickets (${_tickets.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildReportsTab(),
              _buildDisputesTab(),
              _buildTicketsTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ================= REPORT (UC10, UC12) =================
  Widget _buildReportsTab() {
    if (_reports.isEmpty) return const Center(child: Text('No pending reports.'));
    
    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        final product = report['product'] ?? {};
        return Card(
          margin: const EdgeInsets.only(bottom: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Side: Report Details
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.red.withOpacity(0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Report Evidence', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red[800])),
                            const SizedBox(height: 12),
                            Text('Violation Type: ${report['violation_type']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Description: ${report['description']}'),
                            const SizedBox(height: 8),
                            Text('Reporter ID: ${report['reporter_id']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right Side: Product Details
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey.withOpacity(0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Target Product', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 12),
                            Text('Title: ${product['title'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Price: RM ${product['price'] ?? 'N/A'}'),
                            const SizedBox(height: 8),
                            Text('Status: ${product['status'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _confirmAction(
                          title: 'Dismiss Report',
                          content: 'Are you sure you want to dismiss this report as a false alarm?',
                          actionName: 'Dismiss',
                          onConfirm: () => _handleReport(report['id'], 'Dismissed'),
                      ),
                      child: const Text('Dismiss (False Alarm)'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => _confirmAction(
                          title: 'Uphold Report & Suspend',
                          content: 'This will suspend the product and CANCEL all active orders tied to it. This cannot be undone.',
                          actionName: 'Uphold',
                          isDestructive: true,
                          onConfirm: () => _handleReport(report['id'], 'Uphold'),
                      ),
                      child: const Text('Uphold (Suspend & Cancel Orders)', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleReport(String id, String status) async {
    try {
      await _apiClient.put('/moderator/reports/$id/status', {'status': status});
      _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report $status')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ================= DISPUTES (UC23) =================
  Widget _buildDisputesTab() {
    if (_disputes.isEmpty) return const Center(child: Text('No active disputes.'));

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: _disputes.length,
      itemBuilder: (context, index) {
        final dispute = _disputes[index];
        String replyText = '';
        return Card(
          margin: const EdgeInsets.only(bottom: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dispute #${dispute['id'].toString().substring(0,8)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                Text('Reason: ${dispute['reason']}', style: const TextStyle(color: Colors.red)),
                Text('Description: ${dispute['description']}'),
                Text('Status: ${dispute['status']}'),
                if (dispute['admin_notes'] != null) ...[
                  const SizedBox(height: 16),
                  Text('Moderator Log:\n${dispute['admin_notes']}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey)),
                ],
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => replyText = v,
                  decoration: const InputDecoration(labelText: 'Action Reply / Evidence Request', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  children: [
                    ElevatedButton(
                      onPressed: () => _confirmAction(
                        title: 'Request Evidence',
                        content: 'Change dispute status to Investigating?',
                        actionName: 'Confirm',
                        onConfirm: () => _triageDispute(dispute['id'], 'Investigating', replyText)), 
                      child: const Text('Ask for Evidence (Investigating)')
                    ),
                    ElevatedButton(
                      onPressed: () => _confirmAction(
                        title: 'Mediate Dispute',
                        content: 'Mark this dispute as resolved via mediation?',
                        actionName: 'Resolve',
                        onConfirm: () => _triageDispute(dispute['id'], 'Mediation', replyText)), 
                      child: const Text('Mediation (Resolved)')
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () => _confirmAction(
                        title: 'Dismiss Dispute',
                        content: 'This will unfreeze the transaction and allow it to proceed.',
                        actionName: 'Unfreeze',
                        onConfirm: () => _triageDispute(dispute['id'], 'Dismiss', replyText)), 
                      child: const Text('Dismiss (Unfreeze Order)', style: TextStyle(color: Colors.white))
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => _confirmAction(
                        title: 'Escalate to Admin',
                        content: 'Hand this dispute over to an Administrator for final arbitration?',
                        actionName: 'Escalate',
                        isDestructive: true,
                        onConfirm: () => _triageDispute(dispute['id'], 'Escalate', replyText)), 
                      child: const Text('Escalate to Admin', style: TextStyle(color: Colors.white))
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _triageDispute(String id, String action, String reply) async {
    try {
      await _apiClient.put('/moderator/disputes/$id/triage', {'action': action, 'reply': reply});
      _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dispute updated: $action')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ================= SUPPORT TICKETS (UC28) =================
  Widget _buildTicketsTab() {
    if (_tickets.isEmpty) return const Center(child: Text('No support tickets.'));

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        final bool isLocked = ticket['lockedByModeratorId'] != null;
        final bool isLockedByMe = ticket['lockedByModeratorId'] == _currentUserId;
        String replyText = '';

        return Card(
          margin: const EdgeInsets.only(bottom: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ticket: ${ticket['subject']} [${ticket['category']}]', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                    if (isLocked) 
                       Chip(
                         label: Text(isLockedByMe ? 'Locked by You' : 'Locked by Another Mod'),
                         backgroundColor: isLockedByMe ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                       ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(ticket['description']),
                const SizedBox(height: 16),
                
                if (!isLocked)
                  ElevatedButton(
                    onPressed: () => _claimTicket(ticket['id']), 
                    child: const Text('Claim Ticket')
                  )
                else if (isLockedByMe) ...[
                  TextField(
                    onChanged: (v) => replyText = v,
                    decoration: const InputDecoration(labelText: 'Reply Content', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D503C)),
                    onPressed: () => _confirmAction(
                      title: 'Resolve Ticket',
                      content: 'Send reply and close this support ticket?',
                      actionName: 'Resolve',
                      onConfirm: () => _resolveTicket(ticket['id'], replyText)), 
                    child: const Text('Reply & Resolve', style: TextStyle(color: Colors.white))
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _claimTicket(String id) async {
    try {
      await _apiClient.put('/moderator/tickets/$id/claim', {});
      _fetchData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to claim: $e')));
    }
  }

  Future<void> _resolveTicket(String id, String reply) async {
    if (reply.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply cannot be empty')));
      return;
    }
    try {
      await _apiClient.put('/moderator/tickets/$id/resolve', {'reply_content': reply});
      _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket Resolved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _confirmAction({
    required String title,
    required String content,
    required String actionName,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) async {
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDestructive ? Colors.red : null)),
        content: Text(content, style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isDestructive ? Colors.red : const Color(0xFF0D503C)),
            onPressed: () {
              Navigator.pop(ctx, true);
              onConfirm();
            },
            child: Text(actionName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
