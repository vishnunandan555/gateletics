import 'package:flutter/material.dart';
import '../../providers/telemetry_service.dart';

class TelemetrySettingsSection extends StatefulWidget {
  const TelemetrySettingsSection({super.key});

  @override
  State<TelemetrySettingsSection> createState() => _TelemetrySettingsSectionState();
}

class _TelemetrySettingsSectionState extends State<TelemetrySettingsSection> {
  bool _isEnabled = true;
  final TextEditingController _urlController = TextEditingController();
  bool _isTesting = false;
  String? _testMessage;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final enabled = await TelemetryService.isTelemetryEnabled();
    final customUrl = await TelemetryService.getCustomUrl();
    if (mounted) {
      setState(() {
        _isEnabled = enabled;
        _urlController.text = customUrl;
      });
    }
  }

  Future<void> _toggleTelemetry(bool value) async {
    await TelemetryService.setTelemetryEnabled(value);
    setState(() {
      _isEnabled = value;
    });
  }

  Future<void> _saveCustomUrl(String value) async {
    await TelemetryService.setCustomUrl(value);
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testMessage = null;
      _testSuccess = null;
    });

    final result = await TelemetryService.sendTestPing(_urlController.text);
    
    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = result['success'] as bool;
        _testMessage = result['message'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Divider(color: Colors.white12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'TELEMETRY & DIAGNOSTICS',
            style: TextStyle(
              color: Colors.amberAccent.withAlpha(178),
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SwitchListTile(
          value: _isEnabled,
          onChanged: _toggleTelemetry,
          activeThumbColor: Colors.amberAccent,
          secondary: const Icon(Icons.analytics_outlined, color: Colors.amberAccent),
          title: const Text('Anonymous Daily Telemetry'),
          subtitle: const Text(
            'Ping server securely with SHA256 tokens upon app launch. GDPR-compliant. No personal data collected.',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),
        if (_isEnabled) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Custom Telemetry Endpoint URL',
                  style: TextStyle(
                    color: Colors.white.withAlpha(128),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: TextField(
                          controller: _urlController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'https://gate-tracker-telemetry.vercel.app/api/ping',
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onChanged: _saveCustomUrl,
                          onSubmitted: _saveCustomUrl,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isTesting ? null : _testConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(12),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.white24),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          elevation: 0,
                        ),
                        child: _isTesting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.bolt, color: Colors.amberAccent, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Leave blank to use the default production telemetry server.',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
                if (_testMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _testSuccess == true
                          ? Colors.green.withAlpha(20)
                          : Colors.redAccent.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _testSuccess == true
                            ? Colors.green.withAlpha(80)
                            : Colors.redAccent.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _testSuccess == true
                              ? Icons.check_circle_outline_rounded
                              : Icons.error_outline_rounded,
                          color: _testSuccess == true ? Colors.greenAccent : Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _testMessage!,
                            style: TextStyle(
                              color: _testSuccess == true ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
