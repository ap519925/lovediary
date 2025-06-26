import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lovediary/features/profile/presentation/bloc/profile_bloc.dart';

class EditProfileScreen extends StatefulWidget {
  static const routeName = '/edit-profile';
  final String userId;
  final Map<String, dynamic> initialProfile;

  const EditProfileScreen({
    super.key, 
    required this.userId,
    required this.initialProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _displayNameController;
  late TextEditingController _genderController;
  late TextEditingController _bioController;
  late TextEditingController _birthdayController;
  late TextEditingController _locationController;
  
  DateTime? _anniversaryDate;
  DateTime? _nextMeetingDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile['name'] ?? '');
    _displayNameController = TextEditingController(text: widget.initialProfile['displayName'] ?? '');
    _genderController = TextEditingController(text: widget.initialProfile['gender'] ?? '');
    _bioController = TextEditingController(text: widget.initialProfile['bio'] ?? '');
    _birthdayController = TextEditingController(text: widget.initialProfile['birthday'] ?? '');
    _locationController = TextEditingController(text: widget.initialProfile['location'] ?? '');
    
    // Parse dates from milliseconds
    if (widget.initialProfile['anniversaryDate'] != null) {
      final timestamp = widget.initialProfile['anniversaryDate'];
      if (timestamp is int) {
        _anniversaryDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }
    
    if (widget.initialProfile['nextMeetingDate'] != null) {
      final timestamp = widget.initialProfile['nextMeetingDate'];
      if (timestamp is int) {
        _nextMeetingDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _genderController.dispose();
    _bioController.dispose();
    _birthdayController.dispose();
    _locationController.dispose();
    super.dispose();
  }
  
  // Format date to display in text field
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.day}/${date.year}';
  }
  
  // Show date picker
  Future<DateTime?> _selectDate(BuildContext context, DateTime? initialDate) async {
    final DateTime now = DateTime.now();
    final DateTime initialDateTime = initialDate ?? now;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    
    return picked;
  }

  Future<void> _pickImage(String imageType) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: imageType == 'avatar' ? 300 : 1200,
        maxHeight: imageType == 'avatar' ? 300 : 400,
        imageQuality: 85,
      );
      if (image != null) {
        context.read<ProfileBloc>().add(
          UploadProfileImage(widget.userId, imageType, image)
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        )
      );
    }
  }

  void _updateProfile() {
    if (_formKey.currentState!.validate()) {
      try {
        final updates = {
          'name': _nameController.text,
          'displayName': _displayNameController.text,
          'gender': _genderController.text,
          'bio': _bioController.text,
          'birthday': _birthdayController.text,
          'location': _locationController.text,
          'anniversaryDate': _anniversaryDate?.millisecondsSinceEpoch,
          'nextMeetingDate': _nextMeetingDate?.millisecondsSinceEpoch,
        };
        
        // Remove null values
        updates.removeWhere((key, value) => value == null);
        
        context.read<ProfileBloc>().add(
          UpdateProfile(widget.userId, updates)
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'))
        );
        
        // Navigate back to profile screen
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateProfile,
            tooltip: 'Save',
          ),
        ],
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              )
            );
          }
          
          if (state is ProfileImageUploaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploaded successfully'))
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture and Banner Section
                Center(
                  child: Column(
                    children: [
                      // Banner Image
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                              image: widget.initialProfile['bannerUrl'] != null
                                ? DecorationImage(
                                    image: NetworkImage(widget.initialProfile['bannerUrl']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            ),
                            child: widget.initialProfile['bannerUrl'] == null
                                ? const Center(child: Text('No Banner Image'))
                                : null,
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white),
                                onPressed: () => _pickImage('banner'),
                                tooltip: 'Change Banner',
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Profile Picture
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[700],
                            backgroundImage: widget.initialProfile['avatarUrl'] != null
                                ? NetworkImage(widget.initialProfile['avatarUrl'])
                                : null,
                            child: widget.initialProfile['avatarUrl'] == null
                                ? const Icon(Icons.person, size: 60, color: Colors.white)
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white),
                                onPressed: () => _pickImage('avatar'),
                                tooltip: 'Change Profile Picture',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                const Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Display Name Field
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a display name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Gender Field
                TextFormField(
                  controller: _genderController,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Bio Field
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 16),
                
                // Birthday Field
                TextFormField(
                  controller: _birthdayController,
                  decoration: const InputDecoration(
                    labelText: 'Birthday (MM/DD/YYYY)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 01/15/1990',
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Location Field
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Current Location',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. New York, USA',
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Anniversary Date Field
                InkWell(
                  onTap: () async {
                    final picked = await _selectDate(context, _anniversaryDate);
                    if (picked != null) {
                      setState(() {
                        _anniversaryDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Anniversary Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _anniversaryDate != null 
                          ? _formatDate(_anniversaryDate)
                          : 'Select Date',
                      style: TextStyle(
                        color: _anniversaryDate != null 
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Next Meeting Date Field
                InkWell(
                  onTap: () async {
                    final picked = await _selectDate(context, _nextMeetingDate);
                    if (picked != null) {
                      setState(() {
                        _nextMeetingDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Next Meeting Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _nextMeetingDate != null 
                          ? _formatDate(_nextMeetingDate)
                          : 'Select Date',
                      style: TextStyle(
                        color: _nextMeetingDate != null 
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Save Profile'),
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
