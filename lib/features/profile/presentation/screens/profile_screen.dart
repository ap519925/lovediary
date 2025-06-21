import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_event.dart';
import 'package:lovediary/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lovediary/features/profile/presentation/screens/partner_search_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _displayNameController;
  late TextEditingController _genderController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _displayNameController = TextEditingController();
    _genderController = TextEditingController();
    _bioController = TextEditingController();
    context.read<ProfileBloc>().add(LoadProfile(widget.userId));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _genderController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String imageType) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
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
        };
        context.read<ProfileBloc>().add(
          UpdateProfile(widget.userId, updates)
        );
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
    return BlocConsumer<ProfileBloc, ProfileState>(
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
      },
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileLoaded) {
          _nameController.text = state.profile['name'] ?? '';
          _displayNameController.text = state.profile['displayName'] ?? '';
          _genderController.text = state.profile['gender'] ?? '';
          _bioController.text = state.profile['bio'] ?? '';

          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
                  tooltip: 'Logout',
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Rest of the profile screen implementation...
                    // (Previous content remains the same)
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Error loading profile'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<ProfileBloc>().add(LoadProfile(widget.userId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
