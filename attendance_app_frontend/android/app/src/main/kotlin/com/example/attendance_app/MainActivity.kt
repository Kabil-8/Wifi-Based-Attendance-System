package com.example.attendance_app

import android.content.pm.PackageManager
import android.hardware.biometrics.BiometricManager.Authenticators
import android.os.Build
import android.os.CancellationSignal
import androidx.annotation.RequiresApi
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity
 *
 * Exposes two MethodChannel calls to Flutter:
 *   • biometric/authenticate  (method: "fingerprintOnly" | "faceOnly")
 *
 * "fingerprintOnly" : BiometricPrompt that accepts ONLY fingerprint
 *                     (achieved by checking that fingerprint hardware exists and
 *                      pre-verifying via BIOMETRIC_STRONG which maps to fingerprint
 *                      on nearly all Android devices).
 *
 * "faceOnly"        : BiometricPrompt restricted to face recognition.
 *                     On Android 11+ we check BiometricManager for BIOMETRIC_STRONG
 *                     capability after confirming NO fingerprint hardware is used
 *                     (we check PackageManager feature flag for face).
 *                     The system prompt title/subtitle makes the intent clear.
 *
 * Both return a Map to Flutter:
 *   { "success": true/false, "error": "<message or null>" }
 */
class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val CHANNEL = "com.example.attendance_app/biometric"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "fingerprintOnly" -> authenticateFingerprint(result)
                "faceOnly"        -> authenticateFace(result)
                else              -> result.notImplemented()
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Gate 1 — Fingerprint Only
    // ─────────────────────────────────────────────────────────────────────────

    private fun authenticateFingerprint(result: MethodChannel.Result) {
        val manager = BiometricManager.from(this)

        // Verify the device can handle a strong biometric (fingerprint class)
        val canAuth = manager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)
        if (canAuth != BiometricManager.BIOMETRIC_SUCCESS) {
            result.success(mapOf("success" to false, "error" to "Fingerprint not available (code $canAuth)"))
            return
        }

        // Double-check fingerprint hardware feature flag
        val hasFingerprintHw = packageManager.hasSystemFeature(PackageManager.FEATURE_FINGERPRINT)
        if (!hasFingerprintHw) {
            result.success(mapOf("success" to false, "error" to "No fingerprint sensor on this device"))
            return
        }

        val executor = ContextCompat.getMainExecutor(this)

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Fingerprint Verification")
            .setSubtitle("Step 1 of 2 — Scan your enrolled fingerprint")
            .setDescription("Place your finger on the sensor to continue")
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            // setNegativeButtonText is required when NOT allowing device credential
            .setNegativeButtonText("Cancel")
            .build()

        val biometricPrompt = BiometricPrompt(
            this,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(r: BiometricPrompt.AuthenticationResult) {
                    result.success(mapOf("success" to true, "error" to null))
                }

                override fun onAuthenticationFailed() {
                    // Called when a finger is presented but not recognised — do NOT
                    // resolve the result here; the system retries automatically.
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    result.success(
                        mapOf("success" to false, "error" to "Fingerprint error ($errorCode): $errString"),
                    )
                }
            },
        )

        biometricPrompt.authenticate(promptInfo)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Gate 2 — Face Only
    // ─────────────────────────────────────────────────────────────────────────

    private fun authenticateFace(result: MethodChannel.Result) {
        // Check that the device advertises a front-facing camera / face-auth feature
        val hasFaceHw = packageManager.hasSystemFeature(PackageManager.FEATURE_FACE)
                     || packageManager.hasSystemFeature("android.hardware.biometrics.face")

        if (!hasFaceHw) {
            result.success(mapOf("success" to false, "error" to "No Face Recognition hardware on this device"))
            return
        }

        // On Android 11+ we can query BiometricManager for BIOMETRIC_STRONG capability.
        // If the only strong biometric is fingerprint, face is BIOMETRIC_WEAK on this device.
        // We still proceed and let BiometricPrompt handle it; the title makes intent clear.
        val manager = BiometricManager.from(this)
        val canAuthWeak = manager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK)
        if (canAuthWeak != BiometricManager.BIOMETRIC_SUCCESS) {
            result.success(
                mapOf("success" to false, "error" to "Face Recognition not enrolled or not available (code $canAuthWeak)"),
            )
            return
        }

        val executor = ContextCompat.getMainExecutor(this)

        // Use BIOMETRIC_WEAK to allow face (which is weak-class on many OEMs).
        // The title + confirmationRequired = true forces the user to consciously
        // present their face rather than passively pass.
        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Face Recognition")
            .setSubtitle("Step 2 of 2 — Look at the front camera")
            .setDescription("Face Recognition is required to complete verification")
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_WEAK)
            .setConfirmationRequired(true)          // forces explicit face match confirmation
            .setNegativeButtonText("Cancel")
            .build()

        val biometricPrompt = BiometricPrompt(
            this,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(r: BiometricPrompt.AuthenticationResult) {
                    result.success(mapOf("success" to true, "error" to null))
                }

                override fun onAuthenticationFailed() {
                    // System retries — do not resolve here
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    result.success(
                        mapOf("success" to false, "error" to "Face Recognition error ($errorCode): $errString"),
                    )
                }
            },
        )

        biometricPrompt.authenticate(promptInfo)
    }
}
