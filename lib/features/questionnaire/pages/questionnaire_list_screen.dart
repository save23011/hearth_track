import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class QuestionnaireListScreen extends StatelessWidget {
  const QuestionnaireListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Assessments'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Questionnaire Feature',
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
