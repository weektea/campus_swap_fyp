import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/features/home/presentation/pages/home_page.dart';
import 'package:campus_swap/features/auth/presentation/pages/register_page.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_swap/core/services/socket_service.dart';

import 'package:campus_swap/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}



class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;


  @override
  void initState() {
    super.initState();
    _loadUserCredentials();
  }

  Future<void> _loadUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_me') ?? false;
    
    String studentId = '';
    String password = '';
    
    if (remember) {
        studentId = prefs.getString('student_id') ?? '';
        password = prefs.getString('password') ?? '';
    }

    if (mounted) {
      setState(() {
        _rememberMe = remember;
        if (remember) {
            _studentIdController.text = studentId;
            _passwordController.text = password;
        }
      });
    }
  }

  Future<void> _saveUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('student_id', _studentIdController.text);
      await prefs.setString('password', _passwordController.text);
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('student_id');
      await prefs.remove('password');
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await _saveUserCredentials(); // Save credentials if checked

      try {
        final apiClient = ApiClient();
        final response = await apiClient.post('/auth/login', {
          'student_id': _studentIdController.text,
          'password': _passwordController.text,
        });

        // For MVP, we won't persist token yet, just assume success 

        final session = UserSession();
        session.token = response['token'];
        session.userId = response['user']['id'];
        session.email = response['user']['email'];
        session.username = response['user']['username'];
        session.fullName = response['user']['full_name'];
        session.role = response['user']['role'];

        // Initialize real-time WebSocket connection
        SocketService().init();

        if (mounted) {
           Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } catch (e) {
        if (mounted) {
          if (e is ApiException && e.message == 'Account Suspended') {
            _showSuspendedBottomSheet(e.responseData);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Login Failed: ${e.toString()}')),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSuspendedBottomSheet(Map<String, dynamic>? data) {
    final reason = data?['reason'] ?? 'Violation of community guidelines';
    String unbanDate = 'Permanent';
    if (data?['unban_date'] != null) {
      try {
        final date = DateTime.parse(data!['unban_date']);
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        unbanDate = '${months[date.month - 1]} ${date.day}, ${date.year}';
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Account Suspended',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account has been restricted due to a violation of our community guidelines.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Reason:', style: TextStyle(color: Colors.grey[600])),
                        Text(reason, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Unban Date:', style: TextStyle(color: Colors.grey[600])),
                        Text(unbanDate, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D503C), // Dark green
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close sheet
                    // Add external url launch if needed, or snackbar for MVP
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Redirecting to support...')));
                  },
                  child: const Text('Contact Support', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Dismiss', style: TextStyle(color: Colors.grey[700], fontSize: 16)),
              ),
              const SizedBox(height: 16), // Padding for bottom notch
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.eco_rounded,
                        size: 80,
                        color: Color(0xFF00695C),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Campus Swap',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Trade Smarter, Live Greener',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 48),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _studentIdController,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Student ID',
                                prefixIcon: Icon(Icons.badge_outlined),
                                hintText: 'YYAAAXXXXX',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your student ID';
                                }
                                if (!RegExp(r'^\d{2}[a-zA-Z]{3}\d{5}$').hasMatch(value)) {
                                  return 'Invalid format. Use YYAAAXXXXX (e.g. 24PMR01234)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_isPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
    
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                                const Flexible(child: Text('Remember Me', overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage()));
                                },
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Text(
                                'Login',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'New to Campus Swap?',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                            },
                            child: const Text('Register Now'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    // Simulate jumping to a web portal via Chrome / external browser
                    final Uri adminUrl = Uri.parse('http://localhost:5173/');
                    if (!await launchUrl(adminUrl, mode: LaunchMode.externalApplication)) {
                        if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open external browser')));
                        }
                    }
                  }, 
                  icon: const Icon(Icons.admin_panel_settings, size: 18), 
                  label: const Text('Admin Portal'),
                  style: FilledButton.styleFrom(
                     backgroundColor: Colors.blueGrey.withValues(alpha: 0.1),
                     foregroundColor: Colors.blueGrey,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
