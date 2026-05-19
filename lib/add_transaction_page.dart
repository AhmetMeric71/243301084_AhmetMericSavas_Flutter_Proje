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
  
  // 0: Harcama, 1: Borç, 2: Maaş/Gelir
  int _selectedType = 0; 
  bool _isLoading = false;

  Future<void> _saveTransaction() async {
    final amountText = _amountController.text.trim();
    final descriptionText = _descriptionController.text.trim();

    if (amountText.isEmpty || descriptionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun!")),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen geçerli bir sayı girin!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      // Türlere göre veritabanına nasıl yazılacağını belirliyoruz
      bool isDebt = _selectedType == 1;
      String finalDescription = descriptionText;
      
      if (_selectedType == 2) {
        // Eğer Maaş/Gelir seçildiyse başına etiket koyuyoruz
        finalDescription = "[MAAŞ] $descriptionText";
      }

      await Supabase.instance.client.from('transactions').insert({
        'user_id': user?.id,
        'amount': amount,
        'description': finalDescription,
        'is_debt': isDebt,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context, true); // Başarılıysa geri dön
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kaydedilirken hata oluştu: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni İşlem Ekle")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // İŞLEM TÜRÜ SEÇİMİ (Segmented Button / Üçlü Seçenek)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text("Harcama"),
                        selected: _selectedType == 0,
                        selectedColor: Colors.red.shade100,
                        onSelected: (val) => setState(() => _selectedType = 0),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Borç Alındı"),
                        selected: _selectedType == 1,
                        selectedColor: Colors.green.shade100,
                        onSelected: (val) => setState(() => _selectedType = 1),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Maaş/Gelir"),
                        selected: _selectedType == 2,
                        selectedColor: Colors.blue.shade100,
                        onSelected: (val) => setState(() => _selectedType = 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: "Tutar (TL)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Açıklama",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedType == 0 
                            ? Colors.red 
                            : (_selectedType == 1 ? Colors.green : Colors.blue),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saveTransaction,
                      child: const Text("Kaydet", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}