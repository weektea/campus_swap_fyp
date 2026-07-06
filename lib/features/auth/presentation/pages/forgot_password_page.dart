import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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

  void _submit() async {
    if (_emailController.text.isEmpty) {
        _showErrorSnackBar(context, 'Please enter email');
        return;
    }

    setState(() => _isLoading = true);

    try {
        final apiClient = ApiClient();
        final res = await apiClient.post('/auth/forgot-password', {'email': _emailController.text});
        
        if (mounted) {
            _showSuccessSnackBar(context, res['message'] ?? 'Request sent');
            Navigator.pop(context);
        }
    } catch (e) {
        if (mounted) _showErrorSnackBar(context, 'Reset request failed: ${_getFriendlyErrorMessage(e)}');
    } finally {
        if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Reset Password')),
        body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                children: [
                    const Text('Enter your student email to receive a password reset link.'),
                    const SizedBox(height: 16),
                    TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading ? const CircularProgressIndicator() : const Text('Send Reset Link'),
                        ),
                    )
                ],
            ),
        ),
    );
  }
}
