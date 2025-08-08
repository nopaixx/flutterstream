import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/content_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(LiveVaultHubApp());
}

class LiveVaultHubApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
      ],
      child: MaterialApp(
        title: 'LiveVaultHub',
        theme: AppTheme.darkTheme,
        home: HomeScreen(), // Siempre carga la home screen
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}