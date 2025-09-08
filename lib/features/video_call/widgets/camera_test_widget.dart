import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CameraTestWidget extends StatefulWidget {
  const CameraTestWidget({Key? key}) : super(key: key);

  @override
  State<CameraTestWidget> createState() => _CameraTestWidgetState();
}

class _CameraTestWidgetState extends State<CameraTestWidget> {
  RTCVideoRenderer? _localRenderer;
  MediaStream? _localStream;
  String _status = 'Ready to test camera';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeRenderer();
  }

  Future<void> _initializeRenderer() async {
    _localRenderer = RTCVideoRenderer();
    await _localRenderer!.initialize();
    setState(() {});
  }

  Future<void> _testCameraAccess() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing camera access...';
    });

    try {
      // Test basic camera access
      final mediaConstraints = {
        'video': {
          'mandatory': {
            'minWidth': '320',
            'minHeight': '240',
            'minFrameRate': '15',
          },
          'facingMode': 'user',
        },
        'audio': false, // Test video only first
      };

      print('Requesting camera access with constraints: $mediaConstraints');
      
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      
      if (_localRenderer != null) {
        _localRenderer!.srcObject = _localStream;
      }

      setState(() {
        _status = 'Camera access successful! 📹';
        _isLoading = false;
      });

      print('Camera access successful');
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('NotAllowedError') || e.toString().contains('Permission denied')) {
        errorMessage = '❌ Camera permission denied. Check your browser settings.';
      } else if (e.toString().contains('NotFoundError')) {
        errorMessage = '❌ No camera found. Please connect a camera.';
      } else if (e.toString().contains('NotReadableError')) {
        errorMessage = '❌ Camera is in use by another application.';
      } else {
        errorMessage = '❌ Error: $e';
      }

      setState(() {
        _status = errorMessage;
        _isLoading = false;
      });

      print('Camera error: $e');
    }
  }

  Future<void> _stopCamera() async {
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) => track.stop());
      _localStream = null;
    }
    if (_localRenderer != null) {
      _localRenderer!.srcObject = null;
    }
    setState(() {
      _status = 'Camera stopped';
    });
  }

  @override
  void dispose() {
    _stopCamera();
    _localRenderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Camera Permissions Check',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 16,
                        color: _status.contains('❌') ? Colors.red : 
                               _status.contains('📹') ? Colors.green : Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _testCameraAccess,
                            icon: const Icon(Icons.videocam),
                            label: const Text('Test Camera'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _stopCamera,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_localRenderer != null)
              Expanded(
                child: Card(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        const Text(
                          'Camera Preview',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _localStream != null
                                ? RTCVideoView(_localRenderer!)
                                : const Center(
                                    child: Text(
                                      'No video stream\nClick "Test Camera" to start',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Troubleshooting Tips:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Check camera permission in browser address bar'),
                    const Text('2. Ensure no other apps are using the camera'),
                    const Text('3. Try refreshing the page'),
                    const Text('4. Check Windows camera privacy settings'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Open browser console for debugging
                        html.window.console.log('Camera debugging info:');
                        html.window.console.log('Navigator: ${html.window.navigator}');
                        html.window.console.log('MediaDevices available: ${html.window.navigator.mediaDevices != null}');
                      },
                      icon: const Icon(Icons.bug_report),
                      label: const Text('Debug Info (Check Console)'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
