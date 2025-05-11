import 'package:finanstakip/icerik/abonelik_ekle.dart';
import 'package:finanstakip/icerik/birikim_ekle.dart';
import 'package:finanstakip/icerik/butce_ekle.dart';
import 'package:finanstakip/icerik/harcama_ekle.dart';
import 'package:flutter/material.dart';

class Secenekler extends StatelessWidget {
  const Secenekler({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlemler'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _secenekKareButon(
                      context,
                      icon: Icons.account_balance_wallet,
                      text: 'Bütçe',
                      sayfa: const ButceEkleBaslangic(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _secenekKareButon(
                      context,
                      icon: Icons.attach_money,
                      text: 'Harcama',
                      sayfa: const HarcamaEkleBaslangic(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _secenekKareButon(
                      context,
                      icon: Icons.subscriptions,
                      text: 'Abonelik',
                      sayfa: const AbonelikEkleBaslangic(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _secenekKareButon(
                      context,
                      icon: Icons.flag_circle,
                      text: 'Birikim',
                      sayfa: const BirikimEkleBaslangic(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secenekKareButon(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Widget sayfa,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade300,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(16),
      ),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => sayfa));
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
