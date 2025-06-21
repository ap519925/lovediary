import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lovediary/features/profile/presentation/bloc/profile_bloc.dart';

class PartnerSearchScreen extends StatefulWidget {
  static const routeName = '/partner-search';
  final String currentUserId;
  const PartnerSearchScreen({super.key, required this.currentUserId});

  @override
  State<PartnerSearchScreen> createState() => _PartnerSearchScreenState();
}

class _PartnerSearchScreenState extends State<PartnerSearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchUsers() {
    if (_searchController.text.isNotEmpty) {
      context.read<ProfileBloc>().add(
        SearchUsersById(_searchController.text, widget.currentUserId)
      );
    }
  }

  void _sendRequest(String partnerId) {
    context.read<ProfileBloc>().add(
      SendRelationshipRequest(widget.currentUserId, partnerId)
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request sent successfully'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Partner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by User ID', // Changed label
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
              ),
              onSubmitted: (_) => _searchUsers(),
            ),
            const SizedBox(height: 20),
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                if (state is ProfileSearching) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ProfileSearchResults) {
                  return Expanded(
                    child: ListView.builder(
                      itemCount: state.results.length,
                      itemBuilder: (context, index) {
                        final user = state.results[index];
                        final profile = user['profile'] ?? {};
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: profile['avatarUrl'] != null
                                ? NetworkImage(profile['avatarUrl'])
                                : null,
                            child: profile['avatarUrl'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(profile['displayName'] ?? 'No name'),
                          subtitle: Text('ID: ${user['id']}'), // Display user ID
                          trailing: IconButton(
                            icon: const Icon(Icons.person_add),
                            onPressed: () => _sendRequest(user.id),
                          ),
                        );
                      },
                    ),
                  );
                }

                if (state is ProfileSearchError) {
                  return Center(child: Text('Error: ${state.message}'));
                }

                return const Center(child: Text('Enter a User ID to search for partners'));
              },
            ),
          ],
        ),
      ),
    );
  }
}
