import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sensor_data.dart';
import '../services/api_service.dart';
import '../widgets/sensor_card.dart';
import 'advisor_screen.dart';
import 'config_screen.dart';
import 'logs_screen.dart';

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
  DateTime? _lastFetchTime;

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
          // Note: _isOnline stays false until a fresh fetch succeeds
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
    setState(() => _isLoading = _currentData == null); // Only show spinner if no data at all
    
    final health = await _apiService.checkHealth();
    if (health) {
      final data = await _apiService.fetchStatus();
      if (data != null) {
        setState(() {
          _currentData = data;
          _isOnline = true;
          _isLoading = false;
          _lastFetchTime = DateTime.now();
        });
        await _saveToCache(data);
      }
    } else {
      setState(() {
        _isOnline = false;
        _isLoading = false;
      });
      // We keep _currentData (the cached version)
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
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.green[800],
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('AgriShield Dashboard', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Colors.green[900]!, Colors.green[700]!],
                    ),
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: 0.2,
                      child: Icon(Icons.agriculture, size: 120, color: Colors.white),
                    ),
                  ),
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
                  : _buildOfflineView(), // Only show strictly offline view if NO cache exists
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
          const Text('Première Connexion Requise', 
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Connectez-vous au Wi-Fi AgriShield pour synchroniser les données initiales.', 
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _refreshData, 
            icon: const Icon(Icons.sync),
            label: const Text('Tenter la synchronisation'),
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
              const SectionHeader(title: 'Environnement Actuel', icon: Icons.eco),
              const SizedBox(height: 12),
              _buildSensorGrid(),
              const SizedBox(height: 24),
              const SectionHeader(title: 'État de l\'Énergie', icon: Icons.bolt),
              const SizedBox(height: 12),
              _buildPowerCard(),
              const SizedBox(height: 80), // Bottom padding
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: Colors.amber[100],
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 16, color: Colors.amber[900]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode Hors Ligne : Affichage des données enregistrées',
              style: TextStyle(color: Colors.amber[900], fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: _refreshData,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
            child: const Text('Actualiser', style: TextStyle(fontSize: 12)),
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
        color: alertColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: alertColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: alertColor, shape: BoxShape.circle),
                child: const Icon(Icons.shield, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Niveau de Risque : ${_currentData?.alertLevel}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: alertColor)),
                    const Text('Système de Protection AgriShield', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          if (_currentData?.alertReason.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _currentData!.alertReason,
                style: const TextStyle(height: 1.4, fontSize: 14),
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
          icon: Icons.thermostat,
          label: 'Temp. Air',
          value: '${_currentData?.temperatureAir.toStringAsFixed(1)}°C',
          color: Colors.orange,
        ),
        SensorCard(
          icon: Icons.water_drop,
          label: 'Humidité Air',
          value: '${_currentData?.humidityAir.toStringAsFixed(0)}%',
          color: Colors.blue,
        ),
        SensorCard(
          icon: Icons.grass,
          label: 'Humidité Sol',
          value: '${_currentData?.soilMoisture}%',
          color: Colors.brown[400]!,
        ),
        SensorCard(
          icon: Icons.sensors,
          label: 'Temp. Sol',
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
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: (_currentData?.batteryPercent ?? 0) / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey[100],
                    color: (_currentData?.batteryPercent ?? 0) < 20 ? Colors.red : Colors.green[400],
                  ),
                ),
                Text('${_currentData?.batteryPercent}%', 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Batterie : ${_currentData?.batteryVoltage.toStringAsFixed(2)}V',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    _currentData?.solarCharging ?? false ? '⚡ Recharge Solaire Active' : 'Utilisation de la batterie',
                    style: TextStyle(
                      color: _currentData?.solarCharging ?? false ? Colors.amber[800] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _currentData?.solarCharging ?? false ? Icons.wb_sunny : Icons.battery_std,
              color: Colors.amber[800],
              size: 30,
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
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.green[800]),
            accountName: const Text('AgriShield v1.0', style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: const Text('Protection Intelligente de Plantation'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.agriculture, size: 40, color: Colors.green),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: const Text('Tableau de Bord'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.psychology_rounded),
            title: const Text('Conseiller Agricole'),
            subtitle: const Text('Analyses & Météo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => AdvisorScreen(currentData: _currentData?.toJson())));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_suggest_rounded),
            title: const Text('Configuration Cultures'),
            subtitle: const Text('Sélectionner Maize, Cacao...'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ConfigScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_edu_rounded),
            title: const Text('Journal Historique'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LogsScreen()));
            },
          ),
          const Divider(),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('AgriShield © 2026', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const SectionHeader({super.key, required this.title, required this.icon});

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

}
