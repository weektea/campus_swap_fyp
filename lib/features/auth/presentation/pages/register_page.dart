import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:campus_swap/core/api/api_client.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _universityIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController(); 
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Timer? _usernameDebounce;
  bool _isCheckingUsername = false;
  bool _isUsernameValid = false;
  String? _usernameFeedback;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _universityIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String val) {
    if (_usernameDebounce?.isActive ?? false) _usernameDebounce!.cancel();

    if (val.trim().length < 3) {
      setState(() {
        _isUsernameValid = false;
        _usernameFeedback = 'Username must be at least 3 characters';
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameFeedback = null;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final client = ApiClient();
        final res = await client.get('/auth/check-username?username=${Uri.encodeComponent(val.trim())}');
        
        if (mounted) {
          setState(() {
            _isCheckingUsername = false;
            _isUsernameValid = res['available'] ?? false;
            _usernameFeedback = res['available'] == true 
                ? 'Username is available' 
                : (res['error'] ?? 'Username already taken');
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isCheckingUsername = false;
            _isUsernameValid = false;
            _usernameFeedback = 'Could not verify username';
          });
        }
      }
    });
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
    return message.replaceAll(RegExp(r'^Exception:\s*'), '').replaceAll(RegExp(r'^ApiException:\s*'), '');
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorSnackBar(context, 'Passwords do not match');
        return;
      }

      setState(() => _isLoading = true);

      try {
        final apiClient = ApiClient();
        await apiClient.post('/auth/register', {
          'username': _usernameController.text.toLowerCase().trim(),
          'full_name': _fullNameController.text.trim(),
          'university_id': _universityIdController.text.toUpperCase(),
          'email': _emailController.text,
          'password': _passwordController.text,
          'phone_number': '+60${_phoneController.text}',
        });

        if (mounted) {
          _showSuccessSnackBar(context, 'Registration Successful! Please Login.');
          Navigator.pop(context); // Go back to login
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar(context, 'Registration Failed: ${_getFriendlyErrorMessage(e)}');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  hintText: 'e.g., Zhang Xiao Ming',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Tooltip(
                        message: 'Please use your real name as it will be verified against your university ID.',
                        triggerMode: TooltipTriggerMode.tap,
                        child: Icon(Icons.info_outline, size: 20),
                      ),
                      SizedBox(width: 12),
                    ],
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 2 || v.trim().length > 50) {
                    return 'Must be between 2 and 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _usernameController,
                onChanged: _onUsernameChanged,
                decoration: InputDecoration(
                  labelText: 'Username (Unique ID)', 
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Tooltip(
                        message: 'Used for your profile link and tagging. Letters, numbers, and underscores only. Cannot be changed later.',
                        triggerMode: TooltipTriggerMode.tap,
                        child: Icon(Icons.info_outline, size: 20),
                      ),
                      if (_isCheckingUsername)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0, right: 12.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_usernameFeedback != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 12.0),
                          child: Icon(
                            _isUsernameValid ? Icons.check_circle : Icons.cancel,
                            color: _isUsernameValid ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        )
                      else
                        const SizedBox(width: 12),
                    ],
                  ),
                  helperText: _isUsernameValid && _usernameFeedback != null ? _usernameFeedback : null,
                  helperStyle: const TextStyle(color: Colors.green),
                  errorText: !_isUsernameValid && _usernameFeedback != null ? _usernameFeedback : null,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!_isUsernameValid) return _usernameFeedback ?? 'Username is not available';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _universityIdController,
                decoration: const InputDecoration(
                  labelText: 'University ID (e.g. 24PMR01234)', 
                  prefixIcon: Icon(Icons.badge_outlined),
                  hintText: 'YYAAAXXXXX'
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!RegExp(r'^\d{2}[a-zA-Z]{3}\d{5}$').hasMatch(v)) {
                    return 'Invalid format. Use YYAAAXXXXX (e.g. 24PMR01234)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number', 
                    prefixIcon: Icon(Icons.phone_outlined),
                    prefixText: '+60 ', // Fixed prefix
                    hintText: '1x-xxxxxxx'
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                    _PhoneInputFormatter(),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    // Validate: 2 digits, hyphen, 7-8 digits. e.g. 16-1234567
                    if (!RegExp(r'^\d{2}-\d{7,8}$').hasMatch(v)) {
                      return 'Enter like: 16-1234567';
                    }
                    return null;
                  },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Student Email (@edu.my)', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!v.endsWith('.edu.my')) return 'Must be .edu.my email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible, // Controlled by state
                decoration: InputDecoration(
                  labelText: 'Password', 
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: GestureDetector(
                    onTapDown: (_) => setState(() => _isPasswordVisible = true),
                    onTapUp: (_) => setState(() => _isPasswordVisible = false),
                    onTapCancel: () => setState(() => _isPasswordVisible = false),
                    child: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                validator: (v) { 
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 8) return 'Min 8 characters';
                  if (!RegExp(r'(?=.*[A-Z])').hasMatch(v)) return 'Need uppercase letter';
                  if (!RegExp(r'(?=.*[a-z])').hasMatch(v)) return 'Need lowercase letter';
                  if (!RegExp(r'(?=.*[0-9])').hasMatch(v)) return 'Need number';
                  if (!RegExp(r'(?=.*[\W_])').hasMatch(v)) return 'Need symbol (!@#)';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password', 
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: GestureDetector(
                    onTapDown: (_) => setState(() => _isConfirmPasswordVisible = true),
                    onTapUp: (_) => setState(() => _isConfirmPasswordVisible = false),
                    onTapCancel: () => setState(() => _isConfirmPasswordVisible = false),
                    child: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Formatter to auto-insert dash after 2nd digit
class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    
    // If deleting, don't force formatting to strictly avoid fighting the user
    if (newValue.selection.baseOffset < oldValue.selection.baseOffset) {
      return newValue;
    }

    // Remove any existing dash to re-process
    var digitsOnly = text.replaceAll('-', '');
    var buffer = StringBuffer();
    
    for (int i = 0; i < digitsOnly.length; i++) {
        buffer.write(digitsOnly[i]);
        // Insert dash after 2nd digit
        if (i == 1) {
            buffer.write('-');
        }
    }

    var newText = buffer.toString();
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length), // simple cursor logic usually fine for append
    );
  }
}
