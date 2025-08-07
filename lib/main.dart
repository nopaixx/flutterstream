import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/content_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(NetflixCloneApp());
}

class NetflixCloneApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Netflix Clone',
            theme: AppTheme.darkTheme,
            home: authProvider.isLoggedIn ? HomeScreen() : LoginScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}