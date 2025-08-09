import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/content_provider.dart';
import 'core/services/p2p_service.dart';
import 'presentation/screens/home_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 LIVEVAULTHUB - Configuración multiplataforma
  // flutter_inappwebview funciona automáticamente en todas las plataformas
  // No necesita configuración específica por plataforma

  runApp(LiveVaultHubApp());
}

class LiveVaultHubApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),

        // 🚀 P2P Service Provider
        ChangeNotifierProvider(create: (_) => P2PService.instance),
      ],
      child: MaterialApp(
        title: 'LiveVaultHub',
        theme: AppTheme.darkTheme,
        home: HomeScreen(),
        debugShowCheckedModeBanner: false,

        // 🌍 LOCALIZACIÓN INTERNACIONAL
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'), // Español España
          Locale('es', 'MX'), // Español México
          Locale('es', 'AR'), // Español Argentina
          Locale('en', 'US'), // Inglés
        ],

        // Optimizaciones de rendimiento
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // Evitar scaling automático en dispositivos con texto grande
              textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}