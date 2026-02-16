import 'package:aiworkflowautomation/splash.dart';
import 'package:aiworkflowautomation/theme/theme_provider.dart';
import 'package:aiworkflowautomation/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiworkflowautomation/controller/language_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final languageProvider = LanguageProvider();
  await languageProvider.loadLanguage(const Locale('en'));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => languageProvider),
      ],
      child: const ElegantRoleLoginApp(),
    ),
  );
}

class ElegantRoleLoginApp extends StatelessWidget {
  const ElegantRoleLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Role Login (Teacher/Student)',
      theme: LightTheme.theme,
      darkTheme: DarkTheme.theme,
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
