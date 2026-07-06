import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';


class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
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
      if (!_formKey.currentState!.validate()) return;
      
      if (_newPassController.text != _confirmPassController.text) {
          _showErrorSnackBar(context, 'New passwords do not match');
          return;
      }

      setState(() => _isLoading = true);

      try {
          final apiClient = ApiClient();
          await apiClient.post('/auth/change-password', {
              'old_password': _oldPassController.text,
              'new_password': _newPassController.text
          });

          if (mounted) {
              _showSuccessSnackBar(context, 'Password changed successfully!');
              Navigator.pop(context);
          }
      } catch (e) {
          if (mounted) _showErrorSnackBar(context, 'Change password failed: ${_getFriendlyErrorMessage(e)}');
      } finally {
          if (mounted) setState(() => _isLoading = false);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Change Password')),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
                key: _formKey,
                child: Column(
                    children: [
                        TextFormField(
                            controller: _oldPassController,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Old Password', border: OutlineInputBorder()),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: _newPassController,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                            validator: (v) => v!.length < 8 ? 'Min 8 characters' : null,
                        ),
                         const SizedBox(height: 16),
                        TextFormField(
                            controller: _confirmPassController,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Confirm New Password', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 24),
                         SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                child: _isLoading 
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                    : const Text('Update Password'),
                            ),
                        )
                    ],
                ),
            ),
        ),
    );
  }
}
