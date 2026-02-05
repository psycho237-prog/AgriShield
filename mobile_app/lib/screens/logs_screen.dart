import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import 'package:intl/intl.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final data = await _apiService.fetchLog();
    if (data != null && data['records'] != null) {
      setState(() {
        _logs = List.from(data['records']).reversed.toList(); // Newest first
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(int timestamp) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd/MM HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('nav_logs')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No logs available', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final level = log['alert_level'] ?? 'GREEN';
                    
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatTimestamp((log['timestamp'] ?? 0) ~/ 1000), // convert ms to s if needed or vice versa
                                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                              _buildStatusIndicator(level),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildLogDetail(Icons.thermostat_outlined, '${log['temperature_air'] ?? '--'}°C', Colors.orange),
                              _buildLogDetail(Icons.water_drop_outlined, '${log['humidity_air'] ?? '--'}%', Colors.blue),
                              _buildLogDetail(Icons.grass_outlined, '${log['soil_moisture'] ?? '--'}%', Colors.brown),
                              _buildLogDetail(Icons.battery_std_outlined, '${log['battery_percent'] ?? '--'}%', Colors.green),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildStatusIndicator(String level) {
    Color color = Colors.green;
    if (level == 'RED') color = Colors.red;
    if (level == 'ORANGE') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        level,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLogDetail(IconData icon, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
