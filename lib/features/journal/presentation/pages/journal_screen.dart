import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Journal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book,
              size: 80,
              color: AppTheme.secondaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Personal Journal',
              style: AppTheme.heading2,
            ),
            SizedBox(height: 8),
            Text(
              'Coming Soon!',
              style: AppTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
