# Camera Not Working - Troubleshooting Guide

## Common Issues and Solutions

### 1. Browser Permissions (Most Common Issue)

**Chrome Browser:**
1. Navigate to `localhost:8080` or your app URL
2. Look for camera icon in the address bar
3. Click on the camera/microphone icon and ensure permissions are set to "Allow"
4. If blocked, go to Chrome Settings → Privacy and Security → Site Settings → Camera → Allow
5. Refresh the page and try again

**Edge Browser:**
1. Similar to Chrome, check the address bar for permission prompts
2. Go to Settings → Site permissions → Camera → Allow

### 2. Windows Camera Privacy Settings

**Windows 10/11:**
1. Go to Windows Settings → Privacy → Camera
2. Ensure "Allow apps to access your camera" is ON
3. Ensure "Allow desktop apps to access your camera" is ON
4. Check if Chrome/Edge is listed and allowed

### 3. Code-Level Issues

#### 3.1 WebRTC Service Recursive Call Fix

The current `webrtc_service.dart` has a recursive call issue in the `createPeerConnection` method:

```dart
// ISSUE: This line is calling itself recursively
final pc = await createPeerConnection(participantId);

// FIX: Should use the flutter_webrtc API
final pc = await createPeerConnection(_configuration);
```

#### 3.2 Permission Request Timing

Make sure permissions are requested before attempting to access the camera:

```dart
// In your video call initialization
await _requestPermissions();
await startLocalStream(video: true, audio: true);
```

#### 3.3 Error Handling Improvements

Add better error handling for getUserMedia calls:

```dart
try {
  _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
} catch (e) {
  if (e.toString().contains('NotAllowedError')) {
    throw Exception('Camera permission denied. Please allow camera access in browser settings.');
  } else if (e.toString().contains('NotFoundError')) {
    throw Exception('No camera found. Please connect a camera and try again.');
  } else if (e.toString().contains('NotReadableError')) {
    throw Exception('Camera is already in use by another application.');
  } else {
    throw Exception('Failed to access camera: $e');
  }
}
```

### 4. Testing Steps

1. **Test Browser Permissions:**
   - Open Chrome DevTools (F12)
   - Go to Console tab
   - Run: `navigator.mediaDevices.getUserMedia({video: true, audio: true})`
   - If this fails, it's a permission issue

2. **Test Camera Access:**
   - Visit: `https://webcam-test.com`
   - If camera works here but not in your app, it's a code issue

3. **Check Flutter Web Console:**
   - Look for WebRTC errors in browser console
   - Common errors: "Permission denied", "Device not found", "Device in use"

### 5. Production Considerations

For production deployment:
1. Use HTTPS (required for camera access on non-localhost)
2. Add proper error handling and user feedback
3. Implement fallback options for unsupported browsers
4. Test on multiple devices and browsers

### 6. Flutter Web Specific Issues

**CORS Issues:**
- Ensure your server supports WebRTC
- Check if running on HTTPS for production

**Browser Compatibility:**
- Test on Chrome, Firefox, Safari, Edge
- Some older browsers don't support WebRTC fully

### 7. Quick Debug Commands

```bash
# Check Flutter doctor
flutter doctor -v

# Clean and rebuild
flutter clean
flutter pub get
flutter run -d chrome --web-port 8080

# Check for specific errors
flutter run -d chrome --verbose
```

### 8. Emergency Fixes

If all else fails:
1. Restart Chrome completely
2. Clear browser cache and cookies
3. Disable browser extensions temporarily
4. Try incognito/private mode
5. Try a different browser
6. Restart your computer

### 9. Code Patches to Apply

Apply these fixes to your codebase:

1. Fix the recursive call in `webrtc_service.dart`
2. Add better error handling in camera initialization
3. Add user-friendly error messages
4. Implement retry mechanism for failed camera access

Remember: The most common issue is browser permissions. Always check this first!
