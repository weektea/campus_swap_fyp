import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';

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

  void _submit() async {
      if (!_formKey.currentState!.validate()) return;
      
      if (_newPassController.text != _confirmPassController.text) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match')));
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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password Changed Successfully')));
              Navigator.pop(context);
          }
      } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                                child: _isLoading ? const CircularProgressIndicator() : const Text('Update Password'),
                            ),
                        )
                    ],
                ),
            ),
        ),
    );
  }
}
