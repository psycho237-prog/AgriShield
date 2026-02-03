#!/usr/bin/env python3
"""
AgriShield ESP32 API Test Script
Tests all REST endpoints and validates responses
"""

import requests
import json
import time
from datetime import datetime

# Configuration
ESP32_IP = "192.168.4.1"
BASE_URL = f"http://{ESP32_IP}"

def print_header(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")

def test_health():
    print_header("Testing /health endpoint")
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(json.dumps(data, indent=2))
        
        # Validate
        assert data["status"] == "OK", "Health check failed"
        assert "uptime_ms" in data, "Missing uptime"
        assert "firmware_version" in data, "Missing firmware version"
        print("✅ Health check PASSED")
        return True
    except Exception as e:
        print(f"❌ Health check FAILED: {e}")
        return False

def test_ping():
    print_header("Testing /ping endpoint")
    try:
        response = requests.get(f"{BASE_URL}/ping", timeout=5)
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(json.dumps(data, indent=2))
        
        assert data["pong"] == True, "Ping failed"
        print("✅ Ping test PASSED")
        return True
    except Exception as e:
        print(f"❌ Ping test FAILED: {e}")
        return False

def test_status():
    print_header("Testing /status endpoint")
    try:
        response = requests.get(f"{BASE_URL}/status", timeout=5)
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(json.dumps(data, indent=2))
        
        # Validate required fields
        required_fields = [
            "device_id", "alert_level", "temperature_air",
            "humidity_air", "soil_moisture", "battery_voltage",
            "battery_percent", "solar_charging", "timestamp"
        ]
        
        for field in required_fields:
            assert field in data, f"Missing field: {field}"
        
        # Validate alert level
        assert data["alert_level"] in ["GREEN", "ORANGE", "RED"], "Invalid alert level"
        
        print("✅ Status check PASSED")
        return True
    except Exception as e:
        print(f"❌ Status check FAILED: {e}")
        return False

def test_data_log():
    print_header("Testing /data/log endpoint")
    try:
        response = requests.get(f"{BASE_URL}/data/log", timeout=5)
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 404:
            print("⚠️  No data log found (expected on first boot)")
            return True
        
        data = response.json()
        print(f"Records count: {len(data.get('records', []))}")
        print(f"Device ID: {data.get('device_info', {}).get('device_id')}")
        
        # Show latest record
        if data.get("records"):
            latest = data["records"][-1]
            print("\nLatest Record:")
            print(json.dumps(latest, indent=2))
        
        print("✅ Data log check PASSED")
        return True
    except Exception as e:
        print(f"❌ Data log check FAILED: {e}")
        return False

def test_config_get():
    print_header("Testing GET /config endpoint")
    try:
        response = requests.get(f"{BASE_URL}/config", timeout=5)
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(json.dumps(data, indent=2))
        
        # Validate structure
        assert "crop_profile_id" in data, "Missing crop_profile_id"
        assert "sampling_interval_minutes" in data, "Missing sampling_interval"
        assert "alert_thresholds" in data, "Missing alert_thresholds"
        
        print("✅ Config GET PASSED")
        return data
    except Exception as e:
        print(f"❌ Config GET FAILED: {e}")
        return None

def test_config_post():
    print_header("Testing POST /config endpoint")
    try:
        # First get current config
        current_config = test_config_get()
        if not current_config:
            return False
        
        # Modify config
        new_config = {
            "crop_profile_id": "TEST_PROFILE",
            "sampling_interval_minutes": 30,
            "alert_thresholds": {
                "humidity_warning": 75,
                "humidity_critical": 90,
                "temperature_max": 32,
                "soil_moisture_min": 35,
                "soil_moisture_max": 75
            }
        }
        
        print("\nSending new configuration:")
        print(json.dumps(new_config, indent=2))
        
        response = requests.post(
            f"{BASE_URL}/config",
            json=new_config,
            headers={"Content-Type": "application/json"},
            timeout=5
        )
        
        print(f"\nStatus Code: {response.status_code}")
        data = response.json()
        print(json.dumps(data, indent=2))
        
        assert data["status"] == "CONFIG_APPLIED", "Config not applied"
        
        # Verify config was saved
        time.sleep(1)
        verify_response = requests.get(f"{BASE_URL}/config", timeout=5)
        verify_data = verify_response.json()
        
        assert verify_data["crop_profile_id"] == "TEST_PROFILE", "Config not saved"
        
        print("✅ Config POST PASSED")
        
        # Restore original config
        print("\nRestoring original configuration...")
        requests.post(
            f"{BASE_URL}/config",
            json=current_config,
            headers={"Content-Type": "application/json"},
            timeout=5
        )
        
        return True
    except Exception as e:
        print(f"❌ Config POST FAILED: {e}")
        return False

def test_continuous_monitoring(duration=30):
    print_header(f"Continuous Monitoring ({duration}s)")
    print("Monitoring sensor values in real-time...\n")
    
    start_time = time.time()
    try:
        while (time.time() - start_time) < duration:
            response = requests.get(f"{BASE_URL}/status", timeout=5)
            data = response.json()
            
            timestamp = datetime.now().strftime("%H:%M:%S")
            print(f"[{timestamp}] "
                  f"Temp: {data['temperature_air']:.1f}°C | "
                  f"Humidity: {data['humidity_air']:.0f}% | "
                  f"Soil: {data['soil_moisture']}% | "
                  f"Alert: {data['alert_level']} | "
                  f"Battery: {data['battery_voltage']:.2f}V ({data['battery_percent']}%)")
            
            time.sleep(2)
        
        print("\n✅ Continuous monitoring completed")
        return True
    except KeyboardInterrupt:
        print("\n⚠️  Monitoring interrupted by user")
        return True
    except Exception as e:
        print(f"\n❌ Monitoring FAILED: {e}")
        return False

def run_all_tests():
    print("\n" + "="*60)
    print("  🌱 AgriShield ESP32 API Test Suite")
    print("="*60)
    print(f"Target: {BASE_URL}")
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    results = {
        "Health Check": test_health(),
        "Ping Test": test_ping(),
        "Status Check": test_status(),
        "Data Log": test_data_log(),
        "Config GET": test_config_get() is not None,
        "Config POST": test_config_post(),
    }
    
    # Summary
    print_header("Test Summary")
    passed = sum(results.values())
    total = len(results)
    
    for test_name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{test_name:.<40} {status}")
    
    print(f"\n{'='*60}")
    print(f"Results: {passed}/{total} tests passed ({(passed/total)*100:.0f}%)")
    print(f"{'='*60}\n")
    
    # Optional: Run continuous monitoring
    if passed == total:
        choice = input("All tests passed! Run continuous monitoring? (y/n): ")
        if choice.lower() == 'y':
            test_continuous_monitoring(30)

if __name__ == "__main__":
    try:
        run_all_tests()
    except KeyboardInterrupt:
        print("\n\n⚠️  Tests interrupted by user")
    except Exception as e:
        print(f"\n\n❌ Fatal error: {e}")
