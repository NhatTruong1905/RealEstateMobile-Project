import 'package:flutter/foundation.dart';

enum Environment { dev, prod }

class AppConfig {
  static const bool? manualUseRemote = null;

  static const String _envParam = String.fromEnvironment(
    'ENV',
    defaultValue: kReleaseMode ? 'prod' : 'dev',
  );

  static bool get isProduction {
    if (manualUseRemote != null) {
      return manualUseRemote!;
    }
    return _envParam.toLowerCase() == 'prod' || kReleaseMode;
  }

  static Environment get environment =>
      isProduction ? Environment.prod : Environment.dev;

  static const String _springBootRemoteHost =
      'realestatemobile-project-production.up.railway.app';
  static const String _springBootLocalHost = '10.0.2.2:8080';

  static String get springBootBaseUrl {
    if (isProduction) {
      return 'https://$_springBootRemoteHost/api';
    }
    return 'http://$_springBootLocalHost/api';
  }

  static String get springBootWsUrl {
    if (isProduction) {
      return 'wss://$_springBootRemoteHost/ws';
    }
    return 'ws://$_springBootLocalHost/ws';
  }

  static const String _aiRemoteHost =
      'real-estate-ai-production-e985.up.railway.app';
  static const String _aiLocalHost = '10.0.2.2:8000';

  static String get aiBaseUrl {
    if (isProduction) {
      return 'https://$_aiRemoteHost/api';
    }
    return 'http://$_aiLocalHost/api';
  }
}
