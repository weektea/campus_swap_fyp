import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _yearController = TextEditingController();
  final _bioController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  String _privacySetting = 'Public';
  String _primaryIntent = 'browse';
  List<String> _preferenceTags = [];
  bool _isLoading = false;
  bool _isUploading = false;

  final List<String> _availableCategories = [
    'Electronics & Gadgets',
    'Textbooks & Books',
    'Fashion & Apparel',
    'Furniture & Dorm',
    'Sports & Outdoor',
    'Stationery & Art',
    'Games & Consoles',
    'FCI Special',
    'Year 1 Essentials',
    'Transport & Bikes',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _yearController.dispose();
    _bioController.dispose();
    _studentIdController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      final res = await apiClient.get('/auth/user/${UserSession().userId}');
      if (res != null && res['user'] != null) {
        final userData = res['user'];
        _yearController.text = userData['year_of_study']?.toString() ?? '';
        _bioController.text = userData['bio'] ?? '';
        _studentIdController.text = userData['university_id'] ?? '';
        _usernameController.text = userData['username'] ?? '';
        _fullNameController.text = userData['full_name'] ?? '';
        _primaryIntent = userData['primary_intent'] ?? 'browse';
        _preferenceTags = List<String>.from(userData['preference_tags'] ?? []);
        if (userData['privacy_setting'] != null) {
          _privacySetting = userData['privacy_setting'];
          if (_privacySetting == 'Friends Only') {
            _privacySetting = 'Public';
          }
        }
      }
    } catch (e) {
      // Ignore
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile == null) return;

      setState(() => _isUploading = true);
      final session = UserSession();

      try {
          final apiClient = ApiClient();
          // 1. Upload Image
          final uploadRes = await apiClient.postMultipart('/upload', pickedFile);
          final imageUrl = uploadRes['url']; 

          // 2. Update User Profile
          await apiClient.patch('/auth/user/${session.userId}', {'profile_picture': imageUrl});

          // 3. Update Local Session
          setState(() {
              session.avatarUrl = imageUrl;
              _isUploading = false;
          });
          if (mounted) {
             _showSuccessSnackBar(context, 'Avatar Updated!');
          }
      } catch (e) {
          if (mounted) {
              _showErrorSnackBar(context, 'Upload Failed: ${_getFriendlyErrorMessage(e)}');
              setState(() => _isUploading = false);
          }
      }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
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

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      await apiClient.patch('/auth/user/${UserSession().userId}', {
        'year_of_study': int.tryParse(_yearController.text),
        'bio': _bioController.text,
        'privacy_setting': _privacySetting,
        'primary_intent': _primaryIntent,
        'preference_tags': _preferenceTags,
      });
      UserSession().primaryIntent = _primaryIntent;
      UserSession().preferenceTags = List<String>.from(_preferenceTags);
      if (mounted) {
        _showSuccessSnackBar(context, 'Profile updated successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Update failed: ${_getFriendlyErrorMessage(e)}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular Avatar Placeholder at the Top
                  Center(
                    child: GestureDetector(
                      onTap: _pickAndUploadAvatar,
                      child: Stack(
                        children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.teal,
                              backgroundImage: UserSession().avatarUrl != null 
                                  ? NetworkImage('${ApiClient.baseUrl.replaceAll('/api', '')}${UserSession().avatarUrl}') 
                                  : null,
                              child: _isUploading 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : (UserSession().avatarUrl == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null),
                            ),
                            Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.grey),
                                ),
                            )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text("Academic Info", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  const SizedBox(height: 16),
                  
                  // Full Name Field (Immutable once set)
                  TextFormField(
                    controller: _fullNameController,
                    enabled: false,
                    decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.person, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Username Field (Immutable once set)
                  TextFormField(
                    controller: _usernameController,
                    enabled: false,
                    decoration: InputDecoration(
                        labelText: 'Username (Unique ID)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.alternate_email, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Username and Full Name are permanent for account security and cannot be changed.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Read-Only Student ID Field
                  TextFormField(
                    controller: _studentIdController,
                    enabled: false,
                    decoration: InputDecoration(
                        labelText: 'Student ID',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.badge_outlined, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  

                  TextFormField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'Year of Study (1-4)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text("About Me", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    maxLength: 150,
                    decoration: InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell others about what you usually sell / buy...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _privacySetting,
                    decoration: InputDecoration(
                      labelText: 'Profile Privacy',
                      helperText: 'Controls visibility of Email, Faculty, and Year of Study.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Public', 'Private'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _privacySetting = val);
                    },
                  ),
                  const SizedBox(height: 32),
                  Text("Looking For (Interests)", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text("Select interest categories to calibrate your ML recommendation feed:", style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableCategories.map((cat) {
                      final isSelected = _preferenceTags.contains(cat);
                      return FilterChip(
                        label: Text(cat, style: GoogleFonts.outfit(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              if (!_preferenceTags.contains(cat)) _preferenceTags.add(cat);
                            } else {
                              _preferenceTags.remove(cat);
                            }
                          });
                        },
                        selectedColor: const Color(0xFF005A43),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Save Changes', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
