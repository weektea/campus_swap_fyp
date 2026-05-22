import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PortalLayout extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final Widget body;

  const PortalLayout({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: const Color(0xFF1E2622),
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D503C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'CM',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Campus Swap',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Moderator Portal',
                              style: GoogleFonts.outfit(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildMenuItem(0, 'Dashboard', Icons.dashboard_outlined),
                      _buildMenuItem(1, 'Reports', Icons.warning_amber_rounded),
                      _buildMenuItem(2, 'Disputes', Icons.shield_outlined),
                      _buildMenuItem(3, 'User Management', Icons.people_outline),
                      _buildMenuItem(4, 'Analytics', Icons.bar_chart_rounded),
                      _buildMenuItem(5, 'Backup & Restore', Icons.storage_rounded),
                      _buildMenuItem(6, 'Support Tickets', Icons.headset_mic_outlined),
                      _buildMenuItem(7, 'My History', Icons.history),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6F5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search tickets, users, or listings...',
                              hintStyle: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 14),
                              prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Actions
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(Icons.notifications_none_rounded, color: Colors.grey[600]),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(width: 24),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF0D503C),
                        child: Text('MJ', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
                // Page Body
                Expanded(
                  child: body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon) {
    bool isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onItemSelected(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D503C) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[400], size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
