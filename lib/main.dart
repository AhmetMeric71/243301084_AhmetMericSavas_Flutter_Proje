import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kykjolaanudirklgbbte.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5a2pvbGFhbnVkaXJrbGdiYnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDc3NjEsImV4cCI6MjA5NDE4Mzc2MX0.TsM6hmRyf9MwHo6Y3hdPsVPbLnqvUC1sz1uXMrjznBU',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harcama ve Borç Takip',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Supabase.instance.client.auth.currentSession == null
          ? const LoginPage()
          : const HomePage(),
    );
  }
}