import 'package:flutter_dotenv/flutter_dotenv.dart';

const String fallbackApiHost = 'https://dummyjson.com';

String get apiHost {
  try {
    final String configuredHost = dotenv.env['HOST']?.trim() ?? '';
    return configuredHost.isEmpty ? fallbackApiHost : configuredHost;
  } on Object {
    return fallbackApiHost;
  }
}
