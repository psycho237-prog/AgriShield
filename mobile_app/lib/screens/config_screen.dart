import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final ApiService _apiService = ApiService();
  bool _isUpdating = false;
  String? _selectedCrop;

  final List<Map<String, dynamic>> _cropProfiles = [
    {
      'id': 'MAIZE',
      'name_en': 'Maize',
      'name_fr': 'Maïs',
      'icon': Icons.grain_outlined,
      'minMoisture': 40,
      'maxTemp': 35,
      'desc_en': 'Optimized for rapid growth and irrigation control.',
      'desc_fr': 'Optimisé pour la croissance rapide et le contrôle de l\'irrigation.',
    },
    {
      'id': 'COCOA',
      'name_en': 'Cocoa',
      'name_fr': 'Cacaoyer',
      'icon': Icons.park_outlined,
      'minMoisture': 60,
      'maxTemp': 32,
      'desc_en': 'Maintains high soil moisture for young plants.',
      'desc_fr': 'Maintient une humidité élevée du sol pour les jeunes plants.',
    },
    {
      'id': 'TOMATO',
      'name_en': 'Tomato',
      'name_fr': 'Tomate',
      'icon': Icons.agriculture_outlined,
      'minMoisture': 50,
      'maxTemp': 30,
      'desc_en': 'Early alerts for heat stress and wilting.',
      'desc_fr': 'Alertes précoces pour le stress thermique et le flétrissement.',
    },
  ];

  Future<void> _applyProfile(Map<String, dynamic> profile) async {
    setState(() {
      _isUpdating = true;
      _selectedCrop = profile['id'];
    });

    final success = await _apiService.updateConfig({
      'crop_id': profile['id'],
      'min_soil_moisture': profile['minMoisture'],
      'max_air_temp': profile['maxTemp'],
    });

    setState(() => _isUpdating = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('profile_applied')),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('error_module')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('nav_config')),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cropProfiles.length,
        itemBuilder: (context, index) {
          final profile = _cropProfiles[index];
          final isSelected = _selectedCrop == profile['id'];
          final name = AppStrings.currentLang == 'en' ? profile['name_en'] : profile['name_fr'];
          final desc = AppStrings.currentLang == 'en' ? profile['desc_en'] : profile['desc_fr'];

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: isSelected ? Colors.green : Colors.grey[200]!, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                        child: Icon(profile['icon'], color: Colors.green[800]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildParamTag(AppStrings.currentLang == 'en' ? 'Min. Moisture' : 'Humidité Min.', '${profile['minMoisture']}%', Icons.water_drop_outlined),
                      _buildParamTag(AppStrings.currentLang == 'en' ? 'Max. Temp' : 'Temp. Max.', '${profile['maxTemp']}°C', Icons.thermostat_outlined),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : () => _applyProfile(profile),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isUpdating && isSelected
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(AppStrings.get('apply_profile')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParamTag(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.green[700]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
