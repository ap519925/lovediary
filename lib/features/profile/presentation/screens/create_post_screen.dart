import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lovediary/features/profile/presentation/bloc/profile_bloc.dart';

class CreatePostScreen extends StatefulWidget {
  static const routeName = '/create-post';
  final String userId;

  const CreatePostScreen({
    super.key,
    required this.userId,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _isUploading = true;
        });
        
        context.read<ProfileBloc>().add(
          UploadPostImage(widget.userId, image)
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

  void _createPost() {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some content for your post'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }

    context.read<ProfileBloc>().add(
      CreatePost(
        widget.userId,
        _contentController.text,
        imageUrl: _imageUrl,
      )
    );

    // Navigate back to profile screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _createPost,
            tooltip: 'Post',
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
            setState(() {
              _isUploading = false;
            });
          }
          
          if (state is PostImageUploaded) {
            setState(() {
              _imageUrl = state.imageUrl;
              _isUploading = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image uploaded successfully'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              )
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content Field
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: "What's on your mind?",
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              
              const SizedBox(height: 16),
              
              // Image Preview
              if (_imageUrl != null)
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(_imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _imageUrl = null;
                            });
                          },
                          tooltip: 'Remove Image',
                        ),
                      ),
                    ),
                  ],
                )
              else if (_isUploading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Uploading image...'),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Add Image Button
              if (_imageUrl == null && !_isUploading)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Add Image'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _pickImage,
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Post Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createPost,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Post'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
