import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.4.1';

  Future<SensorData?> fetchStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/status')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return SensorData.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching status: $e');
    }
    return null;
  }

  Future<bool> updateConfig(Map<String, dynamic> config) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/config'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(config),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating config: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchLog() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/data/log')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error fetching logs: $e');
    }
    return null;
  }

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
