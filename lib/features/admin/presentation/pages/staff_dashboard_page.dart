import 'package:flutter/material.dart';
import 'package:campus_swap/features/admin/presentation/layouts/portal_layout.dart';
import 'package:campus_swap/features/admin/presentation/pages/moderator_dashboard_page.dart';
import 'package:campus_swap/features/admin/presentation/pages/triage_review_page.dart';
import 'package:campus_swap/features/admin/presentation/pages/dispute_arbitration_page.dart';
import 'package:campus_swap/features/admin/presentation/pages/user_management_page.dart';
import 'package:campus_swap/features/admin/presentation/pages/system_metrics_page.dart';
import 'package:google_fonts/google_fonts.dart';

class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
  int _selectedIndex = 0;

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: // Dashboard
        return const ModeratorDashboardPage();
      case 1: // Reports (Triage & Review)
        return const TriageReviewPage();
      case 2: // Disputes
        return const DisputeArbitrationPage();
      case 3: // User Management
        return const UserManagementPage();
      case 4: // Analytics (System Metrics)
        return const SystemMetricsPage();
      default:
        return Center(
          child: Text(
            'Under Construction',
            style: GoogleFonts.outfit(fontSize: 24, color: Colors.grey[500]),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PortalLayout(
      selectedIndex: _selectedIndex,
      onItemSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      body: _buildBody(),
    );
  }
}
