import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isDebt = false; // Seçilen tür: harcama mı borç mu?
  bool _isLoading = false;

  // Veritabanına Kayıt Ekleme Fonksiyonu (VTYS için INSERT sorgusu)
  Future<void> _saveTransaction() async {
    final String amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen bir tutar girin!")),
      );
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen geçerli bir sayı girin!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      // Supabase 'transactions' tablosuna veriyi INSERT ediyoruz
      await Supabase.instance.client.from('transactions').insert({
        'user_id': user?.id, // İşlemi yapan kullanıcının ID'si
        'amount': amount,
        'description': _descriptionController.text.trim(),
        'is_debt': _isDebt,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("İşlem başarıyla kaydedildi!")),
        );
        Navigator.pop(context, true); // Sayfayı kapat ve bir önceki sayfaya (Home) 'true' döndür
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kaydedilirken hata oluştu: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni İşlem Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Harcama / Borç Seçimi (Segmented Button veya Switch)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Harcama", style: TextStyle(fontSize: 16)),
                Switch(
                  value: _isDebt,
                  onChanged: (value) {
                    setState(() {
                      _isDebt = value;
                    });
                  },
                  activeColor: Colors.red,
                  inactiveThumbColor: Colors.green,
                ),
                const Text("Borç", style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Tutar (TL)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Açıklama",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _isDebt ? Colors.red.shade400 : Colors.green.shade400,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Kaydet", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}