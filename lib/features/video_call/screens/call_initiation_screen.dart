import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import 'video_call_screen.dart';

class CallInitiationScreen extends ConsumerStatefulWidget {
  const CallInitiationScreen({super.key});

  @override
  ConsumerState<CallInitiationScreen> createState() => _CallInitiationScreenState();
}

class _CallInitiationScreenState extends ConsumerState<CallInitiationScreen> {
  final _sessionIdController = TextEditingController();
  final _serverUrlController = TextEditingController(
    text: 'https://sol-3a0fa16a1680.herokuapp.com', // Default backend URL
  );
  bool _isJoining = false;

  @override
  void dispose() {
    _sessionIdController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Join Video Call'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              
              // Header
              const Text(
                'Join a Video Call',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Enter the session ID to join an existing call or create a new one',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Server URL input
              _buildInputField(
                controller: _serverUrlController,
                label: 'Server URL',
                hint: 'Enter backend server URL',
                icon: Icons.cloud,
              ),
              
              const SizedBox(height: 24),
              
              // Session ID input
              _buildInputField(
                controller: _sessionIdController,
                label: 'Session ID',
                hint: 'Enter session ID or leave empty for new call',
                icon: Icons.video_call,
              ),
              
              const SizedBox(height: 32),
              
              // Join call button
              ElevatedButton(
                onPressed: _isJoining ? null : _joinCall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isJoining
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Join Call',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Create new call button
              OutlinedButton(
                onPressed: _isJoining ? null : _createNewCall,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.blue),
                ),
                child: const Text(
                  'Create New Call',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Help text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Make sure your backend server is running\n'
                      '• Check camera and microphone permissions\n'
                      '• Use a stable internet connection',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _joinCall() async {
    if (_serverUrlController.text.isEmpty) {
      _showErrorDialog('Please enter a server URL');
      return;
    }

    if (_sessionIdController.text.isEmpty) {
      _showErrorDialog('Please enter a session ID');
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      // Get current user and token
      final user = await AuthService.getCurrentUser();
      final token = ApiService.authToken;
      
      if (user == null || token == null) {
        // For demo purposes, create a demo user
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final demoUser = {
          'id': 'demo_user_$timestamp',
          'firstName': 'Demo',
          'lastName': 'User',
        };
        final demoToken = 'demo_token_$timestamp';
        
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              sessionId: _sessionIdController.text.trim(),
              serverUrl: _serverUrlController.text.trim(),
              userId: demoUser['id']!,
              token: demoToken,
            ),
          ),
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            sessionId: _sessionIdController.text.trim(),
            serverUrl: _serverUrlController.text.trim(),
            userId: user.id,
            token: token,
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog('Failed to join call: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _createNewCall() async {
    if (_serverUrlController.text.isEmpty) {
      _showErrorDialog('Please enter a server URL');
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      // Get current user and token
      final user = await AuthService.getCurrentUser();
      final token = ApiService.authToken;
      
      if (user == null || token == null) {
        // For demo purposes, create a demo user
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final demoUser = {
          'id': 'demo_user_$timestamp',
          'firstName': 'Demo',
          'lastName': 'User',
        };
        final demoToken = 'demo_token_$timestamp';
        
        // Generate a new session ID
        final sessionId = _generateSessionId();
        _sessionIdController.text = sessionId;

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              sessionId: sessionId,
              serverUrl: _serverUrlController.text.trim(),
              userId: demoUser['id']!,
              token: demoToken,
            ),
          ),
        );
        return;
      }

      // Generate a new session ID
      final sessionId = _generateSessionId();
      _sessionIdController.text = sessionId;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            sessionId: sessionId,
            serverUrl: _serverUrlController.text.trim(),
            userId: user.id,
            token: token,
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog('Failed to create call: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'call_${timestamp}_$random';
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
