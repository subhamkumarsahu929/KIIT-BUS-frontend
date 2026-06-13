import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Constants {
  static String googleApiKey = const String.fromEnvironment(
    'GOOGLE_API_KEY',
    defaultValue: '',
  );
  static String directionsKey = const String.fromEnvironment(
    'DIRECTIONS_KEY',
    defaultValue: '',
  );

  static const String _devKey = '';

  static Future<void> init() async {
    if (googleApiKey.isNotEmpty || directionsKey.isNotEmpty) {
      return;
    }

    const assetCandidates = ['secrets.json', 'assets/secrets.json'];
    if (kDebugMode) {
      try {
        final manifestJson = await rootBundle.loadString('AssetManifest.json');
        final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
        final hasRoot = manifest.containsKey('secrets.json');
        final hasAssets = manifest.containsKey('assets/secrets.json');
        print(
          'Constants.init() AssetManifest includes secrets.json=$hasRoot assets/secrets.json=$hasAssets',
        );
      } catch (e) {
        print('Constants.init() failed to read AssetManifest.json: $e');
      }
    }

    for (final assetPath in assetCandidates) {
      try {
        final jsonString = await rootBundle.loadString(assetPath);
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        googleApiKey =
            (data['GOOGLE_API_KEY'] as String?)?.trim() ?? googleApiKey;
        directionsKey =
            (data['DIRECTIONS_KEY'] as String?)?.trim() ?? directionsKey;

        if (googleApiKey.isNotEmpty || directionsKey.isNotEmpty) {
          if (kDebugMode) {
            print('Constants.init() loaded keys from $assetPath');
          }
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Constants.init() asset load failed for $assetPath: $e');
        }
        // Try the next asset path.
      }
    }

    if (kDebugMode) {
      print('Constants.init() did not load any API keys from assets.');
    }
  }

  static String get apiKey {
    final keyFromEnv = directionsKey.isNotEmpty ? directionsKey : googleApiKey;
    if (keyFromEnv.isNotEmpty) {
      return keyFromEnv;
    }

    if (_devKey.isNotEmpty) {
      return _devKey;
    }

    return '';
  }
}
