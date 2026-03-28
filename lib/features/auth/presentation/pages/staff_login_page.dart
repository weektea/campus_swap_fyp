import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/features/admin/presentation/pages/staff_dashboard_page.dart';

class StaffLoginPage extends StatefulWidget {
  const StaffLoginPage({super.key});

  @override
  State<StaffLoginPage> createState() => _StaffLoginPageState();
}

class _StaffLoginPageState extends State<StaffLoginPage> {
  final _staffIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _loginStaff() async {
    if (_staffIdController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Staff ID and Password')));
      return;
    }

    setState(() => _isLoading = true);
    
    // Simulate network delay for Mock Login
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
       setState(() => _isLoading = false);
       if (_staffIdController.text.toLowerCase() == 'admin' || _staffIdController.text.toLowerCase() == 'mod') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StaffDashboardPage()),
          );
       } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Staff Credentials')));
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900], // Dark theme for Admin portal
      appBar: AppBar(
        title: Text('STAFF PORTAL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.security, size: 64, color: Colors.blueGrey),
                const SizedBox(height: 16),
                Text('Admin / Moderator', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey[900])),
                Text('Internal System Access Only', style: GoogleFonts.outfit(fontSize: 12, color: Colors.red)),
                const SizedBox(height: 32),
                TextField(
                  controller: _staffIdController,
                  decoration: const InputDecoration(
                    labelText: 'Staff ID',
                    prefixIcon: Icon(Icons.badge),
                    hintText: 'e.g. admin or mod',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginStaff,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[900],
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : Text('SECURE LOGIN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
