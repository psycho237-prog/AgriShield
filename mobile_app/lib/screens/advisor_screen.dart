import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';

class AdvisorScreen extends StatelessWidget {
  final Map<String, dynamic>? currentData;

  const AdvisorScreen({super.key, this.currentData});

  List<Map<String, dynamic>> _generateSuggestions() {
    if (currentData == null) return [];
    
    List<Map<String, dynamic>> suggestions = [];
    
    double temp = (currentData!['temperature_air'] ?? 0.0).toDouble();
    int moisture = (currentData!['soil_moisture'] ?? 0);
    double humidity = (currentData!['humidity_air'] ?? 0.0).toDouble();

    // Irrigation Logic
    if (moisture < 30) {
      suggestions.add({
        'title': AppStrings.currentLang == 'en' ? 'Urgent Irrigation' : 'Irrigation Urgente',
        'desc': AppStrings.currentLang == 'en' ? 'Soil moisture is critical. Water immediately.' : 'L\'humidité du sol est critique. Arrosez immédiatement.',
        'icon': Icons.water_drop_outlined,
        'color': Colors.red,
      });
    }

    if (temp > 32) {
      suggestions.add({
        'title': AppStrings.currentLang == 'en' ? 'Heat Stress' : 'Stress Thermique',
        'desc': AppStrings.currentLang == 'en' ? 'High temperature detected. Provide shade.' : 'Température élevée détectée. Prévoyez de l\'ombre.',
        'icon': Icons.wb_sunny_outlined,
        'color': Colors.orange,
      });
    }

    if (suggestions.isEmpty) {
      suggestions.add({
        'title': AppStrings.currentLang == 'en' ? 'Optimal Conditions' : 'Conditions Optimales',
        'desc': AppStrings.currentLang == 'en' ? 'All metrics are within target range.' : 'Toutes les métriques sont dans la plage cible.',
        'icon': Icons.check_circle_outline,
        'color': Colors.green,
      });
    }

    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _generateSuggestions();

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('nav_advisor'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(AppStrings.get('suggestions_title'), 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(AppStrings.get('suggestions_desc'),
            style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ...suggestions.map((s) => _buildSuggestionCard(s)).toList(),
          const SizedBox(height: 24),
          _buildWeatherPreview(),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(s['icon'], color: s['color'], size: 36),
        title: Text(s['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(s['desc'], style: const TextStyle(fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildWeatherPreview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.get('weather_title'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Icon(Icons.cloud_outlined, color: Colors.white),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeatherDay(day: 'Tomorrow', icon: Icons.cloud_outlined, temp: '28°C'),
              _WeatherDay(day: 'Fri', icon: Icons.beach_access_outlined, temp: '24°C'),
              _WeatherDay(day: 'Sat', icon: Icons.wb_sunny_outlined, temp: '31°C'),
            ],
          )
        ],
      ),
    );
  }
}

class _WeatherDay extends StatelessWidget {
  final String day;
  final IconData icon;
  final String temp;
  const _WeatherDay({required this.day, required this.icon, required this.temp});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(day, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 12),
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 12),
        Text(temp, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
