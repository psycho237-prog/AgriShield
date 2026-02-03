/*
 * AgriShield ESP32-C3 Firmware
 * Solar-Powered Agricultural Risk Monitoring System
 *
 * Hardware:
 * - ESP32-C3
 * - 2x DHT22 (Air & Soil)
 * - Capacitive Soil Moisture Sensor
 * - DS18B20 Temperature Sensor
 * - OLED Display (128x64 I2C)
 * - 3x LEDs (Green, Orange, Red)
 * - Buzzer
 * - 3.7V Li-Ion Battery + Solar Panel
 *
 * Features:
 * - Local WiFi AP with REST API
 * - Real-time sensor monitoring
 * - Alert system (GREEN/ORANGE/RED)
 * - Data logging to SPIFFS
 * - Deep sleep power management
 * - Configurable crop profiles
 */

#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <DallasTemperature.h>
#include <OneWire.h>
#include <Preferences.h>
#include <SPIFFS.h>
#include <WebServer.h>
#include <WiFi.h>
#include <Wire.h>

// ==================== PIN DEFINITIONS ====================
#define DHT_AIR_PIN 4       // DHT22 for air temp/humidity
#define DHT_SOIL_PIN 5      // DHT22 for soil temp/humidity (optional)
#define DS18B20_PIN 6       // DS18B20 soil temperature
#define SOIL_MOISTURE_PIN 1 // Analog pin for capacitive sensor
#define BATTERY_PIN 0       // Analog pin for battery voltage
#define LED_GREEN_PIN 7
#define LED_ORANGE_PIN 8
#define LED_RED_PIN 9
#define BUZZER_PIN 10
#define I2C_SDA 2
#define I2C_SCL 3

// ==================== SENSOR OBJECTS ====================
#define DHTTYPE DHT22
DHT dhtAir(DHT_AIR_PIN, DHTTYPE);
DHT dhtSoil(DHT_SOIL_PIN, DHTTYPE);

OneWire oneWire(DS18B20_PIN);
DallasTemperature ds18b20(&oneWire);

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

WebServer server(80);
Preferences preferences;

// ==================== CROP PROFILE DEFINITIONS ====================
struct CropProfile {
  const char *id;
  const char *name;
  int humidityWarning;
  int humidityCritical;
  int temperatureMax;
  int soilMoistureMin;
  int soilMoistureMax;
};

// Predefined crop profiles (15+ categories)
const CropProfile CROP_PROFILES[] = {
    // VEGETABLES - Open Field
    {"TOMATO_OPEN_FIELD", "Tomato (Open Field)", 70, 85, 35, 30, 70},
    {"PEPPER_OPEN_FIELD", "Pepper (Open Field)", 65, 80, 32, 35, 75},
    {"ONION", "Onion", 60, 75, 30, 25, 60},
    {"CABBAGE", "Cabbage", 75, 90, 28, 40, 80},
    {"LETTUCE", "Lettuce", 75, 90, 28, 40, 80},
    {"CARROT", "Carrot", 65, 80, 30, 30, 70},
    {"POTATO", "Potato", 70, 85, 30, 35, 75},
    {"CUCUMBER", "Cucumber", 75, 90, 35, 40, 80},

    // VEGETABLES - Greenhouse
    {"TOMATO_GREENHOUSE", "Tomato (Greenhouse)", 75, 90, 32, 35, 75},
    {"PEPPER_GREENHOUSE", "Pepper (Greenhouse)", 70, 85, 30, 40, 80},

    // FRUITS
    {"BANANA", "Banana", 75, 90, 38, 40, 85},
    {"MANGO", "Mango", 60, 75, 40, 25, 60},
    {"PAPAYA", "Papaya", 70, 85, 38, 35, 75},
    {"PINEAPPLE", "Pineapple", 65, 80, 35, 30, 70},
    {"CITRUS", "Citrus (Orange/Lemon)", 60, 75, 38, 30, 70},
    {"AVOCADO", "Avocado", 65, 80, 35, 35, 75},

    // CEREALS & GRAINS
    {"MAIZE_CORN", "Maize/Corn", 65, 80, 38, 30, 70},
    {"RICE", "Rice", 80, 95, 38, 50, 90},
    {"WHEAT", "Wheat", 60, 75, 35, 25, 65},
    {"SORGHUM", "Sorghum", 55, 70, 40, 20, 60},
    {"MILLET", "Millet", 55, 70, 40, 20, 60},

    // LEGUMES
    {"BEANS", "Beans", 65, 80, 32, 30, 70},
    {"PEAS", "Peas", 70, 85, 28, 35, 75},
    {"GROUNDNUT_PEANUT", "Groundnut/Peanut", 60, 75, 35, 25, 65},
    {"SOYBEAN", "Soybean", 70, 85, 35, 35, 75},

    // CASH CROPS
    {"COFFEE", "Coffee", 75, 90, 30, 40, 80},
    {"COCOA", "Cocoa", 80, 95, 32, 45, 85},
    {"TEA", "Tea", 75, 90, 32, 40, 80},
    {"COTTON", "Cotton", 60, 75, 40, 25, 65},
    {"SUGARCANE", "Sugarcane", 75, 90, 38, 40, 85},
    {"TOBACCO", "Tobacco", 65, 80, 35, 30, 70},

    // TUBERS & ROOTS
    {"CASSAVA", "Cassava", 65, 80, 38, 25, 65},
    {"SWEET_POTATO", "Sweet Potato", 70, 85, 35, 30, 70},
    {"YAM", "Yam", 70, 85, 35, 30, 75},

    // HERBS & SPICES
    {"GINGER", "Ginger", 75, 90, 32, 40, 80},
    {"GARLIC", "Garlic", 60, 75, 30, 25, 65},
    {"CHILI_PEPPER", "Chili Pepper", 65, 80, 35, 30, 70},

    // GENERAL/DEFAULT
    {"GENERAL_CROP", "General Crop", 70, 85, 35, 30, 70},
    {"CUSTOM", "Custom (Manual Settings)", 70, 85, 35, 30, 70}};

const int CROP_PROFILE_COUNT = sizeof(CROP_PROFILES) / sizeof(CropProfile);

// ==================== CONFIGURATION ====================
struct Config {
  char deviceId[20] = "AS-001-237";
  char cropProfileId[30] = "TOMATO_OPEN_FIELD";
  int samplingIntervalMinutes = 60;
  int humidityWarning = 70;
  int humidityCritical = 85;
  int temperatureMax = 35;
  int soilMoistureMin = 30;
  int soilMoistureMax = 70;
} config;

// ==================== CROP PROFILE FUNCTIONS ====================
bool applyCropProfile(const char *profileId) {
  for (int i = 0; i < CROP_PROFILE_COUNT; i++) {
    if (strcmp(CROP_PROFILES[i].id, profileId) == 0) {
      // Apply profile thresholds
      config.humidityWarning = CROP_PROFILES[i].humidityWarning;
      config.humidityCritical = CROP_PROFILES[i].humidityCritical;
      config.temperatureMax = CROP_PROFILES[i].temperatureMax;
      config.soilMoistureMin = CROP_PROFILES[i].soilMoistureMin;
      config.soilMoistureMax = CROP_PROFILES[i].soilMoistureMax;

      Serial.printf("✅ Applied profile: %s (%s)\n", CROP_PROFILES[i].name,
                    CROP_PROFILES[i].id);
      Serial.printf(
          "   Humidity: %d%% / %d%% | Temp: %d°C | Soil: %d%% - %d%%\n",
          config.humidityWarning, config.humidityCritical,
          config.temperatureMax, config.soilMoistureMin,
          config.soilMoistureMax);

      return true;
    }
  }

  Serial.printf("⚠️  Profile '%s' not found - using custom settings\n",
                profileId);
  return false;
}

// ==================== SENSOR DATA ====================
struct SensorData {
  float tempAir = 0.0;
  float humidityAir = 0.0;
  float tempSoil = 0.0;
  int soilMoisture = 0;
  float batteryVoltage = 0.0;
  int batteryPercent = 0;
  bool solarCharging = false;
  String alertLevel = "GREEN";
  String alertReason = "";
  unsigned long timestamp = 0;
} currentData;

// ==================== GLOBAL STATE ====================
const char *firmwareVersion = "1.0.0";
unsigned long bootTime = 0;
unsigned long lastSensorRead = 0;
unsigned long lastDataLog = 0;
const unsigned long SENSOR_READ_INTERVAL = 10000; // 10 seconds
const char *AP_SSID = "AgriShield-AP";
const char *AP_PASS = "agrishield2026";

// ==================== SETUP ====================
void setup() {
  Serial.begin(115200);
  bootTime = millis();

  Serial.println("\n\n🌱 AgriShield ESP32-C3 Starting...");

  // Initialize pins
  pinMode(LED_GREEN_PIN, OUTPUT);
  pinMode(LED_ORANGE_PIN, OUTPUT);
  pinMode(LED_RED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(SOIL_MOISTURE_PIN, INPUT);
  pinMode(BATTERY_PIN, INPUT);

  // Test LEDs
  testLEDs();

  // Initialize I2C
  Wire.begin(I2C_SDA, I2C_SCL);

  // Initialize OLED
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("❌ OLED init failed");
  } else {
    Serial.println("✅ OLED initialized");
    displayBootScreen();
  }

  // Initialize sensors
  dhtAir.begin();
  dhtSoil.begin();
  ds18b20.begin();
  Serial.println("✅ Sensors initialized");

  // Initialize SPIFFS
  if (!SPIFFS.begin(true)) {
    Serial.println("❌ SPIFFS mount failed");
  } else {
    Serial.println("✅ SPIFFS mounted");
  }

  // Load configuration
  loadConfig();

  // Start WiFi AP
  WiFi.mode(WIFI_AP);
  WiFi.softAP(AP_SSID, AP_PASS);
  IPAddress IP = WiFi.softAPIP();
  Serial.print("📡 AP IP: ");
  Serial.println(IP);

  // Setup web server routes
  setupRoutes();
  server.begin();
  Serial.println("✅ Web server started");

  // Initial sensor read
  readSensors();
  updateDisplay();
}

// ==================== MAIN LOOP ====================
void loop() {
  server.handleClient();

  // Read sensors periodically
  if (millis() - lastSensorRead >= SENSOR_READ_INTERVAL) {
    readSensors();
    evaluateAlertLevel();
    updateDisplay();
    updateLEDs();

    lastSensorRead = millis();
  }

  // Log data periodically (based on config)
  if (millis() - lastDataLog >= (config.samplingIntervalMinutes * 60000UL)) {
    logDataToFile();
    lastDataLog = millis();
  }

  delay(100);
}

// ==================== SENSOR READING ====================
void readSensors() {
  // Read DHT22 Air
  currentData.tempAir = dhtAir.readTemperature();
  currentData.humidityAir = dhtAir.readHumidity();

  // Read DS18B20 Soil Temperature
  ds18b20.requestTemperatures();
  currentData.tempSoil = ds18b20.getTempCByIndex(0);

  // Read Soil Moisture (analog)
  int rawMoisture = analogRead(SOIL_MOISTURE_PIN);
  currentData.soilMoisture =
      map(rawMoisture, 4095, 0, 0, 100); // Invert & map to %

  // Read Battery Voltage
  int rawBattery = analogRead(BATTERY_PIN);
  currentData.batteryVoltage =
      (rawBattery / 4095.0) * 3.3 * 2.0; // Voltage divider
  currentData.batteryPercent = map(
      constrain(currentData.batteryVoltage * 100, 320, 420), 320, 420, 0, 100);

  // Detect solar charging (simple heuristic)
  currentData.solarCharging = (currentData.batteryVoltage > 3.9);

  currentData.timestamp = millis();

  // Debug output
  Serial.printf("🌡️  Air: %.1f°C | 💧 Humidity: %.1f%% | 🌱 Soil: %d%% | 🔋 "
                "%.2fV (%d%%)\n",
                currentData.tempAir, currentData.humidityAir,
                currentData.soilMoisture, currentData.batteryVoltage,
                currentData.batteryPercent);
}

// ==================== ALERT EVALUATION ====================
void evaluateAlertLevel() {
  String previousLevel = currentData.alertLevel;
  currentData.alertLevel = "GREEN";
  currentData.alertReason = "Normal conditions";

  // Check critical conditions (RED)
  if (isnan(currentData.tempAir) || isnan(currentData.humidityAir)) {
    currentData.alertLevel = "RED";
    currentData.alertReason = "Sensor failure";
  } else if (currentData.tempAir > config.temperatureMax) {
    currentData.alertLevel = "RED";
    currentData.alertReason = "Heat stress";
  } else if (currentData.humidityAir >= config.humidityCritical) {
    currentData.alertLevel = "RED";
    currentData.alertReason = "Critical humidity - disease risk";
  } else if (currentData.soilMoisture < config.soilMoistureMin) {
    currentData.alertLevel = "RED";
    currentData.alertReason = "Severe drought";
  }
  // Check warning conditions (ORANGE)
  else if (currentData.humidityAir >= config.humidityWarning) {
    currentData.alertLevel = "ORANGE";
    currentData.alertReason = "High humidity - monitor closely";
  } else if (currentData.soilMoisture < (config.soilMoistureMin + 10)) {
    currentData.alertLevel = "ORANGE";
    currentData.alertReason = "Low soil moisture";
  } else if (currentData.tempAir > (config.temperatureMax - 5)) {
    currentData.alertLevel = "ORANGE";
    currentData.alertReason = "High temperature";
  }

  // Alert on level change
  if (currentData.alertLevel != previousLevel) {
    Serial.printf("⚠️  Alert level changed: %s → %s (%s)\n",
                  previousLevel.c_str(), currentData.alertLevel.c_str(),
                  currentData.alertReason.c_str());

    if (currentData.alertLevel == "RED") {
      soundBuzzer(3); // 3 beeps for critical
    } else if (currentData.alertLevel == "ORANGE") {
      soundBuzzer(1); // 1 beep for warning
    }
  }
}

// ==================== LED CONTROL ====================
void updateLEDs() {
  digitalWrite(LED_GREEN_PIN, currentData.alertLevel == "GREEN");
  digitalWrite(LED_ORANGE_PIN, currentData.alertLevel == "ORANGE");
  digitalWrite(LED_RED_PIN, currentData.alertLevel == "RED");
}

void testLEDs() {
  digitalWrite(LED_GREEN_PIN, HIGH);
  delay(200);
  digitalWrite(LED_GREEN_PIN, LOW);
  digitalWrite(LED_ORANGE_PIN, HIGH);
  delay(200);
  digitalWrite(LED_ORANGE_PIN, LOW);
  digitalWrite(LED_RED_PIN, HIGH);
  delay(200);
  digitalWrite(LED_RED_PIN, LOW);
}

// ==================== BUZZER CONTROL ====================
void soundBuzzer(int beeps) {
  for (int i = 0; i < beeps; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(100);
    digitalWrite(BUZZER_PIN, LOW);
    delay(100);
  }
}

// ==================== DISPLAY FUNCTIONS ====================
void displayBootScreen() {
  display.clearDisplay();
  display.setTextSize(2);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 10);
  display.println("AgriShield");
  display.setTextSize(1);
  display.setCursor(0, 35);
  display.println("Initializing...");
  display.display();
  delay(2000);
}

void updateDisplay() {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);

  // Line 1: Device ID
  display.setCursor(0, 0);
  display.print(config.deviceId);

  // Line 2: Temperature
  display.setCursor(0, 12);
  display.print("Temp: ");
  display.print(currentData.tempAir, 1);
  display.print("C");

  // Line 3: Humidity
  display.setCursor(0, 24);
  display.print("Humidity: ");
  display.print(currentData.humidityAir, 0);
  display.print("%");

  // Line 4: Soil Moisture
  display.setCursor(0, 36);
  display.print("Soil: ");
  display.print(currentData.soilMoisture);
  display.print("%");

  // Line 5: Battery
  display.setCursor(0, 48);
  display.print("Bat: ");
  display.print(currentData.batteryVoltage, 2);
  display.print("V ");
  if (currentData.solarCharging)
    display.print("[+]");

  // Alert indicator
  display.setCursor(90, 0);
  if (currentData.alertLevel == "GREEN")
    display.print("[OK]");
  else if (currentData.alertLevel == "ORANGE")
    display.print("[!]");
  else
    display.print("[!!]");

  display.display();
}

// ==================== WEB SERVER ROUTES ====================
void setupRoutes() {
  server.on("/health", HTTP_GET, handleHealth);
  server.on("/ping", HTTP_GET, handlePing);
  server.on("/status", HTTP_GET, handleStatus);
  server.on("/data/log", HTTP_GET, handleDataLog);
  server.on("/config", HTTP_GET, handleConfigGet);
  server.on("/config", HTTP_POST, handleConfigPost);
  server.onNotFound(handle404);

  // Enable CORS
  server.enableCORS(true);
}

void handleHealth() {
  StaticJsonDocument<256> doc;
  doc["status"] = "OK";
  doc["uptime_ms"] = millis() - bootTime;
  doc["firmware_version"] = firmwareVersion;

  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void handlePing() { server.send(200, "application/json", "{\"pong\":true}"); }

void handleStatus() {
  StaticJsonDocument<512> doc;
  doc["device_id"] = config.deviceId;
  doc["alert_level"] = currentData.alertLevel;
  doc["temperature_air"] = currentData.tempAir;
  doc["humidity_air"] = currentData.humidityAir;
  doc["soil_moisture"] = currentData.soilMoisture;
  doc["soil_temperature"] = currentData.tempSoil;
  doc["battery_voltage"] = currentData.batteryVoltage;
  doc["battery_percent"] = currentData.batteryPercent;
  doc["solar_charging"] = currentData.solarCharging;
  doc["timestamp"] = currentData.timestamp;
  doc["alert_reason"] = currentData.alertReason;

  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void handleDataLog() {
  File file = SPIFFS.open("/datalog.json", "r");
  if (!file) {
    server.send(404, "application/json", "{\"error\":\"No data log found\"}");
    return;
  }

  server.streamFile(file, "application/json");
  file.close();
}

void handleConfigGet() {
  StaticJsonDocument<512> doc;
  doc["crop_profile_id"] = config.cropProfileId;
  doc["sampling_interval_minutes"] = config.samplingIntervalMinutes;

  JsonObject thresholds = doc.createNestedObject("alert_thresholds");
  thresholds["humidity_warning"] = config.humidityWarning;
  thresholds["humidity_critical"] = config.humidityCritical;
  thresholds["temperature_max"] = config.temperatureMax;
  thresholds["soil_moisture_min"] = config.soilMoistureMin;
  thresholds["soil_moisture_max"] = config.soilMoistureMax;

  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void handleConfigPost() {
  if (!server.hasArg("plain")) {
    server.send(400, "application/json", "{\"error\":\"No body\"}");
    return;
  }

  StaticJsonDocument<512> doc;
  DeserializationError error = deserializeJson(doc, server.arg("plain"));

  if (error) {
    server.send(400, "application/json", "{\"error\":\"Invalid JSON\"}");
    return;
  }

  bool profileApplied = false;

  // Update crop profile ID and auto-apply if it's a predefined profile
  if (doc.containsKey("crop_profile_id")) {
    const char *newProfileId = doc["crop_profile_id"];
    strlcpy(config.cropProfileId, newProfileId, sizeof(config.cropProfileId));

    // Try to apply predefined profile (auto-sets thresholds)
    profileApplied = applyCropProfile(newProfileId);
  }

  // Update sampling interval
  if (doc.containsKey("sampling_interval_minutes")) {
    config.samplingIntervalMinutes = doc["sampling_interval_minutes"];
  }

  // Manual threshold overrides (only if provided explicitly)
  // This allows custom profiles or fine-tuning of predefined profiles
  if (doc.containsKey("alert_thresholds")) {
    JsonObject thresh = doc["alert_thresholds"];
    if (thresh.containsKey("humidity_warning"))
      config.humidityWarning = thresh["humidity_warning"];
    if (thresh.containsKey("humidity_critical"))
      config.humidityCritical = thresh["humidity_critical"];
    if (thresh.containsKey("temperature_max"))
      config.temperatureMax = thresh["temperature_max"];
    if (thresh.containsKey("soil_moisture_min"))
      config.soilMoistureMin = thresh["soil_moisture_min"];
    if (thresh.containsKey("soil_moisture_max"))
      config.soilMoistureMax = thresh["soil_moisture_max"];

    if (profileApplied) {
      Serial.println(
          "⚠️ Manual thresholds provided - overriding profile defaults");
    }
  }

  saveConfig();

  // Return success with profile info
  String response = "{\"status\":\"CONFIG_APPLIED\",\"reboot_required\":false";
  if (profileApplied) {
    response += ",\"profile_applied\":true";
  }
  response += "}";

  server.send(200, "application/json", response);
}

void handle404() {
  server.send(404, "application/json", "{\"error\":\"Not found\"}");
}

// ==================== DATA LOGGING ====================
void logDataToFile() {
  File file = SPIFFS.open("/datalog.json", "r");
  StaticJsonDocument<8192> doc;

  if (file) {
    deserializeJson(doc, file);
    file.close();
  } else {
    // Initialize new log file
    JsonObject info = doc.createNestedObject("device_info");
    info["device_id"] = config.deviceId;
    info["firmware_version"] = firmwareVersion;
    info["crop_profile_id"] = config.cropProfileId;

    doc.createNestedArray("records");
  }

  // Add new record
  JsonArray records = doc["records"];
  JsonObject record = records.createNestedObject();
  record["timestamp"] = currentData.timestamp;
  record["temperature_air"] = currentData.tempAir;
  record["humidity_air"] = currentData.humidityAir;
  record["soil_moisture"] = currentData.soilMoisture;
  record["soil_temperature"] = currentData.tempSoil;
  record["alert_level"] = currentData.alertLevel;

  // Keep only last 1000 records
  if (records.size() > 1000) {
    records.remove(0);
  }

  // Update power status
  JsonObject power = doc.createNestedObject("power_status");
  power["battery_voltage"] = currentData.batteryVoltage;
  power["battery_level_percent"] = currentData.batteryPercent;
  power["solar_charging"] = currentData.solarCharging;

  // Update last alert
  JsonObject lastAlert = doc.createNestedObject("last_alert");
  lastAlert["level"] = currentData.alertLevel;
  lastAlert["reason"] = currentData.alertReason;
  lastAlert["timestamp"] = currentData.timestamp;

  // Write to file
  file = SPIFFS.open("/datalog.json", "w");
  if (file) {
    serializeJson(doc, file);
    file.close();
    Serial.println("✅ Data logged");
  } else {
    Serial.println("❌ Failed to write log");
  }
}

// ==================== CONFIGURATION PERSISTENCE ====================
void loadConfig() {
  preferences.begin("agrishield", false);

  preferences.getString("deviceId", config.deviceId, sizeof(config.deviceId));
  preferences.getString("cropProfile", config.cropProfileId,
                        sizeof(config.cropProfileId));
  config.samplingIntervalMinutes = preferences.getInt("samplingInt", 60);
  config.humidityWarning = preferences.getInt("humWarn", 70);
  config.humidityCritical = preferences.getInt("humCrit", 85);
  config.temperatureMax = preferences.getInt("tempMax", 35);
  config.soilMoistureMin = preferences.getInt("soilMin", 30);
  config.soilMoistureMax = preferences.getInt("soilMax", 70);

  preferences.end();
  Serial.println("✅ Config loaded");
}

void saveConfig() {
  preferences.begin("agrishield", false);

  preferences.putString("deviceId", config.deviceId);
  preferences.putString("cropProfile", config.cropProfileId);
  preferences.putInt("samplingInt", config.samplingIntervalMinutes);
  preferences.putInt("humWarn", config.humidityWarning);
  preferences.putInt("humCrit", config.humidityCritical);
  preferences.putInt("tempMax", config.temperatureMax);
  preferences.putInt("soilMin", config.soilMoistureMin);
  preferences.putInt("soilMax", config.soilMoistureMax);

  preferences.end();
  Serial.println("✅ Config saved");
}
