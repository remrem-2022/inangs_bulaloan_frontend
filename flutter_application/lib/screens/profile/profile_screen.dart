import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = AuthService.currentUser;
      if (user != null) {
        setState(() {
          // Parse username as first and last name if available
          final nameParts = user.username.split('_');
          if (nameParts.length >= 2) {
            _firstNameController.text = nameParts[0];
            _lastNameController.text = nameParts.sublist(1).join(' ');
          } else {
            _firstNameController.text = user.username;
          }
          // Email and password would need to be fetched from backend
          // For now, leaving them empty
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = <String, dynamic>{};

      if (_firstNameController.text.isNotEmpty) {
        data['firstName'] = _firstNameController.text.trim();
      }
      if (_lastNameController.text.isNotEmpty) {
        data['lastName'] = _lastNameController.text.trim();
      }
      if (_emailController.text.isNotEmpty) {
        data['email'] = _emailController.text.trim();
      }
      if (_passwordController.text.isNotEmpty) {
        data['password'] = _passwordController.text;
      }

      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes to save')),
        );
        return;
      }

      // Note: The backend needs to implement a profile update endpoint
      // For now, this is a placeholder
      final response = await ApiService.put(
        '${ApiConfig.baseUrl}/auth/profile',
        data,
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          _passwordController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to update profile')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROFILE',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 32),

                    // User Info (read-only)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow('Username:', user?.username ?? ''),
                            const SizedBox(height: 8),
                            _InfoRow('Role:', user?.role.toUpperCase() ?? ''),
                            const SizedBox(height: 8),
                            _InfoRow('Store:', user?.storeName ?? 'N/A'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // First Name
                    Text(
                      'FIRST NAME',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 400,
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Last Name
                    Text(
                      'LAST NAME',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 400,
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email Address
                    Text(
                      'EMAIL ADDRESS',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 400,
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Password
                    Text(
                      'PASSWORD',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 400,
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          hintText: 'Leave blank to keep current password',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('SAVE PROFILE'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Text(value),
      ],
    );
  }
}
