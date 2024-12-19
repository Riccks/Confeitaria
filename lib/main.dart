import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'telas/login.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://xxbwklrehavmacscosio.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4YndrbHJlaGF2bWFjc2Nvc2lvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjUzODU2OTMsImV4cCI6MjA0MDk2MTY5M30.bBJsisIei03EeEte9UZ0yFT263ejmXd0ptsGEXhrJAI',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFF1E0F9),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF65558F)),
            bodyLarge: TextStyle(color: Color(0xFF65558F)),
            bodySmall: TextStyle(color: Color(0xFF65558F)),
          )),
      title: 'confeitaria',
      home: const TelaLogin(),
    );
  }
}
