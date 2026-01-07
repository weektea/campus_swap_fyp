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

  void _submit() async {
    if (_emailController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email')));
        return;
    }

    setState(() => _isLoading = true);

    try {
        final apiClient = ApiClient();
        final res = await apiClient.post('/auth/forgot-password', {'email': _emailController.text});
        
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Request sent')));
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
