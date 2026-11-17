import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

class NotifikasiPushService {
  static final instance = NotifikasiPushService();
  String? _uid;
  String? _token;
  StreamSubscription<String>? _refresh;
  StreamSubscription<RemoteMessage>? _pesan;
  StreamSubscription<RemoteMessage>? _buka;
  static bool get didukung =>
      !kIsWeb &&
      [
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform);
  String _id(String token) =>
      base64Url.encode(utf8.encode(token)).replaceAll('=', '');

  Future<void> _simpan(String uid, String token) async {
    if (_uid != uid) return;
    await FirebaseFirestore.instance
        .doc('users/$uid/devices/${_id(token)}')
        .set({'token': token, 'updatedAt': FieldValue.serverTimestamp()});
    _token = token;
  }

  Future<void> hubungkan(
    AppUser user, {
    required VoidCallback onBuka,
    required void Function(String) onPesan,
  }) async {
    hentikan();
    if (!didukung) return;
    _uid = user.uid;
    _pesan = FirebaseMessaging.onMessage.listen((m) {
      if (_uid == user.uid) {
        onPesan(m.notification?.body ?? 'Ada pembaruan laporan.');
      }
    });
    _buka = FirebaseMessaging.onMessageOpenedApp.listen((_) {
      if (_uid == user.uid) onBuka();
    });
    // Backend menggunakan registration token untuk sendEachForMulticast.
    // ignore: deprecated_member_use
    _refresh = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      unawaited(_simpan(user.uid, token).catchError((Object _) {}));
    });
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (_uid == user.uid && initial != null) onBuka();
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _simpan(user.uid, token);
    }
  }

  Future<void> aktifkan(AppUser user) async {
    if (!didukung) {
      throw StateError(
        'Push tersedia pada Android/iOS. Notifikasi dalam aplikasi tetap dapat digunakan.',
      );
    }
    final izin = await FirebaseMessaging.instance.requestPermission();
    if (izin.authorizationStatus == AuthorizationStatus.denied) {
      throw StateError(
        'Izin notifikasi belum diberikan. Aktifkan melalui pengaturan perangkat.',
      );
    }
    _uid = user.uid;
    // ignore: deprecated_member_use
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      throw StateError(
        'Token notifikasi belum tersedia. Periksa konfigurasi perangkat.',
      );
    }
    await _simpan(user.uid, token);
  }

  void hentikan() {
    _uid = null;
    _refresh?.cancel();
    _pesan?.cancel();
    _buka?.cancel();
  }

  Future<void> keluar() async {
    final uid = _uid, token = _token;
    if (!didukung) {
      hentikan();
      return;
    }
    if (uid != null && token != null) {
      await FirebaseFirestore.instance
          .doc('users/$uid/devices/${_id(token)}')
          .delete();
    }
    // ignore: deprecated_member_use
    await FirebaseMessaging.instance.deleteToken();
    hentikan();
    _token = null;
  }
}
