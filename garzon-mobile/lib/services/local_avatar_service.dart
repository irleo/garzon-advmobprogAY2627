import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class LocalAvatarService {
  String _key(String accountId) => 'profileAvatar.$accountId';

  Future<String?> load(String accountId) async {
    try {
      return (await SharedPreferences.getInstance()).getString(_key(accountId));
    } on Object {
      rethrow;
    }
  }

  Future<void> save(String accountId, String? selection) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final bool saved = selection == null
          ? await preferences.remove(_key(accountId))
          : await preferences.setString(_key(accountId), selection);
      if (!saved) {
        throw StateError('The avatar could not be saved on this device.');
      }
    } on Object {
      rethrow;
    }
  }

  String photo(Uint8List bytes) {
    if (bytes.length > 512 * 1024) {
      throw const FormatException('Choose a smaller profile photo.');
    }
    return 'photo:${base64Encode(bytes)}';
  }
}
