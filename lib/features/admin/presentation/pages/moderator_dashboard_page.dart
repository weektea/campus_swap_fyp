import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModeratorDashboardPage extends StatelessWidget {
  const ModeratorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Pending Reports', '14', '+3', true)),
              const SizedBox(width: 24),
              Expanded(child: _buildStatCard('Open Disputes', '5', null, false)),
              const SizedBox(width: 24),
              Expanded(child: _buildStatCard('My Locked Tasks', '2', null, true, icon: Icons.circle, iconColor: Colors.green)),
            ],
          ),
          const SizedBox(height: 32),
          // Recent Open Tasks Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Recent Open Tasks',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                    columns: [
                      DataColumn(label: Text('TICKET ID', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
                      DataColumn(label: Text('TYPE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
                      DataColumn(label: Text('TARGET', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
                      DataColumn(label: Text('SUBMITTED', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
                      DataColumn(label: Text('STATUS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
                      DataColumn(label: Text('ACTION', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
                    ],
                    rows: [
                      _buildDataRow(
                        '#REP-102', 'Fake Item', 'Listing: Wooden Chair', '2 hrs ago', 'Open', false
                      ),
                      _buildDataRow(
                        '#DIS-88', 'Item not as described', 'Order #TRX-99', '5 hrs ago', 'Locked (Alex)', true
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String? trend, bool isTrendPositive, {IconData? icon, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14)),
              if (trend != null)
                Row(
                  children: [
                    Icon(isTrendPositive ? Icons.trending_up : Icons.trending_down, size: 16, color: isTrendPositive ? Colors.red : Colors.green),
                    const SizedBox(width: 4),
                    Text(trend, style: GoogleFonts.outfit(color: isTrendPositive ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              if (icon != null)
                Icon(icon, size: 12, color: iconColor),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w300, color: Colors.black87)),
        ],
      ),
    );
  }

  DataRow _buildDataRow(String id, String type, String target, String submitted, String status, bool isLocked) {
    return DataRow(
      cells: [
        DataCell(Text(id, style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 14))),
        DataCell(Text(type, style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 14))),
        DataCell(
           SizedBox(
             width: 120,
             child: Text(target, style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 14))
           )
        ),
        DataCell(Text(submitted, style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 14))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isLocked ? Colors.blue.withOpacity(0.1) : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: GoogleFonts.outfit(
                color: isLocked ? Colors.blue[700] : Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: isLocked ? Colors.grey[300] : const Color(0xFF0D503C),
              foregroundColor: isLocked ? Colors.grey[600] : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Review', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
