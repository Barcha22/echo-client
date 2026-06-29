import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';

class Glint extends StatelessWidget {
  const Glint({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Glint",
      themeMode: ThemeMode.system,
      navigatorKey: AppNavigator.navigatorKey,
      initialRoute: AppRoutes.authCheck,
      onGenerateRoute: AppRoutes.generateRoute, 
    );
  }
}