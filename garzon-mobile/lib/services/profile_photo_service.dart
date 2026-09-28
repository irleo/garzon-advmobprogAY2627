import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhotoService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pick() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 768,
        maxHeight: 768,
        imageQuality: 85,
        requestFullMetadata: false,
      );
    } on Object {
      rethrow;
    }
  }

  Future<XFile?> recover() async {
    try {
      final LostDataResponse result = await _picker.retrieveLostData();
      if (result.exception != null) throw result.exception!;
      return result.files?.firstOrNull;
    } on Object {
      rethrow;
    }
  }

  Future<Uint8List> prepare(XFile file) async {
    try {
      if (await file.length() > 10 * 1024 * 1024) {
        throw const FormatException('Choose a photo smaller than 10 MB.');
      }
      // Normalize the selected image to a bounded PNG and strip metadata.
      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
        await file.readAsBytes(),
      );
      late final ui.Codec codec;
      try {
        final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(
          buffer,
        );
        try {
          final double scale = math.min(
            1.0,
            256 / math.max(descriptor.width, descriptor.height),
          );
          codec = await descriptor.instantiateCodec(
            targetWidth: math.max(1, (descriptor.width * scale).round()),
            targetHeight: math.max(1, (descriptor.height * scale).round()),
          );
        } finally {
          descriptor.dispose();
        }
      } finally {
        buffer.dispose();
      }
      try {
        final ui.FrameInfo frame = await codec.getNextFrame();
        try {
          final ByteData? data = await frame.image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (data == null || data.lengthInBytes > 5 * 1024 * 1024) {
            throw const FormatException(
              'This photo could not be prepared. Choose another image.',
            );
          }
          return data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    } on Object {
      rethrow;
    }
  }

  Future<String> save(String uid, Uint8List bytes) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != uid) {
        throw StateError('Sign in again before changing your photo.');
      }
      final Reference reference = FirebaseStorage.instance.ref(
        'profilePhotos/$uid/avatar.png',
      );
      await reference.putData(
        bytes,
        SettableMetadata(contentType: 'image/png', cacheControl: 'no-cache'),
      );
      final String downloadUrl = await reference.getDownloadURL();
      final Uri uri = Uri.parse(downloadUrl);
      final String url = uri
          .replace(
            queryParameters: <String, String>{
              ...uri.queryParameters,
              'v': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          )
          .toString();
      await user.updatePhotoURL(url);
      return url;
    } on Object {
      rethrow;
    }
  }
}
