import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_event.dart';

class PartnerLinkScreen extends StatefulWidget {
  static const routeName = '/partner-link';
  final String userId;
  const PartnerLinkScreen({super.key, required this.userId});

  @override
  State<PartnerLinkScreen> createState() => _PartnerLinkScreenState();
}

class _PartnerLinkScreenState extends State<PartnerLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _partnerIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link Partner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _partnerIdController,
                decoration: const InputDecoration(
                  labelText: "Partner's User ID",
                  hintText: "Enter your partner's unique ID",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter partner ID';
                  }
                  if (value == widget.userId) {
                    return 'Cannot link to yourself';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<AuthBloc>().add(
                      LinkPartnerRequested(
                        userId: widget.userId,
                        partnerId: _partnerIdController.text,
                      ),
                    );
                  }
                },
                child: const Text('Link Partner'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _partnerIdController.dispose();
    super.dispose();
  }
}
