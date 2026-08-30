import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/core/services/socket_service.dart';
import 'package:campus_swap/features/auth/presentation/pages/onboarding_page.dart';
import 'package:campus_swap/features/home/presentation/pages/home_page.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;

  const OtpVerificationPage({
    super.key,
    required this.email,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final apiClient = ApiClient();
        final response = await apiClient.post('/auth/verify-otp', {
          'email': widget.email,
          'otp': _otpController.text.trim(),
        });

        if (mounted) {
          _showSuccessSnackBar('Verification Successful!');

          if (response != null && response['token'] != null && response['user'] != null) {
            final session = UserSession();
            session.token = response['token'];
            session.userId = response['user']['id'];
            session.email = response['user']['email'];
            session.username = response['user']['username'];
            session.fullName = response['user']['full_name'];
            session.avatarUrl = response['user']['profile_picture'];
            session.role = response['user']['role'];
            final bool isOnboarded = response['user']['is_onboarded'] == true;
            session.isOnboarded = isOnboarded;
            session.primaryIntent = response['user']['primary_intent'] ?? 'browse';
            session.preferenceTags = List<String>.from(response['user']['preference_tags'] ?? []);
            await session.saveToStorage();

            SocketService().init();

            if (!mounted) return;

            if (!isOnboarded) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const OnboardingPage()),
                (route) => false,
              );
              return;
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
              );
              return;
            }
          }

          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Verification Failed: ${e.toString()}');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);

    try {
      final apiClient = ApiClient();
      await apiClient.post('/auth/resend-otp', {
        'email': widget.email,
      });

      if (mounted) {
        _showSuccessSnackBar('Verification code resent successfully.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to resend code: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 80,
                  color: Color(0xFF00695C),
                ),
                const SizedBox(height: 32),
                Text(
                  'Enter Verification Code',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We have sent a 6-digit OTP code to the email address below. Please enter it to verify your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF00695C),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 16.0,
                  ),
                  decoration: const InputDecoration(
                    hintText: '000000',
                    hintStyle: TextStyle(color: Colors.grey, letterSpacing: 16.0),
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the OTP';
                    }
                    if (value.trim().length != 6) {
                      return 'OTP must be exactly 6 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Verify OTP',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 24),
                if (_isResending)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code?",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _resendOtp,
                        child: const Text('Resend Code'),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text(
                    'Verify Later',
                    style: TextStyle(color: Colors.grey[600], decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
