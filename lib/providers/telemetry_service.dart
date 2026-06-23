import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class TelemetryService {
  static const String _kClientIdKey = 'telemetry_client_id';
  static const String _kLastPingDateKey = 'telemetry_last_ping_date';
  static const String _kTelemetryEnabledKey = 'telemetry_enabled';
  static const String _kCustomTelemetryUrlKey = 'telemetry_custom_url';
  
  // Default Vercel production telemetry URL
  static const String _kTelemetryUrl = 'https://gate-tracker-telemetry.vercel.app/api/ping';

  /// Checks if telemetry is currently enabled (defaults to true)
  static Future<bool> isTelemetryEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kTelemetryEnabledKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Sets whether telemetry is enabled
  static Future<void> setTelemetryEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kTelemetryEnabledKey, enabled);
    } catch (e) {
      debugPrint("[Telemetry] Error setting enabled state: $e");
    }
  }

  /// Gets the custom telemetry URL (defaults to empty string, i.e., default URL)
  static Future<String> getCustomUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kCustomTelemetryUrlKey) ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Sets the custom telemetry URL
  static Future<void> setCustomUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCustomTelemetryUrlKey, url.trim());
    } catch (e) {
      debugPrint("[Telemetry] Error setting custom URL: $e");
    }
  }

  /// Generates a randomized secure client installation ID if not already existing
  static Future<String> _getOrCreateClientId(SharedPreferences prefs) async {
    String? clientId = prefs.getString(_kClientIdKey);
    if (clientId == null || clientId.isEmpty) {
      final random = Random.secure();
      final values = List<int>.generate(16, (i) => random.nextInt(256));
      clientId = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString(_kClientIdKey, clientId);
    }
    return clientId;
  }

  /// Resolve platform tag safely across web and native targets
  static String _getPlatformTag() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Computes the daily SHA256 GDPR-compliant token
  static String _computeDailyToken(String clientId, String dateString) {
    final bytes = utf8.encode(clientId + dateString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Triggers a fire-and-forget daily active user telemetry ping
  static Future<void> triggerLaunchPing() async {
    try {
      debugPrint("[Telemetry] Checking daily active user ping status...");
      
      // 1. Privacy check: Verify if telemetry is enabled
      if (!(await isTelemetryEnabled())) {
        debugPrint("[Telemetry] Telemetry is disabled by user. Launch ping skipped.");
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      
      // 2. Get current date string (UTC)
      final String today = DateTime.now().toUtc().toIso8601String().split('T')[0];
      
      // 3. Cooldown check: ping at most once per UTC calendar day
      final String? lastPing = prefs.getString(_kLastPingDateKey);
      if (lastPing == today) {
        debugPrint("[Telemetry] Daily active user ping already sent today (skipped).");
        return;
      }

      // 4. Resolve client identifier and package version
      final String clientId = await _getOrCreateClientId(prefs);
      final String platform = _getPlatformTag();
      
      String version = '1.1.1';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        version = packageInfo.version;
      } catch (_) {
        // Fallback for platform channels loading delays
      }

      // 5. Compute hashed daily token
      final String dailyToken = _computeDailyToken(clientId, today);

      // Resolve endpoint URL
      final String customUrl = await getCustomUrl();
      final String targetUrl = customUrl.isNotEmpty ? customUrl : _kTelemetryUrl;

      debugPrint("[Telemetry] Attempting daily active user ping (Platform: $platform, Version: $version) to URL: $targetUrl...");

      // 6. Fire post ping
      final response = await http.post(
        Uri.parse(targetUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'dailyToken': dailyToken,
          'version': version,
          'platform': platform,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint("[Telemetry] Daily active user ping sent successfully! (Response: 200)");
        // Record successful daily ping date in cache
        await prefs.setString(_kLastPingDateKey, today);
      } else {
        debugPrint("[Telemetry] Daily active user ping failed: Server returned status ${response.statusCode} (${response.reasonPhrase}).");
      }
    } catch (e) {
      debugPrint("[Telemetry] Daily active user ping failed due to network error: $e");
    }
  }

  /// Sends a test ping to the specified target URL to verify server status.
  /// Returns a Map containing: {'success': bool, 'message': String}
  static Future<Map<String, dynamic>> sendTestPing(String targetUrl) async {
    final String url = targetUrl.trim().isEmpty ? _kTelemetryUrl : targetUrl.trim();
    
    // Validate basic URL format
    Uri parsedUri;
    try {
      parsedUri = Uri.parse(url);
      if (!parsedUri.hasAbsolutePath) {
        return {
          'success': false,
          'message': 'Invalid URL format. Must be an absolute HTTP/HTTPS address.'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to parse URL: $e'
      };
    }

    try {
      debugPrint("[Telemetry] Attempting connection test to: $url...");
      
      final prefs = await SharedPreferences.getInstance();
      final String clientId = await _getOrCreateClientId(prefs);
      final String platform = _getPlatformTag();
      
      String version = '1.1.1-test';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        version = '${packageInfo.version}-test';
      } catch (_) {}

      // Compute a dummy test token
      final String testToken = _computeDailyToken(clientId, "test-connection-${DateTime.now().millisecondsSinceEpoch}");

      final response = await http.post(
        parsedUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'dailyToken': testToken,
          'version': version,
          'platform': platform,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Connection successful! Server returned Status 200.'
        };
      } else {
        return {
          'success': false,
          'message': 'Server returned error Status ${response.statusCode}: ${response.reasonPhrase}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection failed: $e'
      };
    }
  }
}
