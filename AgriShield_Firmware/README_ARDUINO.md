# 🛠️ Arduino IDE Setup Guide

This guide will help you compile and upload the AgriShield firmware using the standard **Arduino IDE**.

## 1. Preparation
Download and install the **[Arduino IDE](https://www.arduino.cc/en/software)** (v2.x recommended).

## 2. Install ESP32 Board Support
1. Open Arduino IDE.
2. Go to **File** → **Preferences**.
3. In the "Additional Boards Manager URLs" field, paste the following URL:
   `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
4. Click **OK**.
5. Go to **Tools** → **Board** → **Boards Manager...**.
6. Search for **ESP32** and install the version by **Espressif Systems**.

## 3. Install Required Libraries
Go to **Tools** → **Manage Libraries...** and search for/install the following:

- **ArduinoJson** (by Benoit Blanchon)
- **DHT sensor library** (by Adafruit)
- **Adafruit Unified Sensor** (dependency for DHT)
- **OneWire** (by Paul Stoffregen)
- **DallasTemperature** (by Miles Burton)
- **Adafruit SSD1306** (by Adafruit)
- **Adafruit GFX Library** (dependency for SSD1306)

## 4. Hardware Selection
1. Go to **Tools** → **Board** → **esp32** → Select **ESP32C3 Dev Module**.
2. Go to **Tools** → **Port** and select the port where your ESP32-C3 is connected.
3. Ensure the following settings are active in the **Tools** menu:
   - **Flash Mode**: `QIO`
   - **Partition Scheme**: `Default 4MB with SPIFFS` (Crucial for data logging!)
   - **CPU Frequency**: `160MHz`

## 5. Compile and Upload
1. Open the file `AgriShield_Firmware.ino` located in this folder.
2. Click the **Verify** (Checkmark) button to compile and check for errors.
3. Click the **Upload** (Arrow) button to flash the firmware to your device.
4. Open the **Serial Monitor** (**Tools** → **Serial Monitor**) and set the baud rate to **115200** to see system logs.

---
**🌱 AgriShield Project**
