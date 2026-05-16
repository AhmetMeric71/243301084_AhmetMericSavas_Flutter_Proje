import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String _userEmail = "";

  @override
  void Environment() {
    super.initState();
    _fetchProfileAndLogs();
  }

  @override
  void initState() {
    super.initState();
    _fetchProfileAndLogs();
  }

  // Hem kullanıcı bilgisini hem de Trigger'ın yazdığı logları çekiyoruz
  Future<void> _fetchProfileAndLogs() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        setState(() {
          _userEmail = user.email ?? "";
        });

        // activity_logs tablosundan bu kullanıcıya ait logları çekiyoruz (Seçme Sorgusu)
        final response = await _supabase
            .from('activity_logs')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        setState(() {
          _logs = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print("Loglar çekilirken hata oluştu: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Çıkış Yapma Fonksiyonu
  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil & Sistem Logları"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _signOut,
            tooltip: "Çıkış Yap",
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ÖDEV BİLGİLERİ KARTI
                  Card(
                    color: Colors.blue.shade50,
                    elevation: 2,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.school, size: 40, color: Colors.blue),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Ahmet Yılmaz", // KENDİ ADINI YAZABİLİRSİN
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Öğrenci No: 123456789", // KENDİ NUMARANI YAZABİLİRSİN
                                style: TextStyle(color: Colors.black54),
                              ),
                              Text(
                                "VTYS & Mobil Programlama Ödevi",
                                style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text("Aktif Kullanıcı"),
                    subtitle: Text(_userEmail),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    "Veritabanı Tetikleyici (Trigger) Logları",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 8),
                  
                  // LOGLARIN LİSTELENDİĞİ KISIM
                  Expanded(
                    child: _logs.isEmpty
                        ? const Center(child: Text("Henüz bir işlem logu bulunmuyor.\nYeni harcama ekleyerek trigger'ı tetikleyin."))
                        : ListView.builder(
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: const Icon(Icons.bolt, color: Colors.orange),
                                  title: Text("${log['action_type']} İşlemi Tetiklendi"),
                                  subtitle: Text(log['details'] ?? ""),
                                  trailing: Text(
                                    log['created_at'].toString().substring(11, 16),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}