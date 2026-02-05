import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
      'name': 'Maïs (Maize)',
      'icon': Icons.grain,
      'minMoisture': 40,
      'maxTemp': 35,
      'description': 'Optimisé pour la croissance rapide et le contrôle de l\'irrigation.',
    },
    {
      'id': 'COCOA',
      'name': 'Cacaoyer (Cocoa)',
      'icon': Icons.Park,
      'minMoisture': 60,
      'maxTemp': 32,
      'description': 'Maintient une humidité élevée du sol pour les jeunes plants.',
    },
    {
      'id': 'TOMATO',
      'name': 'Tomate (Tomato)',
      'icon': Icons.Agriculture,
      'minMoisture': 50,
      'maxTemp': 30,
      'description': 'Alertes précoces pour le stress thermique et le flétrissement.',
    },
    {
      'id': 'OTHER',
      'name': 'Générique (Custom)',
      'icon': Icons.settings_input_component,
      'minMoisture': 30,
      'maxTemp': 40,
      'description': 'Paramètres standards pour tout autre type de plantation.',
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
          content: Text('Profil ${profile['name']} appliqué avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur : Impossible de contacter le module AgriShield.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration des Cultures'),
        backgroundColor: Colors.green[800],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _cropProfiles.length,
            itemBuilder: (context, index) {
              final profile = _cropProfiles[index];
              final isSelected = _selectedCrop == profile['id'];

              return Card(
                elevation: isSelected ? 4 : 1,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: isSelected ? Colors.green : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green[50],
                            child: Icon(profile['icon'], color: Colors.green[800]),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile['name'],
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  profile['description'],
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildParamTag('Humidité Min.', '${profile['minMoisture']}%', Icons.water_drop),
                          _buildParamTag('Temp. Max.', '${profile['maxTemp']}°C', Icons.thermostat),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : () => _applyProfile(profile),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isUpdating && isSelected
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Sélectionner ce profil'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_isUpdating)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildParamTag(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.green[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
