import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase başlatılamadı: $e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('tr'), Locale('en')],
      path: 'assets/langs',
      fallbackLocale: const Locale('en'),
      child: const FlashShowApp(),
    ),
  );
}

class FlashShowApp extends StatelessWidget {
  const FlashShowApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DatabaseService()),
      ],
      child: MaterialApp(
        title: 'Flash Show',
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: Colors.grey[900],
        ),
        home: Consumer<AuthService>(
          builder: (context, authService, _) {
            if (authService.isAuthenticated) {
              return const HomeScreen();
            } else {
              return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}
