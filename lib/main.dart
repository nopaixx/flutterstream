import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/content_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'core/theme/app_theme.dart';

//import 'dart:html' as html; // Para usar IFrameElement en Web

// Este import SOLO existe en Web, así que se usa con kIsWeb
// y no rompe Android/iOS
//import 'dart:ui_web' as ui;

void main() {
  WidgetsFlutterBinding.ensureInitialized();


    if (WebViewPlatform.instance is! AndroidWebViewPlatform) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }


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
        home: HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
