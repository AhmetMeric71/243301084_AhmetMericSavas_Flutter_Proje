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
      final desc = tx['description'].toString();

      if (desc.startsWith("[MAAŞ]")) {
        balance += amount; // Maaş ise bakiyeyi ARTIR
      } else if (isDebt) {
        balance += amount; // Borç alındıysa bakiyeyi ARTIR
      } else {
        balance -= amount; // Normal harcamaysa bakiyeyi AZALT
      }
    }
    return balance;
  }
  double _calculateSavings() {
    double savings = 0.0;
    for (var tx in _transactions) {
      final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
      final desc = tx['description'].toString().toLowerCase();
      final isDebt = tx['is_debt'] as bool? ?? false;

      // Eğer açıklama tamamen "kumbara" ise veya "kumbara" kelimesiyle başlıyorsa
      if (desc.startsWith("kumbara")) {
        if (tx['description'].toString().startsWith("[MAAŞ]")) {
          // Kumbaradan para çekme işlemi (Gelir olarak kaydettireceğiz)
          savings -= amount;
        } else if (!isDebt) {
          // Kumbaraya para atma işlemi (Harcama olarak kaydettireceğiz)
          savings += amount;
        }
      }
    }
    return savings;
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
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,  
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kumbaradaki Toplam Birikim",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_calculateSavings().toStringAsFixed(2)} TL",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.savings, color: Colors.white, size: 40),
              ],
            ),
          ),

          // KUMBARA HIZLI İŞLEM BUTONLARI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade50),
                    icon: const Icon(Icons.add, color: Colors.purple),
                    label: const Text("Kumbaraya At", style: TextStyle(color: Colors.purple)),
                    onPressed: () => _showKumbaraDialog(true), // Para Ekle
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade50),
                    icon: const Icon(Icons.remove, color: Colors.purple),
                    label: const Text("Kumbaradan Çek", style: TextStyle(color: Colors.purple)),
                    onPressed: () => _showKumbaraDialog(false), // Para Çek
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
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
                      final desc = tx['description'] ?? "Açıklama Yok";
                      final isMaaS = desc.startsWith("[MAAŞ]");

                      // Ekranda "[MAAŞ] Maaşım" yerine temiz "Maaşım" görünsün diye yazıyı ayıklıyoruz
                      final cleanDesc = isMaaS ? desc.replaceAll("[MAAŞ] ", "") : desc; 

                      Color avatarBg = Colors.red.shade100;
                      IconData leadingIcon = Icons.arrow_upward;
                      Color iconColor = Colors.red;
                      String prefix = "-";

                      if (isMaaS) {
                        avatarBg = Colors.blue.shade100;
                        leadingIcon = Icons.account_balance_wallet;
                        iconColor = Colors.blue;
                        prefix = "+";
                      } else if (isDebt) {
                        avatarBg = Colors.green.shade100;
                        leadingIcon = Icons.arrow_downward;
                        iconColor = Colors.green;
                        prefix = "+";
                      }
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: avatarBg, // Değişken yaptık
                            child: Icon(leadingIcon, color: iconColor), // Değişken yaptık
                          ),
                          title: Text(
                            cleanDesc, // Ayıklanmış temiz açıklamayı koyduk
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("$dateStr - $timeStr"), 
                          trailing: Text(
                            "$prefix${tx['amount']} TL", // Prefix'i değişken yaptık (+ veya -)
                            style: TextStyle(
                              color: iconColor, // Rengi dinamik yaptık
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
  // Kumbaraya para atma/çekme pop-up penceresi
  void _showKumbaraDialog(bool isAdding) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdding ? "Kumbaraya Para At" : "Kumbaradan Para Çek"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Tutar (TL)", border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () async {
              final amount = double.tryParse(controller.text.trim());
              if (amount == null || amount <= 0) return;

              final user = Supabase.instance.client.auth.currentUser;
              
              // Kumbara mantığına göre veritabanına kayıt atıyoruz
              await Supabase.instance.client.from('transactions').insert({
                'user_id': user?.id,
                'amount': amount,
                // Eğer çekiyorsak bakiye fonksiyonu artı saysın diye [MAAŞ] etiketi koyuyoruz
                'description': isAdding ? "Kumbara: Birikim" : "[MAAŞ] Kumbara: Çekilen",
                'is_debt': false,
                'created_at': DateTime.now().toIso8601String(),
              });

              if (mounted) {
                Navigator.pop(context);
                _fetchTransactions(); // Listeyi ve bakiyeleri yenile
              }
            },
            child: const Text("Onayla", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}