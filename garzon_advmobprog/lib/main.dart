import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'models/user.dart';
import 'services/user_service.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
    await dotenv.load(fileName: 'assets/.env');
  } on Object catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'application initialization',
      ),
    );
  }

  runApp(const GarzonAdvMobProg());
}

class GarzonAdvMobProg extends StatelessWidget {
  const GarzonAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        Provider<UserService>(
          create: (_) => UserService(),
          dispose: (_, UserService service) => service.close(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(412, 915),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          final ThemeProvider themeProvider = context.watch<ThemeProvider>();

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'NU Exchange',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
            initialRoute: SplashScreen.routeName,
            routes: <String, WidgetBuilder>{
              SplashScreen.routeName: (_) => const SplashScreen(),
              SignInScreen.routeName: (_) => const SignInScreen(),
              HomeScreen.routeName: (BuildContext context) {
                final Object? user = ModalRoute.of(context)?.settings.arguments;
                return user is User
                    ? HomeScreen(user: user)
                    : const SplashScreen();
              },
              SettingsScreen.routeName: (_) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
