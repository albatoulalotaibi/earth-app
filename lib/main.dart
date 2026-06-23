import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/app_preferences.dart'; 
import 'core/routing/app_router.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // الحصول على التوكن بطريقة آمنة
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('auth_token');
  
  // تحديد المسار الأولي: إذا التوكن موجود افتح الرئيسية، إذا لا افتح الترحيب
  final String initialRoute = (token != null && token.isNotEmpty) 
      ? AppRouter.mainShell 
      : AppRouter.intro;
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppPreferences(),
      child: ErthApp(initialRoute: initialRoute),
    ),
  );
}

class ErthApp extends StatelessWidget {
  final String initialRoute;
  const ErthApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppPreferences>(
      builder: (context, appPrefs, child) {
        return MaterialApp(
          title: 'Erth',
          debugShowCheckedModeBanner: false,

          theme: ThemeData.light(useMaterial3: true), 
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: appPrefs.themeMode, 

          locale: appPrefs.locale,
          supportedLocales: const [
            Locale('en', ''), 
            Locale('ar', ''), 
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: initialRoute, // 👈 استخدام المسار المحدد
        );
      },
    );
  }
}