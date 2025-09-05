import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Exercises'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: AppTheme.successColor,
            ),
            SizedBox(height: 16),
            Text(
              'Exercise Library',
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
