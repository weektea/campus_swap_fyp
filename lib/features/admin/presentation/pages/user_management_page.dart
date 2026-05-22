import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

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
              Text('User Directory', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Container(
                    width: 250,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        hintStyle: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: 'All Status',
                        items: ['All Status', 'Active', 'Banned']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.outfit(fontSize: 14))))
                            .toList(),
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          // User Table
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                columns: [
                  DataColumn(label: Text('USER ID', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
                  DataColumn(label: Text('NAME/EMAIL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
                  DataColumn(label: Text('ROLE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
                  DataColumn(label: Text('ECO-SCORE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
                  DataColumn(label: Text('REPORTS AGAINST', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
                  DataColumn(label: Text('STATUS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
                  DataColumn(label: Text('ACTIONS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]))),
                ],
                rows: [
                  _buildDataRow('USR-1024', 'Sarah Chen', 'sarah.chen@university.edu', 'Student', '85', '0', 'Active'),
                  _buildDataRow('USR-0892', 'Mark Johnson', 'mark.j@university.edu', 'Student', '25', '7', 'Banned'),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  DataRow _buildDataRow(String id, String name, String email, String role, String ecoScore, String reports, String status) {
    bool isActive = status == 'Active';
    bool highReports = int.tryParse(reports) != null && int.parse(reports) > 5;
    
    return DataRow(
      cells: [
        DataCell(Text(id, style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 14))),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name, style: GoogleFonts.outfit(color: Colors.black87, fontSize: 14)),
              Text(email, style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12)),
            ],
          )
        ),
        DataCell(Text(role, style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 14))),
        DataCell(Text(ecoScore, style: GoogleFonts.outfit(color: const Color(0xFF0D503C), fontWeight: FontWeight.bold, fontSize: 14))),
        DataCell(Text(reports, style: GoogleFonts.outfit(color: highReports ? Colors.red : Colors.grey[700], fontWeight: highReports ? FontWeight.bold : FontWeight.normal, fontSize: 14))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: GoogleFonts.outfit(
                color: isActive ? Colors.green[700] : Colors.red[700],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          TextButton(
            onPressed: () {},
            child: Text('View Details', style: GoogleFonts.outfit(color: const Color(0xFF0D503C), fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
