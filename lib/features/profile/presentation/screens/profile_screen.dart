import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_event.dart';
import 'package:lovediary/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lovediary/features/profile/presentation/screens/create_post_screen.dart';
import 'package:lovediary/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:lovediary/features/profile/presentation/screens/partner_search_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadProfileAndPosts();
  }
  
  void _loadProfileAndPosts() {
    context.read<ProfileBloc>().add(LoadProfile(widget.userId));
    context.read<ProfileBloc>().add(FetchPosts(widget.userId));
    context.read<ProfileBloc>().add(FetchRelationshipRequests(widget.userId));
  }
  
  void _navigateToEditProfile(Map<String, dynamic> profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userId: widget.userId,
          initialProfile: profile,
        ),
      ),
    ).then((_) => _loadProfileAndPosts());
  }
  
  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          userId: widget.userId,
        ),
      ),
    ).then((_) => _loadProfileAndPosts());
  }
  
  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }
  
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildPostCard(QueryDocumentSnapshot post) {
    final data = post.data() as Map<String, dynamic>;
    final content = data['content'] as String;
    final imageUrl = data['imageUrl'] as String?;
    final createdAt = data['createdAt'] as Timestamp?;
    final likes = data['likes'] as int? ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: (data['userProfileImage'] != null && (data['userProfileImage'] as String).isNotEmpty)
                      ? NetworkImage(data['userProfileImage'])
                      : null,
                  radius: 20,
                  child: (data['userProfileImage'] == null || (data['userProfileImage'] as String).isEmpty) 
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['userName'] ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        _formatTimestamp(createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Post Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(content),
          ),
          
          // Post Image
          if (imageUrl != null)
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          // Post Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {
                    // Like functionality would go here
                  },
                  tooltip: 'Like',
                ),
                Text('$likes'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () {
                    // Comment functionality would go here
                  },
                  tooltip: 'Comment',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipSection(ProfileState currentState) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        // Show relationship status if in a relationship
        if (currentState is ProfileLoaded && 
            currentState.profile['relationshipStatus'] == 'in_relationship' &&
            currentState.profile['partnerId'] != null) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.pink),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'In a relationship',
                        style: TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // View partner profile
                        // This would navigate to the partner's profile
                      },
                      child: const Text('View Partner'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }
        
        // Show relationship requests if any
        if (state is RelationshipRequestsLoaded) {
          return Column(
            children: [
              // Incoming requests
              if (state.incomingRequests.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Incoming Relationship Requests',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...state.incomingRequests.map((request) {
                        final data = request.data() as Map<String, dynamic>;
                        final fromUserId = data['fromUserId'] as String;
                        
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(fromUserId)
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const ListTile(
                                title: Text('Loading...'),
                              );
                            }
                            
                            final userData = snapshot.data!.data() as Map<String, dynamic>?;
                            final profile = userData?['profile'] as Map<String, dynamic>? ?? {};
                            final displayName = profile['displayName'] ?? 'Unknown User';
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: profile['avatarUrl'] != null
                                    ? NetworkImage(profile['avatarUrl'])
                                    : null,
                                child: profile['avatarUrl'] == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(displayName),
                              subtitle: Text('Wants to connect with you'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () {
                                      context.read<ProfileBloc>().add(
                                        AcceptRelationshipRequest(request.id),
                                      );
                                    },
                                    tooltip: 'Accept',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () {
                                      context.read<ProfileBloc>().add(
                                        RejectRelationshipRequest(request.id),
                                      );
                                    },
                                    tooltip: 'Reject',
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              
              // Outgoing requests
              if (state.outgoingRequests.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Outgoing Relationship Requests',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...state.outgoingRequests.map((request) {
                        final data = request.data() as Map<String, dynamic>;
                        final toUserId = data['toUserId'] as String;
                        
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(toUserId)
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const ListTile(
                                title: Text('Loading...'),
                              );
                            }
                            
                            final userData = snapshot.data!.data() as Map<String, dynamic>?;
                            final profile = userData?['profile'] as Map<String, dynamic>? ?? {};
                            final displayName = profile['displayName'] ?? 'Unknown User';
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: profile['avatarUrl'] != null
                                    ? NetworkImage(profile['avatarUrl'])
                                    : null,
                                child: profile['avatarUrl'] == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(displayName),
                              subtitle: Text('Request pending'),
                              trailing: const Icon(Icons.hourglass_empty),
                            );
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              
              // Find Partner Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_search),
                  label: const Text('Find Partner by Code'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PartnerSearchScreen(
                          currentUserId: widget.userId,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
        
        // Default: Show Find Partner Button
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.person_search),
            label: const Text('Find Partner by Code'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PartnerSearchScreen(
                    currentUserId: widget.userId,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPostsSection() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is PostsLoaded) {
          if (state.posts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No posts yet. Create your first post!',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          
          return Column(
            children: state.posts.map((post) => _buildPostCard(post)).toList(),
          );
        }
        
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  ProfileLoaded? _cachedProfileState;

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
        
        // Cache the ProfileLoaded state when we receive it
        if (state is ProfileLoaded) {
          _cachedProfileState = state;
        }
      },
      builder: (context, state) {
        print('ProfileScreen BlocBuilder state: $state'); // Debug log
        
        if (state is ProfileLoading && _cachedProfileState == null) {
          print('Showing loading indicator'); // Debug log
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileLoaded) {
          print('Profile loaded, showing profile UI'); // Debug log
          return _buildProfileUI(state);
        }
        
        // If we have a cached profile state, use it even if current state is different
        if (_cachedProfileState != null) {
          print('Using cached profile state'); // Debug log
          return _buildProfileUI(_cachedProfileState!);
        }

        // Fallback to loading
        print('Fallback to loading'); // Debug log
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildProfileUI(ProfileLoaded profileState) {
    return Scaffold(
      appBar: AppBar(
        title: Text(profileState.profile['displayName'] ?? 'Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditProfile(profileState.profile),
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        child: const Icon(Icons.add),
        tooltip: 'Create Post',
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadProfileAndPosts(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Banner Image
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      image: profileState.profile['bannerUrl'] != null
                        ? DecorationImage(
                            image: (profileState.profile['bannerUrl'] != null && profileState.profile['bannerUrl'].toString().isNotEmpty)
                            ? NetworkImage(profileState.profile['bannerUrl'])
                            : const AssetImage('assets/placeholder.png') as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                    ),
                  ),
                  
                  // Profile Picture
                  Positioned(
                    bottom: -50,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 4,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[700],
                        backgroundImage: (profileState.profile['avatarUrl'] != null && profileState.profile['avatarUrl'].toString().isNotEmpty)
                           ? NetworkImage(profileState.profile['avatarUrl'])
                           : null,
                        child: profileState.profile['avatarUrl'] == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 60),
              
              // Profile Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Display Name
                    Text(
                      profileState.profile['displayName'] ?? 'Anonymous',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    if (profileState.profile['bio'] != null && profileState.profile['bio'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          profileState.profile['bio'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // User Code
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tag, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            profileState.profile['userCode'] ?? 'No code',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Profile Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (profileState.profile['location'] != null && profileState.profile['location'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, size: 16),
                                const SizedBox(width: 4),
                                Text(profileState.profile['location']),
                              ],
                            ),
                          ),
                        
                        if (profileState.profile['birthday'] != null && profileState.profile['birthday'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.cake, size: 16),
                                const SizedBox(width: 4),
                                Text(profileState.profile['birthday']),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Relationship Section
                    _buildRelationshipSection(profileState),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Posts Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Posts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Posts Section
                    _buildPostsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
