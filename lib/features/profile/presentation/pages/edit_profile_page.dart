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
  final _facultyController = TextEditingController();
  final _yearController = TextEditingController();
  final _bioController = TextEditingController();
  final _studentIdController = TextEditingController();
  String _privacySetting = 'Public';
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _facultyController.dispose();
    _yearController.dispose();
    _bioController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      final res = await apiClient.get('/auth/user/${UserSession().userId}');
      if (res != null && res['user'] != null) {
        final userData = res['user'];
        _facultyController.text = userData['faculty'] ?? '';
        _yearController.text = userData['year_of_study']?.toString() ?? '';
        _bioController.text = userData['bio'] ?? '';
        _studentIdController.text = userData['university_id'] ?? '';
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
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar Updated!')));
          }
      } catch (e) {
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Failed: $e')));
              setState(() => _isUploading = false);
          }
      }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      await apiClient.patch('/auth/user/${UserSession().userId}', {
        'faculty': _facultyController.text,
        'year_of_study': int.tryParse(_yearController.text),
        'bio': _bioController.text,
        'privacy_setting': _privacySetting,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
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
                    controller: _facultyController,
                    decoration: InputDecoration(
                        labelText: 'Faculty',
                        hintText: 'e.g. FTMK, FKE, FSPU',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Public', 'Private'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _privacySetting = val);
                    },
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
