class AppStrings {
  static Map<String, Map<String, String>> translations = {
    'en': {
      'app_title': 'AgriShield',
      'nav_dashboard': 'Dashboard',
      'nav_advisor': 'Agricultural Advisor',
      'nav_config': 'Crop Configuration',
      'nav_logs': 'Historical Logs',
      'nav_stats': 'Trend Analysis',
      'nav_lang': 'Language: English',
      'risk_level': 'Risk Level',
      'status_normal': 'Normal conditions',
      'air_temp': 'Air Temperature',
      'air_hum': 'Air Humidity',
      'soil_moist': 'Soil Moisture',
      'soil_temp': 'Soil Temperature',
      'battery': 'Battery',
      'solar_charging': 'Solar Charging Active',
      'on_battery': 'Operating on Battery',
      'sync_required': 'First Synchronization Required',
      'sync_desc': 'Connect to AgriShield Wi-Fi to synchronize data.',
      'btn_retry': 'Retry Synchronization',
      'offline_mode': 'Offline Mode: Viewing cached data',
      'btn_refresh': 'Refresh',
      'apply_profile': 'Select this profile',
      'profile_applied': 'Profile applied successfully!',
      'error_module': 'Error: Unable to connect to module.',
      'suggestions_title': 'Analysis & Suggestions',
      'suggestions_desc': 'Based on data collected by your module.',
      'weather_title': 'Weather Forecast',
      'trends_title': '24h Trend Analysis',
      'stats_last_24h': 'Last 24 Hours Metrics',
    },
    'fr': {
      'app_title': 'AgriShield',
      'nav_dashboard': 'Tableau de Bord',
      'nav_advisor': 'Conseiller Agricole',
      'nav_config': 'Configuration des Cultures',
      'nav_logs': 'Journal Historique',
      'nav_stats': 'Analyse des Tendances',
      'nav_lang': 'Langue : Français',
      'risk_level': 'Niveau de Risque',
      'status_normal': 'Conditions normales',
      'air_temp': 'Température Air',
      'air_hum': 'Humidité Air',
      'soil_moist': 'Humidité Sol',
      'soil_temp': 'Température Sol',
      'battery': 'Batterie',
      'solar_charging': 'Recharge Solaire Active',
      'on_battery': 'Utilisation de la batterie',
      'sync_required': 'Première Connexion Requise',
      'sync_desc': 'Connectez-vous au Wi-Fi AgriShield pour synchroniser les données initiales.',
      'btn_retry': 'Tenter la synchronisation',
      'offline_mode': 'Mode Hors Ligne : Affichage des données enregistrées',
      'btn_refresh': 'Actualiser',
      'apply_profile': 'Sélectionner ce profil',
      'profile_applied': 'Profil appliqué avec succès !',
      'error_module': 'Erreurs : Impossible de contacter le module.',
      'suggestions_title': 'Analyses et Suggestions',
      'suggestions_desc': 'Basé sur les données récoltées par votre module.',
      'weather_title': 'Prévisions Météo',
      'trends_title': 'Analyse des Tendances 24h',
      'stats_last_24h': 'Métriques des dernières 24 heures',
    },
  };

  static String currentLang = 'en';

  static String get(String key) {
    return translations[currentLang]?[key] ?? key;
  }

  static void toggleLang() {
    currentLang = currentLang == 'en' ? 'fr' : 'en';
  }
}
