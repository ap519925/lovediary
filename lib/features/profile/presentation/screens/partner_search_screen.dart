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
        SearchUsers(_searchController.text, widget.currentUserId)
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
            // Search by code or display name
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Enter partner code or display name',
                hintText: 'e.g. ABC123 or John Doe',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _searchUsers(),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: Searching by partner code is more accurate',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
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
                          title: Row(
                            children: [
                              Text(profile['displayName'] ?? 'No name'),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  user['userCode'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(profile['email'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_add),
                            onPressed: () => _sendRequest(user.id),
                          ),
                        );
                      },
                    ),
                  );
                }

                return const Center(child: Text('Search for partners'));
              },
            ),
          ],
        ),
      ),
    );
  }
}
