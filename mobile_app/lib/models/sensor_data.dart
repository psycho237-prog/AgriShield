class SensorData {
  final String deviceId;
  final String alertLevel;
  final double temperatureAir;
  final double humidityAir;
  final int soilMoisture;
  final double soilTemperature;
  final double batteryVoltage;
  final int batteryPercent;
  final bool solarCharging;
  final int timestamp;
  final String alertReason;

  SensorData({
    required this.deviceId,
    required this.alertLevel,
    required this.temperatureAir,
    required this.humidityAir,
    required this.soilMoisture,
    required this.soilTemperature,
    required this.batteryVoltage,
    required this.batteryPercent,
    required this.solarCharging,
    required this.timestamp,
    required this.alertReason,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      deviceId: json['device_id'] ?? 'Unknown',
      alertLevel: json['alert_level'] ?? 'GREEN',
      temperatureAir: (json['temperature_air'] ?? 0.0).toDouble(),
      humidityAir: (json['humidity_air'] ?? 0.0).toDouble(),
      soilMoisture: json['soil_moisture'] ?? 0,
      soilTemperature: (json['soil_temperature'] ?? 0.0).toDouble(),
      batteryVoltage: (json['battery_voltage'] ?? 0.0).toDouble(),
      batteryPercent: json['battery_percent'] ?? 0,
      solarCharging: json['solar_charging'] ?? false,
      timestamp: json['timestamp'] ?? 0,
      alertReason: json['alert_reason'] ?? '',
    );
  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'alert_level': alertLevel,
      'temperature_air': temperatureAir,
      'humidity_air': humidityAir,
      'soil_moisture': soilMoisture,
      'soil_temperature': soilTemperature,
      'battery_voltage': batteryVoltage,
      'battery_percent': batteryPercent,
      'solar_charging': solarCharging,
      'timestamp': timestamp,
      'alert_reason': alertReason,
    };
  }
}
