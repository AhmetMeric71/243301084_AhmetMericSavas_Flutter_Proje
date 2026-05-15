import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'home_page.dart';

void main() async {
  // Flutter elementlerinin sorunsuz yüklenmesini sağlar
  WidgetsFlutterBinding.ensureInitialized();

  // BURASI KRİTİK: Supabase bağlantısını başlatıyoruz
  await Supabase.initialize(
    url: 'https://kykjolaanudirklgbbte.supabase.co/rest/v1/',
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
      debugShowCheckedModeBanner: false, // Sağ üstteki kırmızı şeridi kaldırır
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Modern görünüm için
      ),
      // ÖDEV GEREKSİNİMİ: Uygulama açıldığında oturum kontrolü yapar.
      // Eğer kullanıcı daha önce giriş yaptıysa doğrudan Ana Sayfa'ya, yapmadıysa Giriş Sayfası'na yönlendirir.
      home: Supabase.instance.client.auth.currentSession == null
          ? const LoginPage()
          : const HomePage(),
    );
  }
}