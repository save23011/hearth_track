import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/webrtc_service.dart';

class CameraDebugWidget extends ConsumerStatefulWidget {
  const CameraDebugWidget({super.key});

  @override
  ConsumerState<CameraDebugWidget> createState() => _CameraDebugWidgetState();
}

class _CameraDebugWidgetState extends ConsumerState<CameraDebugWidget> {
  final WebRTCService _webrtcService = WebRTCService();
  String _status = 'Not tested';
  bool _isLoading = false;
  List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
  }

  Future<void> _testCamera() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing...';
      _logs.clear();
    });

    try {
      _addLog('Starting camera test...');
      
      // Test 1: Initialize WebRTC
      _addLog('Initializing WebRTC service...');
      await _webrtcService.initialize();
      _addLog('✓ WebRTC service initialized');

      // Test 2: Get camera devices
      _addLog('Enumerating camera devices...');
      final cameras = await _webrtcService.getCameraDevices();
      _addLog('✓ Found ${cameras.length} camera device(s)');

      // Test 3: Test camera access
      _addLog('Testing camera access...');
      final hasAccess = await _webrtcService.testCameraAccess();
      
      if (hasAccess) {
        _addLog('✓ Camera access successful');
        
        // Test 4: Start local stream
        _addLog('Starting local video stream...');
        await _webrtcService.startLocalStream(video: true, audio: false);
        _addLog('✓ Local video stream started successfully');
        
        setState(() {
          _status = 'Camera working correctly';
        });
      } else {
        setState(() {
          _status = 'Camera access denied or failed';
        });
      }
    } catch (e) {
      _addLog('✗ Error: $e');
      setState(() {
        _status = 'Camera test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.camera_alt, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Camera Debug Test',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testCamera,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test Camera'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _status.contains('working')
                    ? Colors.green.withOpacity(0.1)
                    : _status.contains('failed') || _status.contains('denied')
                        ? Colors.red.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _status.contains('working')
                      ? Colors.green
                      : _status.contains('failed') || _status.contains('denied')
                          ? Colors.red
                          : Colors.grey,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _status.contains('working')
                        ? Icons.check_circle
                        : _status.contains('failed') || _status.contains('denied')
                            ? Icons.error
                            : Icons.info,
                    color: _status.contains('working')
                        ? Colors.green
                        : _status.contains('failed') || _status.contains('denied')
                            ? Colors.red
                            : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Status: $_status',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _status.contains('working')
                            ? Colors.green.shade700
                            : _status.contains('failed') || _status.contains('denied')
                                ? Colors.red.shade700
                                : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_logs.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Debug Log:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: log.contains('✓')
                              ? Colors.green.shade700
                              : log.contains('✗')
                                  ? Colors.red.shade700
                                  : Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Common Solutions:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Ensure camera permissions are granted in browser'),
                Text('• Close other applications using the camera'),
                Text('• Try refreshing the page'),
                Text('• Check if camera is connected properly'),
                Text('• Try using incognito/private browsing mode'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
