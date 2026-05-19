import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart'; // Profil sayfanın import adı farklıysa burayı düzenleyebilirsin
import 'add_transaction_page.dart'; // Ekleme sayfasının import adı farklıysa burayı düzenleyebilirsin

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final response = await Supabase.instance.client
          .from('transactions')
          .select()
          .eq('user_id', user?.id ?? '')
          .order('created_at', ascending: false);

      setState(() {
        _transactions = response as List<dynamic>;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veriler çekilirken hata oluştu: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _calculateTotalBalance() {
    double balance = 0.0;
    for (var tx in _transactions) {
      final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
      final isDebt = tx['is_debt'] as bool? ?? false;
      final desc = tx['description'].toString();

      if (desc.startsWith("[MAAŞ]")) {
        balance += amount; 
      } else if (isDebt) {
        balance += amount; 
      } else {
        balance -= amount; 
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

      if (desc.contains("kumbara")) {
        if (tx['description'].toString().startsWith("[MAAŞ]")) {
          savings -= amount;
        } else if (!isDebt) {
          savings += amount;
        }
      }
    }
    return savings;
  }

  double _calculateTotalDebts() {
    double totalDebts = 0.0;
    for (var tx in _transactions) {
      final isDebt = tx['is_debt'] as bool? ?? false;
      final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;

      if (isDebt) {
        totalDebts += amount; 
      }
    }
    return totalDebts < 0 ? 0.0 : totalDebts;
  }

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
              await Supabase.instance.client.from('transactions').insert({
                'user_id': user?.id,
                'amount': amount,
                'description': isAdding ? "Kumbara: Birikim" : "[MAAŞ] Kumbara: Çekilen",
                'is_debt': false,
                'created_at': DateTime.now().toIso8601String(),
              });

              if (mounted) {
                Navigator.pop(context);
                _fetchTransactions();
              }
            },
            child: const Text("Onayla", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBorcOdeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Borç Ödemesi Yap"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Ödenecek Tutar (TL)", border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final amount = double.tryParse(controller.text.trim());
              if (amount == null || amount <= 0) return;

              final user = Supabase.instance.client.auth.currentUser;
              await Supabase.instance.client.from('transactions').insert({
                'user_id': user?.id,
                'amount': -amount, 
                'description': "Borç Ödemesi Yapıldı",
                'is_debt': true, 
                'created_at': DateTime.now().toIso8601String(),
              });

              if (mounted) {
                Navigator.pop(context);
                _fetchTransactions();
              }
            },
            child: const Text("Ödemeyi Onayla", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBalance = _calculateTotalBalance();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bütçe & Borç Takibi"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // NET GÜNCEL BAKİYE KARTI
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: totalBalance >= 0 
                          ? [Colors.teal.shade400, Colors.teal.shade700]
                          : [Colors.red.shade400, Colors.red.shade700],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Net Güncel Bakiye",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${totalBalance.toStringAsFixed(2)} TL",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // KUMBARA KARTI
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                        ),
                          ),
                        ],
                      ),
                      const Icon(Icons.savings, color: Colors.white, size: 36),
                    ],
                  ),
                ),

                // KUMBARA BUTONLARI
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade50),
                          icon: const Icon(Icons.add, color: Colors.purple, size: 18),
                          label: const Text("Kumbaraya At", style: TextStyle(color: Colors.purple, fontSize: 12)),
                          onPressed: () => _showKumbaraDialog(true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade50),
                          icon: const Icon(Icons.remove, color: Colors.purple, size: 18),
                          label: const Text("Kumbaradan Çek", style: TextStyle(color: Colors.purple, fontSize: 12)),
                          onPressed: () => _showKumbaraDialog(false),
                        ),
                      ),
                    ],
                  ),
                ),

                // BORÇ KARTI
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade600, Colors.orange.shade900],
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
                            "Ödenmesi Gereken Toplam Borç",
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_calculateTotalDebts().toStringAsFixed(2)} TL",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.handshake, color: Colors.white, size: 36),
                    ],
                  ),
                ),

                // BORÇ ÖDE BUTONU
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade50),
                      icon: const Icon(Icons.payment, color: Colors.orange, size: 18),
                      label: const Text("Borç Ödemesi Yap", style: TextStyle(color: Colors.orange, fontSize: 12)),
                      onPressed: _showBorcOdeDialog,
                    ),
                  ),
                ),
                
                const Divider(height: 16),

                // İŞLEMLER LİSTESİ 
                Expanded(
                  child: _transactions.isEmpty
                      ? const Center(child: Text("Henüz bir kayıt eklenmedi."))
                      : ListView.builder(
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final tx = _transactions[index];
                            final isDebt = tx['is_debt'] as bool? ?? false;
                            
                            final createdAtRaw = tx['created_at'] != null 
                                ? DateTime.parse(tx['created_at'].toString()).toLocal()
                                : DateTime.now();
                            final dateStr = "${createdAtRaw.day.toString().padLeft(2, '0')}/${createdAtRaw.month.toString().padLeft(2, '0')}/${createdAtRaw.year}";
                            final timeStr = "${createdAtRaw.hour.toString().padLeft(2, '0')}:${createdAtRaw.minute.toString().padLeft(2, '0')}";

                            final desc = tx['description'] ?? "Açıklama Yok";
                            final isMaaS = desc.startsWith("[MAAŞ]");
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
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              elevation: 1,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: avatarBg,
                                  child: Icon(leadingIcon, color: iconColor, size: 20),
                                ),
                                title: Text(
                                  cleanDesc,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text("$dateStr - $timeStr", style: const TextStyle(fontSize: 11)), 
                                trailing: Text(
                                  "$prefix${tx['amount'].toString().replaceAll('-', '')} TL",
                                  style: TextStyle(
                                    color: iconColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
    
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTransactionPage(), 
            ),
          );
          if (result == true) {
            _fetchTransactions(); 
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}