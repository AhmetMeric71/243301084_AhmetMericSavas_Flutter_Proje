import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  // Verileri Çekme (VTYS Raporu için SELECT sorgusu örneği)
  Future<void> _fetchTransactions() async {
    final response = await supabase
        .from('transactions')
        .select('*, categories(name)') // Join işlemi: Kategori adını da getirir
        .order('created_at', ascending: false);
    
    setState(() {
      _transactions = response;
    });
  }

  // Çıkış İşlemi (Gereksinim: Çıkış yapılabilmelidir)
  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Harcama & Borç Takip"),
        actions: [
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout))
        ],
      ),
      body: _transactions.isEmpty
          ? const Center(child: Text("Henüz kayıt bulunmuyor."))
          : ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final item = _transactions[index];
                return ListTile(
                  leading: Icon(item['is_debt'] ? Icons.money_off : Icons.shopping_cart),
                  title: Text("${item['amount']} TL"),
                  subtitle: Text("${item['categories']['name']} - ${item['description'] ?? ''}"),
                  trailing: Text(item['created_at'].toString().substring(0, 10)),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () { /* Ekleme sayfasına git */ },
        child: const Icon(Icons.add),
      ),
    );
  }
}