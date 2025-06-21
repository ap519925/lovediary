import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lovediary/features/profile/presentation/bloc/profile_bloc.dart';

class PartnerLinkScreen extends StatefulWidget {
  static const routeName = '/partner-link';
  final String userId;
  const PartnerLinkScreen({super.key, required this.userId});

  @override
  State<PartnerLinkScreen> createState() => _PartnerLinkScreenState();
}

class _PartnerLinkScreenState extends State<PartnerLinkScreen> {

  @override
  void initState() {
    super.initState();
    // Load pending relationship requests when the screen initializes
    context.read<ProfileBloc>().add(LoadRelationshipRequests(widget.userId));
  }

  void _acceptRequest(String requestId) {
    context.read<ProfileBloc>().add(
      AcceptRelationshipRequest(widget.userId, requestId)
    );
  }

  void _declineRequest(String requestId) {
    context.read<ProfileBloc>().add(
      DeclineRelationshipRequest(widget.userId, requestId)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partner Requests')),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is RelationshipRequestAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Relationship request accepted!'))
            );
            // Reload requests after acceptance to update the list
            context.read<ProfileBloc>().add(LoadRelationshipRequests(widget.userId));
          } else if (state is RelationshipRequestDeclined) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Relationship request declined.'))
            );
            // Reload requests after decline to update the list
            context.read<ProfileBloc>().add(LoadRelationshipRequests(widget.userId));
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}'))
            );
          }
        },
        builder: (context, state) {
          if (state is RelationshipRequestLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RelationshipRequestsLoaded) {
            if (state.requests.isEmpty) {
              return const Center(child: Text('No pending partner requests.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: state.requests.length,
              itemBuilder: (context, index) {
                final request = state.requests[index];
                final fromUserId = request['fromUserId'];
                final requestId = request.id;

                // You might want to fetch more user details here later
                // For now, just display the sender's user ID
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request from: $fromUserId',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _declineRequest(requestId),
                              child: const Text('Decline', style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => _acceptRequest(requestId),
                              child: const Text('Accept'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          if (state is NoRelationshipRequests) {
            return const Center(child: Text('No pending partner requests.'));
          }

          // Default case or initial state without requests loaded yet
          return const Center(child: Text('Load your partner requests.'));
        },
      ),
    );
  }
}
