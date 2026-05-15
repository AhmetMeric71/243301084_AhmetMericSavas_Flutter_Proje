import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions(); // Sayfa açılır açılmaz verileri tablodan çekiyoruz
  }

  // Supabase'den Verileri Çekme Fonksiyonu
  Future<void> _fetchTransactions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // transactions tablosundaki verileri en yeni eklenenden başlayarak çekiyoruz
      final response = await _supabase
          .from('transactions')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _transactions = response;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veriler yüklenirken hata oluştu: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Güvenli Çıkış Yapma Fonksiyonu
  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      // Çıkış yapınca kullanıcıyı Giriş Ekranına geri fırlatıyoruz
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Harcama & Borç Listem"),
        actions: [
          // Sağ üst köşeye çıkış butonu ekledik (Ödev gereksinimi)
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.red),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(
                  child: Text(
                    "Henüz hiç harcama veya borç eklemediniz.\nSağ alttaki + butonundan ekleyin!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final item = _transactions[index];
                    final double amount = item['amount'] is int 
                        ? (item['amount'] as int).toDouble() 
                        : item['amount'];
                    final bool isDebt = item['is_debt'] ?? false;
                    final String description = item['description'] ?? "Açıklama Yok";

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDebt ? Colors.red.shade100 : Colors.green.shade100,
                          child: Icon(
                            isDebt ? Icons.money_off : Icons.shopping_cart,
                            color: isDebt ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(
                          "$amount TL",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text(description),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // İleride buraya Ekleme Sayfası'na giden kodu yazacağız
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Yakında: Yeni Harcama Ekleme Ekranı")),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}