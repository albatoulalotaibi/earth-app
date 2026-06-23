import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

/// Root widget of the Erth application.
class ErthApp extends StatelessWidget {
  const ErthApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Erth - إرث',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.intro,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
