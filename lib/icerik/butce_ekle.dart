import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finanstakip/anasayfa.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';

class ButceEkleBaslangic extends StatelessWidget {
  const ButceEkleBaslangic({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bütçe Ekle / Güncelle'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: const ButceEkle(),
    );
  }
}

class ButceEkle extends StatefulWidget {
  const ButceEkle({super.key});

  @override
  State<ButceEkle> createState() => _ButceEkleState();
}

class _ButceEkleState extends State<ButceEkle> {
  final TextEditingController butceController = TextEditingController();
  final TextEditingController aciklamaController = TextEditingController();

  String secilenDonem = 'Aylık';
  bool otomatikSifirlansinMi = false;

  String? mevcutButceDocId;

  @override
  void initState() {
    super.initState();
    mevcutButceyiGetir();
  }

  void mevcutButceyiGetir() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(uid)
            .collection('butce')
            .orderBy('tarih', descending: true)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      setState(() {
        mevcutButceDocId = snapshot.docs.first.id;
        butceController.text = data['tutar'].toString();
        secilenDonem = data['donem'] ?? 'Aylık';
        otomatikSifirlansinMi = data['otomatikSifirlansinMi'] ?? false;
        aciklamaController.text = data['aciklama'] ?? '';
      });
    }
  }

  Future<void> butceKaydetVeyaGuncelle() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final tutarStr = butceController.text.trim();
    final aciklama = aciklamaController.text.trim();

    if (tutarStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir bütçe tutarı girin')),
      );
      return;
    }

    final tutar = double.tryParse(tutarStr) ?? 0;
    final butceVerisi = {
      'tutar': tutar,
      'donem': secilenDonem,
      'otomatikSifirlansinMi': otomatikSifirlansinMi,
      'aciklama': aciklama,
      'tarih': Timestamp.now(),
    };

    try {
      final perform = FirebasePerformance.instance.newTrace("butce_kayit");
      await perform.start();
      final ref = FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(uid)
          .collection('butce');

      if (mevcutButceDocId != null) {
        await ref.doc(mevcutButceDocId).update(butceVerisi);
      } else {
        await ref.add(butceVerisi);
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AnaSayfa()),
      );
      await perform.stop();
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(const SnackBar(content: Text('Bütçe kaydedildi!')));
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Hata oluştu: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Toplam Bütçe',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: butceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Örn: 3000',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Dönem Seçimi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: secilenDonem,
                items:
                    ['Haftalık', 'Aylık', 'Yıllık']
                        .map(
                          (secenek) => DropdownMenuItem(
                            value: secenek,
                            child: Text(secenek),
                          ),
                        )
                        .toList(),
                onChanged: (deger) {
                  setState(() {
                    secilenDonem = deger!;
                  });
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Otomatik sıfırlansın mı?'),
                value: otomatikSifirlansinMi,
                onChanged: (deger) {
                  setState(() {
                    otomatikSifirlansinMi = deger;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Açıklama (isteğe bağlı)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: aciklamaController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Bu bütçeye dair not...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: butceKaydetVeyaGuncelle,
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
