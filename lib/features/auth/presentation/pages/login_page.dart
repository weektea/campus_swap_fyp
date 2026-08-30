import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/features/home/presentation/pages/home_page.dart';
import 'package:campus_swap/features/auth/presentation/pages/register_page.dart';
import 'package:campus_swap/features/auth/presentation/pages/onboarding_page.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_swap/core/services/socket_service.dart';
import 'package:campus_swap/core/services/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:campus_swap/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/terms_guidelines_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

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
  bool _agreedToTerms = false;


  @override
  void initState() {
    super.initState();
    _loadUserCredentials();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    
    String studentId = '';
    String password = '';
    
    if (rememberMe) {
      studentId = prefs.getString('student_id') ?? '';
      password = prefs.getString('password') ?? '';
    }

    if (mounted) {
      setState(() {
        _rememberMe = rememberMe;
        if (rememberMe) {
          _studentIdController.text = studentId;
          _passwordController.text = password;
        }
      });

      final autoLogin = prefs.getBool('auto_login') ?? false;
      if (rememberMe && autoLogin && studentId.isNotEmpty && password.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _login();
          }
        });
      }
    }
  }

  Future<void> _saveUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('student_id', _studentIdController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setBool('auto_login', true);
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('student_id');
      await prefs.remove('password');
      await prefs.remove('auto_login');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getFriendlyErrorMessage(dynamic e) {
    final message = e.toString();
    if (message.contains('SocketException') || message.contains('Connection error') || message.contains('Failed host lookup')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (message.contains('TimeoutException') || message.contains('Connection timed out')) {
      return 'Connection timed out. Please check your network and try again.';
    }
    if (message.contains('API Error: 401') || message.contains('Invalid student ID or password') || message.contains('Invalid credentials')) {
      return 'Incorrect Student ID or Password. Please try again.';
    }
    return message.replaceAll(RegExp(r'^Exception:\s*'), '').replaceAll(RegExp(r'^ApiException:\s*'), '');
  }

  void _login() async {
    if (!_agreedToTerms) {
      _showErrorSnackBar(context, 'Please read and agree to the Terms & Policy to continue.');
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await _saveUserCredentials(); // Save credentials if checked

      try {
        final apiClient = ApiClient();
        final response = await apiClient.post('/auth/login', {
          'student_id': _studentIdController.text,
          'password': _passwordController.text,
        });

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

        // Persist token and user data for auto-login
        await session.saveToStorage();

        // Clear local notification cache for new account
        await NotificationService().clearLocalCache();

        // Initialize real-time WebSocket connection
        SocketService().init();

        if (mounted) {
          if (!isOnboarded) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        }
      } catch (e) {
        final isNetworkError = e.toString().contains('SocketException') || 
                               e.toString().contains('Connection error') || 
                               e.toString().contains('Failed host lookup') ||
                               e.toString().contains('TimeoutException');
        if (!isNetworkError) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('auto_login', false);
        }

        if (mounted) {
          if (e is ApiException && e.responseData?['errorCode'] == 'ACCOUNT_DEACTIVATED') {
            _showReactivateDialog(e.responseData?['token']);
          } else if (e is ApiException && e.responseData?['errorCode'] == 'EMAIL_NOT_VERIFIED') {
            _showEmailVerificationDialog(e.responseData?['email'] ?? _studentIdController.text);
          } else if (e is ApiException && (e.message == 'Account Suspended' || e.responseData?['errorCode'] == 'ACCOUNT_SUSPENDED')) {
            _showSuspendedBottomSheet(e.responseData, e.responseData?['token']);
          } else {
            _showErrorSnackBar(context, 'Login Failed: ${_getFriendlyErrorMessage(e)}');
          }
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showEmailVerificationDialog(String email) {
    final otpInputController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isResending = false;
        bool isVerifying = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.mark_email_unread_rounded, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Email Verification'),
                ],
              ),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your email address is not verified yet. Please enter the OTP verification code below.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Email: $email',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: otpInputController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8.0,
                      ),
                      decoration: const InputDecoration(
                        hintText: '000000',
                        hintStyle: TextStyle(color: Colors.grey, letterSpacing: 8.0),
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter OTP';
                        }
                        if (value.trim().length != 6) {
                          return 'Must be 6 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (isResending)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (isVerifying)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      const Text(
                        'If you did not receive the code, click Resend Code.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              actions: (isResending || isVerifying)
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          setDialogState(() => isResending = true);
                          try {
                            final apiClient = ApiClient();
                            await apiClient.post('/auth/resend-otp', {'email': email});
                            if (context.mounted) {
                              _showSuccessSnackBar(context, 'Verification email resent successfully.');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              _showErrorSnackBar(context, 'Failed to resend: ${_getFriendlyErrorMessage(e)}');
                            }
                          } finally {
                            setDialogState(() => isResending = false);
                          }
                        },
                        child: const Text('Resend Code'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (dialogFormKey.currentState!.validate()) {
                            setDialogState(() => isVerifying = true);
                            try {
                              final apiClient = ApiClient();
                              await apiClient.post('/auth/verify-otp', {
                                'email': email,
                                'otp': otpInputController.text.trim()
                              });
                              if (context.mounted) {
                                Navigator.pop(context); // Close dialog
                                _showSuccessSnackBar(context, 'Email verified successfully! You can now log in.');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                _showErrorSnackBar(context, 'Verification Failed: ${_getFriendlyErrorMessage(e)}');
                              }
                            } finally {
                              setDialogState(() => isVerifying = false);
                            }
                          }
                        },
                        child: const Text('Verify'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  void _showSuspendedBottomSheet(Map<String, dynamic>? data, String? appealToken) {
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
                    _showAppealDialog(appealToken);
                  },
                  child: const Text('Contact Support & Appeal', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _showAppealDialog(String? appealToken) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Submit Suspension Appeal'),
              content: isSubmitting
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Submitting your appeal...', style: GoogleFonts.outfit()),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Provide details for your appeal. The administrators will review it as soon as possible.',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: controller,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Appeal Reason',
                            hintText: 'Describe why your account should be reactivated...',
                          ),
                        ),
                      ],
                    ),
              actions: isSubmitting
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (controller.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter an appeal reason')),
                            );
                            return;
                          }
                          setDialogState(() => isSubmitting = true);
                          try {
                            final apiClient = ApiClient();
                            
                            // Temporarily set token in UserSession so the ApiClient sends it in headers
                            final originalToken = UserSession().token;
                            UserSession().token = appealToken;

                            await apiClient.post('/auth/appeal', {
                              'description': controller.text.trim(),
                              'type': 'SUSPENSION_APPEAL'
                            });

                            // Restore token
                            UserSession().token = originalToken;

                            if (context.mounted) {
                              Navigator.pop(context); // Close dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Appeal submitted successfully. Check back later!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setDialogState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Appeal submission failed: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Submit Appeal'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  void _showReactivateDialog(String? reactivationToken) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isReactivating = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Account Deactivated'),
              content: isReactivating 
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Reactivating your account...', style: GoogleFonts.outfit()),
                      ],
                    )
                  : const Text('Your account is currently deactivated. Would you like to reactivate it and restore your profile?'),
              actions: isReactivating 
                  ? [] 
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          setDialogState(() => isReactivating = true);
                          final originalToken = UserSession().token;
                          try {
                            final apiClient = ApiClient();
                            
                            // Temporarily set token in UserSession so the ApiClient sends it in headers
                            UserSession().token = reactivationToken;
                            
                            final reactivateResponse = await apiClient.put('/auth/users/reactivate', {});
                            
                            // Save new login credentials to session
                            UserSession().token = reactivateResponse['token'] ?? reactivationToken;
                            UserSession().userId = reactivateResponse['user']['id'];
                            UserSession().email = reactivateResponse['user']['email'];
                            UserSession().username = reactivateResponse['user']['username'];
                            UserSession().fullName = reactivateResponse['user']['full_name'];
                            UserSession().avatarUrl = reactivateResponse['user']['profile_picture'];
                            UserSession().role = reactivateResponse['user']['role'];
                            await UserSession().saveToStorage();
                            
                            // Initialize dynamic real-time WebSocket connection
                            SocketService().init();
                            
                            if (context.mounted) {
                              Navigator.pop(context); // Close dialog
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const HomePage()),
                              );
                              _showSuccessSnackBar(context, 'Account reactivated successfully. Welcome back!');
                            }
                          } catch (e) {
                            UserSession().token = originalToken;
                            if (context.mounted) {
                              setDialogState(() => isReactivating = false);
                              _showErrorSnackBar(context, 'Reactivation failed: ${_getFriendlyErrorMessage(e)}');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Yes, Reactivate'),
                      ),
                    ],
            );
          },
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      activeColor: Theme.of(context).colorScheme.primary,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                    ),
                                    Text('Remember Me', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage()));
                                  },
                                  child: const Text('Forgot Password?'),
                                ),
                              ],
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 22,
                            width: 22,
                            child: Checkbox(
                              value: _agreedToTerms,
                              activeColor: Theme.of(context).colorScheme.primary,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (value) {
                                setState(() {
                                  _agreedToTerms = value ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const TermsGuidelinesPage()),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[700]),
                                  children: [
                                    const TextSpan(text: 'I have read & agree to the '),
                                    TextSpan(
                                      text: 'Terms & Conditions',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
