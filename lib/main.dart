import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'app.dart';
import 'firebase_options.dart';
import 'helpers/networking/notification_helper.dart';
import 'helpers/theme/app_theme_controller.dart';
import 'helpers/theme/theme_enum.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();
  await initServers();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'i18n',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      saveLocale: true,
      child: ChangeNotifierProvider(create: (context) => AppThemeController()..initial(), child: const MyApp()),
    ),
  );
}

Future<void> initServers() async {
  FirebaseMessaging.onBackgroundMessage(onAppBackground);
  NotificationHelper().initialize();
  await Hive.initFlutter();
  Hive.registerAdapter(ThemeEnumAdapter());
  await Hive.openBox('app');
  timeago.setLocaleMessages('en', timeago.EnMessages());
  timeago.setLocaleMessages('en_short', timeago.EnShortMessages());
  timeago.setLocaleMessages('ar', timeago.ArMessages());
  timeago.setLocaleMessages('ar_short', timeago.ArShortMessages());
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  HttpOverrides.global = MyHttpOverrides();
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> onAppBackground(RemoteMessage message) async => SoundNotification.instance.playSound();
