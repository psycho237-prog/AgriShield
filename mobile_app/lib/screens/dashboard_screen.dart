import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sensor_data.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../widgets/sensor_card.dart';
import 'advisor_screen.dart';
import 'config_screen.dart';
import 'logs_screen.dart';
import 'stats_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  SensorData? _currentData;
  bool _isLoading = true;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    await _loadFromCache();
    await _refreshData();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString('last_sensor_data');
      if (cachedJson != null) {
        setState(() {
          _currentData = SensorData.fromJson(json.decode(cachedJson));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cache: $e');
    }
  }

  Future<void> _saveToCache(SensorData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sensor_data', json.encode(data.toJson()));
    } catch (e) {
      debugPrint('Error saving cache: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = _currentData == null);
    
    final health = await _apiService.checkHealth();
    if (health) {
      final data = await _apiService.fetchStatus();
      if (data != null) {
        setState(() {
          _currentData = data;
          _isOnline = true;
          _isLoading = false;
        });
        await _saveToCache(data);
      }
    } else {
      setState(() {
        _isOnline = false;
        _isLoading = false;
      });
    }
  }

  Color _getAlertColor(String level) {
    switch (level) {
      case 'RED': return Colors.red;
      case 'ORANGE': return Colors.orange;
      case 'GREEN': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.green[800],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(AppStrings.get('app_title'), 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [Colors.green[900]!, Colors.green[700]!],
                        ),
                      ),
                    ),
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(Icons.agriculture_outlined, size: 200, color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 60),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AgriShield v1.0', style: TextStyle(color: Colors.white, fontSize: 14)),
                          Text('Professional Monitoring', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshData,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: _isLoading 
                ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
                : (_currentData != null)
                  ? _buildMainDashboard()
                  : _buildOfflineView(),
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildOfflineView() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Column(
        children: [
          Icon(Icons.sensors_off_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(AppStrings.get('sync_required'), 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(AppStrings.get('sync_desc'), 
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _refreshData, 
            icon: const Icon(Icons.sync),
            label: Text(AppStrings.get('btn_retry')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDashboard() {
    return Column(
      children: [
        if (!_isOnline) _buildOfflineBanner(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAlertSection(),
              const SizedBox(height: 24),
              _SectionHeader(title: AppStrings.get('stats_last_24h'), icon: Icons.analytics_outlined),
              const SizedBox(height: 12),
              _buildSensorGrid(),
              const SizedBox(height: 24),
              _SectionHeader(title: AppStrings.get('battery'), icon: Icons.power_outlined),
              const SizedBox(height: 12),
              _buildPowerCard(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: Colors.amber[50],
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 16, color: Colors.amber[900]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.get('offline_mode'),
              style: TextStyle(color: Colors.amber[900], fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: _refreshData,
            child: Text(AppStrings.get('btn_refresh'), style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertSection() {
    final alertColor = _getAlertColor(_currentData?.alertLevel ?? 'GREEN');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: alertColor.withOpacity(0.5), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: alertColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.shield_outlined, color: alertColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${AppStrings.get('risk_level')}: ${_currentData?.alertLevel}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: alertColor)),
                Text(_currentData?.alertReason ?? AppStrings.get('status_normal'), 
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        SensorCard(
          icon: Icons.thermostat_outlined,
          label: AppStrings.get('air_temp'),
          value: '${_currentData?.temperatureAir.toStringAsFixed(1)}°C',
          color: Colors.orange,
        ),
        SensorCard(
          icon: Icons.water_outlined,
          label: AppStrings.get('air_hum'),
          value: '${_currentData?.humidityAir.toStringAsFixed(0)}%',
          color: Colors.blue,
        ),
        SensorCard(
          icon: Icons.grass_outlined,
          label: AppStrings.get('soil_moist'),
          value: '${_currentData?.soilMoisture}%',
          color: Colors.brown[400]!,
        ),
        SensorCard(
          icon: Icons.sensors_outlined,
          label: AppStrings.get('soil_temp'),
          value: '${_currentData?.soilTemperature.toStringAsFixed(1)}°C',
          color: Colors.deepOrange[300]!,
        ),
      ],
    );
  }

  Widget _buildPowerCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: (_currentData?.batteryPercent ?? 0) / 100,
                    strokeWidth: 5,
                    backgroundColor: Colors.grey[100],
                    color: (_currentData?.batteryPercent ?? 0) < 20 ? Colors.red : Colors.green[400],
                  ),
                ),
                Text('${_currentData?.batteryPercent}%', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${AppStrings.get('battery')}: ${_currentData?.batteryVoltage.toStringAsFixed(2)}V',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(
                    _currentData?.solarCharging ?? false ? AppStrings.get('solar_charging') : AppStrings.get('on_battery'),
                    style: TextStyle(
                      color: _currentData?.solarCharging ?? false ? Colors.amber[800] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _currentData?.solarCharging ?? false ? Icons.wb_sunny_outlined : Icons.battery_std_outlined,
              color: Colors.amber[800],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            child: Center(child: Icon(Icons.agriculture_outlined, size: 80, color: Colors.white)),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: Text(AppStrings.get('nav_dashboard')),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.psychology_outlined),
            title: Text(AppStrings.get('nav_advisor')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => AdvisorScreen(currentData: _currentData?.toJson())));
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: Text(AppStrings.get('nav_stats')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StatsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(AppStrings.get('nav_config')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ConfigScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: Text(AppStrings.get('nav_logs')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LogsScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(AppStrings.get('nav_lang')),
            onTap: () {
              setState(() {
                AppStrings.toggleLang();
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green[800]),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
