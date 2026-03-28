import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SustainabilityDashboardPage extends StatelessWidget {
  final int itemsReused;
  final double co2Saved;

  const SustainabilityDashboardPage({super.key, required this.itemsReused, required this.co2Saved});

  @override
  Widget build(BuildContext context) {
    // Mock calculations
    final double treesPlanted = co2Saved / 21.0; // Assume 1 mature tree absorbs ~21kg CO2/year
    
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
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: [
                        _buildStatMetric("Items Reused", itemsReused.toString(), Icons.recycling),
                        Container(width: 1, height: 50, color: Colors.white30),
                        _buildStatMetric("CO2 Saved", "${co2Saved.toStringAsFixed(1)} kg", Icons.cloud_done),
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
                    _buildCustomBarChart(),
                    const SizedBox(height: 32),
                    Text("Campus Leaderboard", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildLeaderboard(),
                 ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatMetric(String label, String value, IconData icon) {
      return Column(
          children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
          ]
      );
  }

  Widget _buildCustomBarChart() {
      // Mock data for impact by category
      final data = {
          'Books': 40,
          'Electronics': 85,
          'Clothing': 30,
          'Furniture': 50,
      };
      
      final double maxVal = 100.0; // scale factor

      return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0,4))]
          ),
          child: Column(
              children: data.entries.map((e) {
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
                            SizedBox(width: 40, child: Text("${e.value}kg", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.right)),
                        ]
                    ),
                  );
              }).toList(),
          ),
      );
  }

  Widget _buildLeaderboard() {
      // Mock leaderboard data
      final leaders = [
          {'name': 'Alex Johnson', 'co2': '120.5 kg', 'rank': 1},
          {'name': 'You (Current User)', 'co2': '${co2Saved.toStringAsFixed(1)} kg', 'rank': 2}, // Mock rank 2 for demonstration
          {'name': 'Sarah Tan', 'co2': '45.2 kg', 'rank': 3},
          {'name': 'Wei Ling', 'co2': '30.0 kg', 'rank': 4},
      ];

      return Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0,4))]
          ),
          child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leaders.length,
              separatorBuilder: (_,__) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                  final l = leaders[index];
                  final isMe = l['name']!.toString().startsWith('You');
                  return ListTile(
                      leading: CircleAvatar(
                          backgroundColor: _getRankColor(l['rank'] as int),
                          child: Text("#${l['rank']}", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      title: Text(l['name'].toString(), style: GoogleFonts.outfit(fontWeight: isMe ? FontWeight.bold : FontWeight.normal, color: isMe ? Colors.green.shade700 : Colors.black87)),
                      trailing: Text(l['co2'].toString(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.green.shade600)),
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
