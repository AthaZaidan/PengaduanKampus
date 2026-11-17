import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'services/notifikasi_push_service.dart';

import 'firebase_options.dart';
import 'screens/authentication/login_page.dart';
import 'theme/tema_kampus.dart';

@pragma('vm:entry-point')
Future<void> pesanLatar(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (NotifikasiPushService.didukung) {
    FirebaseMessaging.onBackgroundMessage(pesanLatar);
  }
  runApp(const PengaduanKampusApp());
}

class PengaduanKampusApp extends StatelessWidget {
  const PengaduanKampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pengaduan Kampus',
      debugShowCheckedModeBanner: false,
      theme: TemaKampus.bangun(),
      home: const LoginPage(),
    );
  }
}
