import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String email;
  final VoidCallback onTap;

  const UserTile({required this.email, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.person),
      title: Text(email),
      onTap: onTap,
      tileColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
    );
  }
}