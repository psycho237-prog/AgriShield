import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    final data = await _apiService.fetchLog();
    if (data != null && data['records'] != null) {
      setState(() {
        _logs = List.from(data['records']);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('nav_stats')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('No data available for analysis'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.get('stats_last_24h'),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      _buildChartSection(AppStrings.get('soil_moist'), _getSoilMoistureSpots(), Colors.brown),
                      const SizedBox(height: 32),
                      _buildChartSection(AppStrings.get('air_temp'), _getAirTempSpots(), Colors.orange),
                      const SizedBox(height: 32),
                      _buildChartSection(AppStrings.get('air_hum'), _getAirHumiditySpots(), Colors.blue),
                    ],
                  ),
                ),
    );
  }

  Widget _buildChartSection(String title, List<FlSpot> spots, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[300]!)),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _getSoilMoistureSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _logs.length; i++) {
      spots.add(FlSpot(i.toDouble(), (_logs[i]['soil_moisture'] ?? 0).toDouble()));
    }
    return spots;
  }

  List<FlSpot> _getAirTempSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _logs.length; i++) {
      spots.add(FlSpot(i.toDouble(), (_logs[i]['temperature_air'] ?? 0.0).toDouble()));
    }
    return spots;
  }

  List<FlSpot> _getAirHumiditySpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _logs.length; i++) {
      spots.add(FlSpot(i.toDouble(), (_logs[i]['humidity_air'] ?? 0.0).toDouble()));
    }
    return spots;
  }
}
