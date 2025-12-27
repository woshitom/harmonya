import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/firebase_config.dart';
import 'theme/app_theme.dart';
import 'pages/landing_page.dart';
import 'pages/admin_panel_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure web plugins
  usePathUrlStrategy();

  // Load environment variables from .env file (if available)
  // This is optional - values can also come from --dart-define flags
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env file not found, that's okay - will use --dart-define values
    debugPrint(
      'Note: .env file not found. Using --dart-define values or defaults.',
    );
  }

  // Initialize date formatting for French locale
  await initializeDateFormatting('fr_FR', null);

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: FirebaseConfig.apiKey,
        authDomain: FirebaseConfig.authDomain,
        projectId: FirebaseConfig.projectId,
        storageBucket: FirebaseConfig.storageBucket,
        messagingSenderId: FirebaseConfig.messagingSenderId,
        appId: FirebaseConfig.appId,
        measurementId: FirebaseConfig.measurementId,
      ),
    );
    
    // Log Firebase initialization status
    if (FirebaseConfig.isConfigured) {
      debugPrint('✅ Firebase initialized successfully');
      debugPrint('   Project ID: ${FirebaseConfig.projectId}');
      debugPrint('   Auth Domain: ${FirebaseConfig.authDomain}');
      debugPrint('   Current URL: ${Uri.base}');
      debugPrint('   Host: ${Uri.base.host}');
      debugPrint('   Port: ${Uri.base.port}');
    } else {
      debugPrint('⚠️ Firebase config incomplete. Some values may be missing.');
    }

    // Initialize Firebase Analytics
    try {
      final analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(true);
      debugPrint('✅ Firebase Analytics initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Firebase Analytics initialization warning: $e');
      // Don't rethrow - Analytics is not critical for app functionality
    }
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
    rethrow;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Create Firebase Analytics instance
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harmonya',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr', 'FR'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      // Enable automatic screen tracking
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder to reactively listen to auth state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Check current user synchronously for immediate check
        final User? user = FirebaseAuth.instance.currentUser;

        // Use snapshot data if available, otherwise fall back to currentUser
        final User? currentUser = snapshot.hasData ? snapshot.data : user;

        if (currentUser != null) {
          // User is logged in, show admin panel
          return const AdminPanelPage();
        } else {
          // User is not logged in, show landing page
          return const LandingPage();
        }
      },
    );
  }
}
