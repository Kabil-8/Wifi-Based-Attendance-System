import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Camera service for Tier 3B — capturing audit selfies when
/// a biometric signature change is detected.
class CameraService {
  final ImagePicker _picker = ImagePicker();

  /// ── Tier 3B: Capture an audit selfie via the front camera ────────────────
  ///
  /// Opens the device front camera to take a selfie. The resulting image
  /// is sent to the backend as `auditSelfie` and the attendance record
  /// is flagged for review.
  ///
  /// Returns a [File] on success or `null` if the user cancels / errors.
  Future<File?> captureAuditSelfie() async {
    try {
      debugPrint('📸 [CameraService] Launching front camera for audit selfie…');

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (photo == null) {
        debugPrint('⚠️ [CameraService] User cancelled selfie capture');
        return null;
      }

      final file = File(photo.path);
      final bytes = await file.length();
      debugPrint('✅ [CameraService] Selfie captured: ${photo.path} ($bytes bytes)');
      return file;
    } catch (e) {
      debugPrint('❌ [CameraService] Camera error: $e');
      return null;
    }
  }

  /// Legacy alias for backward compatibility.
  Future<File?> captureFace() => captureAuditSelfie();
}
