import 'package:flutter/material.dart';

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
        'title': 'Irrigation Urgente',
        'desc': 'L\'humidité du sol est critique ($moisture%). Arrosez immédiatement pour éviter le flétrissement.',
        'icon': Icons.water_drop,
        'color': Colors.red,
      });
    } else if (moisture < 50) {
      suggestions.add({
        'title': 'Planifier Arrosage',
        'desc': 'Le sol commence à s\'assécher. Un arrosage léger en fin de journée serait bénéfique.',
        'icon': Icons.opacity,
        'color': Colors.orange,
      });
    }

    // Heat Stress
    if (temp > 32) {
      suggestions.add({
        'title': 'Stress Thermique',
        'desc': 'Température élevée ($temp°C). Si possible, activez l\'ombrage ou augmentez l\'humidité ambiante.',
        'icon': Icons.wb_sunny,
        'color': Colors.orange,
      });
    }

    // Disease Risk (High Humidity + Warm Temp)
    if (humidity > 85 && temp > 25) {
      suggestions.add({
        'title': 'Risque de Mildiou',
        'desc': 'Humidité élevée et chaleur favorisent les champignons. Surveillez l\'apparition de taches sur les feuilles.',
        'icon': Icons.bug_report,
        'color': Colors.purple,
      });
    }

    if (suggestions.isEmpty) {
      suggestions.add({
        'title': 'Conditions Optimales',
        'desc': 'Tous les indicateurs sont au vert. Vos plantes s\'épanouissent dans ces conditions.',
        'icon': Icons.check_circle,
        'color': Colors.green,
      });
    }

    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _generateSuggestions();

    return Scaffold(
      appBar: AppBar(title: const Text('Conseiller Agricole AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Analyses et Suggestions', 
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Basé sur les données récoltées par votre module AgriShield.',
            style: TextStyle(color: Colors.grey)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(s['icon'], color: s['color'], size: 40),
        title: Text(s['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(s['desc']),
        ),
      ),
    );
  }

  Widget _buildWeatherPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue[700]!, Colors.blue[400]!]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prévisions Météo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(Icons.cloud, color: Colors.white),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeatherDay(day: 'Demain', icon: Icons.wb_cloudy, temp: '28°C'),
              _WeatherDay(day: 'Ven', icon: Icons.beach_access, temp: '24°C'),
              _WeatherDay(day: 'Sam', icon: Icons.wb_sunny, temp: '31°C'),
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
        const SizedBox(height: 8),
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(temp, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
