import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';
import '../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _settingsService = SettingsService.instance;
  
  // Controllers for form fields
  late TextEditingController _serverIpController;
  late TextEditingController _serverPortController;
  late TextEditingController _apiKeyController;
  late TextEditingController _httpTimeoutController;
  late TextEditingController _reconnectIntervalController;
  late TextEditingController _pollIntervalController;
  late TextEditingController _highTempThresholdController;
  late TextEditingController _lowFlowThresholdController;
  late TextEditingController _criticalTempThresholdController;
  late TextEditingController _criticalFlowThresholdController;
  
  // Boolean settings
  bool _enableNotifications = true;
  bool _enableWebSocket = true;
  bool _enableOfflineMode = true;
  
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCurrentSettings();
  }

  void _initializeControllers() {
    _serverIpController = TextEditingController();
    _serverPortController = TextEditingController();
    _apiKeyController = TextEditingController();
    _httpTimeoutController = TextEditingController();
    _reconnectIntervalController = TextEditingController();
    _pollIntervalController = TextEditingController();
    _highTempThresholdController = TextEditingController();
    _lowFlowThresholdController = TextEditingController();
    _criticalTempThresholdController = TextEditingController();
    _criticalFlowThresholdController = TextEditingController();
    
    // Add listeners to detect changes
    _serverIpController.addListener(_onFieldChanged);
    _serverPortController.addListener(_onFieldChanged);
    _apiKeyController.addListener(_onFieldChanged);
    _httpTimeoutController.addListener(_onFieldChanged);
    _reconnectIntervalController.addListener(_onFieldChanged);
    _pollIntervalController.addListener(_onFieldChanged);
    _highTempThresholdController.addListener(_onFieldChanged);
    _lowFlowThresholdController.addListener(_onFieldChanged);
    _criticalTempThresholdController.addListener(_onFieldChanged);
    _criticalFlowThresholdController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _loadCurrentSettings() {
    _serverIpController.text = _settingsService.serverIp;
    _serverPortController.text = _settingsService.serverPort.toString();
    _apiKeyController.text = _settingsService.apiKey;
    _httpTimeoutController.text = _settingsService.httpTimeout.inSeconds.toString();
    _reconnectIntervalController.text = _settingsService.reconnectInterval.inSeconds.toString();
    _pollIntervalController.text = _settingsService.pollInterval.inSeconds.toString();
    _highTempThresholdController.text = _settingsService.highTemperatureThreshold.toString();
    _lowFlowThresholdController.text = _settingsService.lowFlowThreshold.toString();
    _criticalTempThresholdController.text = _settingsService.criticalTemperatureThreshold.toString();
    _criticalFlowThresholdController.text = _settingsService.criticalFlowThreshold.toString();
    
    setState(() {
      _enableNotifications = _settingsService.enableNotifications;
      _enableWebSocket = _settingsService.enableWebSocket;
      _enableOfflineMode = _settingsService.enableOfflineMode;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final settings = {
        'serverIp': _serverIpController.text.trim(),
        'serverPort': int.parse(_serverPortController.text),
        'apiKey': _apiKeyController.text.trim(),
        'httpTimeout': int.parse(_httpTimeoutController.text),
        'reconnectInterval': int.parse(_reconnectIntervalController.text),
        'pollInterval': int.parse(_pollIntervalController.text),
        'highTemperatureThreshold': double.parse(_highTempThresholdController.text),
        'lowFlowThreshold': double.parse(_lowFlowThresholdController.text),
        'criticalTemperatureThreshold': double.parse(_criticalTempThresholdController.text),
        'criticalFlowThreshold': double.parse(_criticalFlowThresholdController.text),
        'enableNotifications': _enableNotifications,
        'enableWebSocket': _enableWebSocket,
        'enableOfflineMode': _enableOfflineMode,
      };

      await _settingsService.updateSettings(settings);
      
      // Reinitialize API service with new settings
      await ApiService.instance.initialize();

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _settingsService.resetToDefaults();
      _loadCurrentSettings();
      setState(() {
        _hasUnsavedChanges = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings reset to defaults'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Temporarily save settings for testing
      await _saveSettings();
      
      // Test the connection
      final response = await ApiService.instance.getAllGuns();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.success 
                ? 'Connection successful!' 
                : 'Connection failed: ${response.error}'
            ),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _serverIpController.dispose();
    _serverPortController.dispose();
    _apiKeyController.dispose();
    _httpTimeoutController.dispose();
    _reconnectIntervalController.dispose();
    _pollIntervalController.dispose();
    _highTempThresholdController.dispose();
    _lowFlowThresholdController.dispose();
    _criticalTempThresholdController.dispose();
    _criticalFlowThresholdController.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.blue.shade800,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildServerConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _serverIpController,
              decoration: const InputDecoration(
                labelText: 'Server IP Address',
                hintText: '192.168.1.100',
                prefixIcon: Icon(Icons.computer),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter server IP address';
                }
                if (!SettingsService.isValidIpAddress(value.trim())) {
                  return 'Please enter a valid IP address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serverPortController,
              decoration: const InputDecoration(
                labelText: 'Server Port',
                hintText: '7575',
                prefixIcon: Icon(Icons.settings_ethernet),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter server port';
                }
                final port = int.tryParse(value);
                if (port == null || !SettingsService.isValidPort(port)) {
                  return 'Please enter a valid port (1-65535)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'FlameApp123\$byNevark',
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter API key';
                }
                if (value.length < 8) {
                  return 'API key must be at least 8 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _httpTimeoutController,
              decoration: const InputDecoration(
                labelText: 'HTTP Timeout (seconds)',
                hintText: '10',
                prefixIcon: Icon(Icons.timer),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter timeout value';
                }
                final timeout = int.tryParse(value);
                if (timeout == null || !SettingsService.isValidInterval(timeout)) {
                  return 'Please enter a valid timeout (1-300 seconds)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reconnectIntervalController,
              decoration: const InputDecoration(
                labelText: 'Reconnect Interval (seconds)',
                hintText: '10',
                prefixIcon: Icon(Icons.refresh),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter reconnect interval';
                }
                final interval = int.tryParse(value);
                if (interval == null || !SettingsService.isValidInterval(interval)) {
                  return 'Please enter a valid interval (1-300 seconds)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pollIntervalController,
              decoration: const InputDecoration(
                labelText: 'Poll Interval (seconds)',
                hintText: '5',
                prefixIcon: Icon(Icons.schedule),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter poll interval';
                }
                final interval = int.tryParse(value);
                if (interval == null || !SettingsService.isValidInterval(interval)) {
                  return 'Please enter a valid interval (1-300 seconds)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _highTempThresholdController,
              decoration: const InputDecoration(
                labelText: 'High Temperature Threshold (°C)',
                hintText: '45.0',
                prefixIcon: Icon(Icons.thermostat),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter high temperature threshold';
                }
                final threshold = double.tryParse(value);
                if (threshold == null || !SettingsService.isValidThreshold(threshold)) {
                  return 'Please enter a valid threshold (0-1000)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lowFlowThresholdController,
              decoration: const InputDecoration(
                labelText: 'Low Flow Threshold',
                hintText: '8.0',
                prefixIcon: Icon(Icons.water_drop),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter low flow threshold';
                }
                final threshold = double.tryParse(value);
                if (threshold == null || !SettingsService.isValidThreshold(threshold)) {
                  return 'Please enter a valid threshold (0-1000)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _criticalTempThresholdController,
              decoration: const InputDecoration(
                labelText: 'Critical Temperature Threshold (°C)',
                hintText: '50.0',
                prefixIcon: Icon(Icons.warning),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter critical temperature threshold';
                }
                final threshold = double.tryParse(value);
                if (threshold == null || !SettingsService.isValidThreshold(threshold)) {
                  return 'Please enter a valid threshold (0-1000)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _criticalFlowThresholdController,
              decoration: const InputDecoration(
                labelText: 'Critical Flow Threshold',
                hintText: '5.0',
                prefixIcon: Icon(Icons.error),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter critical flow threshold';
                }
                final threshold = double.tryParse(value);
                if (threshold == null || !SettingsService.isValidThreshold(threshold)) {
                  return 'Please enter a valid threshold (0-1000)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTogglesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive push notifications for alerts'),
              value: _enableNotifications,
              onChanged: (value) {
                setState(() {
                  _enableNotifications = value;
                  _hasUnsavedChanges = true;
                });
              },
              secondary: const Icon(Icons.notifications),
            ),
            SwitchListTile(
              title: const Text('Enable WebSocket'),
              subtitle: const Text('Use real-time WebSocket connection'),
              value: _enableWebSocket,
              onChanged: (value) {
                setState(() {
                  _enableWebSocket = value;
                  _hasUnsavedChanges = true;
                });
              },
              secondary: const Icon(Icons.wifi),
            ),
            SwitchListTile(
              title: const Text('Enable Offline Mode'),
              subtitle: const Text('Cache data for offline access'),
              value: _enableOfflineMode,
              onChanged: (value) {
                setState(() {
                  _enableOfflineMode = value;
                  _hasUnsavedChanges = true;
                });
              },
              secondary: const Icon(Icons.offline_bolt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _testConnection,
                icon: const Icon(Icons.wifi_find),
                label: const Text('Test Connection'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _resetToDefaults,
                icon: const Icon(Icons.restore),
                label: const Text('Reset'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue.shade800,
        actions: [
          if (_hasUnsavedChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveSettings,
              tooltip: 'Save Settings',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _resetToDefaults();
                  break;
                case 'test':
                  _testConnection();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'test',
                child: Row(
                  children: [
                    Icon(Icons.wifi_find),
                    SizedBox(width: 8),
                    Text('Test Connection'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore),
                    SizedBox(width: 8),
                    Text('Reset to Defaults'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                _loadCurrentSettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings refreshed'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader('Server Configuration'),
                  _buildServerConfigSection(),
                  const SizedBox(height: 24),

                  _buildSectionHeader('Connection Settings'),
                  _buildConnectionSettingsSection(),
                  const SizedBox(height: 24),

                  _buildSectionHeader('Alert Thresholds'),
                  _buildThresholdSection(),
                  const SizedBox(height: 24),

                  _buildSectionHeader('Features'),
                  _buildFeatureTogglesSection(),
                  const SizedBox(height: 32),

                  _buildActionButtons(),
                ],
              ),
            ),
          ),
    );
  }
}
