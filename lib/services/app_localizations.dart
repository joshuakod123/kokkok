// lib/services/app_localizations.dart
import 'package:flutter/material.dart';

class AppLocalizations {
  static const List<Locale> supportedLocales = [
    Locale('ko', 'KR'),
    Locale('en', 'US'),
    // ...
  ];

  static const Map<String, Map<String, String>> _localizedValues = {
    'ko': {
      'app_name': '콕콕',
      // ...
    },
    'en': {
      'app_name': 'KokKok',
      // ...
    },
  };

  String getMessage(String key, Locale locale) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}