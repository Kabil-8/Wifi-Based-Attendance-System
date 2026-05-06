import 'package:flutter/material.dart';
import '../../config/routes.dart';

class SelectRoleScreen extends StatelessWidget {
  SelectRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(
                    context, Routes.studentDashboard);
              },
              child: const Text('Student'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(
                    context, Routes.staffDashboard);
              },
              child: const Text('Staff'),
            ),
          ],
        ),
      ),
    );
  }
}
