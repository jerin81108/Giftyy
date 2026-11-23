import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/wedding_provider.dart';
import 'providers/guest_provider.dart';
import 'providers/kyc_provider.dart';
import 'providers/room_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/guest/guest_wedding_screen.dart';
import 'screens/room/room_screen.dart';
import 'screens/room/qr_scanner_screen.dart';
import 'screens/room/create_room_screen.dart';
import 'screens/couple/couple_dashboard_screen.dart';
import 'screens/couple/phone_login_screen.dart';
import 'screens/couple/kyc_verification_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GiftyyApp());
}

class GiftyyApp extends StatelessWidget {
  const GiftyyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WeddingProvider()),
        ChangeNotifierProvider(create: (_) => GuestProvider()),
        ChangeNotifierProvider(create: (_) => KycProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
      ],
      child: MaterialApp(
        title: 'Giftyy - Skip the gifts. Fund the dream',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        // OnGenerateRoute enables clean web URLs like /r/priya-ear-piercing-4821 or /w/aisha-kabir
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');

          // Event Rooms URL matching: /r/:slugOrCode
          if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'r') {
            final slugOrCode = uri.pathSegments[1];
            return MaterialPageRoute(
              builder: (_) => RoomScreen(slugOrCode: slugOrCode),
              settings: settings,
            );
          }

          // Legacy wedding URL matching: /w/:slug
          if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'w') {
            final slug = uri.pathSegments[1];
            return MaterialPageRoute(
              builder: (_) => GuestWeddingScreen(slug: slug),
              settings: settings,
            );
          }

          switch (uri.path) {
            case '/scanner':
              return MaterialPageRoute(builder: (_) => const QrScannerScreen());
            case '/create-room':
              return MaterialPageRoute(builder: (_) => const CreateRoomScreen());
            case '/login':
              return MaterialPageRoute(builder: (_) => const PhoneLoginScreen());
            case '/dashboard':
              return MaterialPageRoute(builder: (_) => const CoupleDashboardScreen());
            case '/kyc':
              return MaterialPageRoute(builder: (_) => const KycVerificationScreen());
            case '/':
            default:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
          }
        },
      ),
    );
  }
}
