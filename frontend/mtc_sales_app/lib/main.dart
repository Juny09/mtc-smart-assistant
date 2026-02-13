import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_sales_app/core/theme/app_theme.dart';
import 'package:mtc_sales_app/core/auth/login_screen.dart';

void main() {
  runApp(const ProviderScope(child: MtcSalesApp()));
}

class MtcSalesApp extends StatelessWidget {
  const MtcSalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTC Sales',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(), // Start with Login
      debugShowCheckedModeBanner: false,
    );
  }
}
