import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'add_transaction_page.dart';
import 'profile_page.dart';

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
  double _calculateTotalBalance() {
    double balance = 0.0;
    for (var tx in _transactions) {
      final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
      final isDebt = tx['is_debt'] as bool? ?? false;
      if (isDebt) {
        balance += amount;
      } else {
        balance -= amount;
      }
    }
    return balance;
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
          // Sağ üst köşeye profil butonu ekledik
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            icon: const Icon(Icons.person, color: Colors.blue),
          ),
        ],
      ),
    body: _isLoading
    ? const Center(child: CircularProgressIndicator())
    : Column(
        children: [
          // GÜNCEL BAKİYE KARTI
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _calculateTotalBalance() >= 0 
                    ? [Colors.teal.shade400, Colors.teal.shade700]
                    : [Colors.red.shade400, Colors.red.shade700],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Net Güncel Bakiye",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "${_calculateTotalBalance().toStringAsFixed(2)} TL",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // İŞLEMLER LİSTESİ
          Expanded(
            child: _transactions.isEmpty
                ? const Center(child: Text("Henüz bir kayıt eklenmedi."))
                : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final tx = _transactions[index];
                      final isDebt = tx['is_debt'] as bool? ?? false;
                      
                      // Tarih bilgisini formatlama
                      final createdAtRaw = tx['created_at'] != null 
                          ? DateTime.parse(tx['created_at'].toString()).toLocal()
                          : DateTime.now();
                      final dateStr = "${createdAtRaw.day.toString().padLeft(2, '0')}/${createdAtRaw.month.toString().padLeft(2, '0')}/${createdAtRaw.year}";
                      final timeStr = "${createdAtRaw.hour.toString().padLeft(2, '0')}:${createdAtRaw.minute.toString().padLeft(2, '0')}";

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDebt ? Colors.green.shade100 : Colors.red.shade100,
                            child: Icon(
                              isDebt ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isDebt ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(
                            tx['description'] ?? "Açıklama Yok",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("$dateStr - $timeStr"), 
                          trailing: Text(
                            "${isDebt ? '+' : '-'}${tx['amount']} TL",
                            style: TextStyle(
                              color: isDebt ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Ekleme sayfasına gidiyoruz ve dönen sonucu bekliyoruz
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionPage()),
          );
          
          // Eğer yeni bir şey eklenip geri dönüldüyse listeyi otomatik yenile
          if (result == true) {
            _fetchTransactions();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}