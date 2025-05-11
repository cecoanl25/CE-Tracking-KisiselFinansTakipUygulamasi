import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';

class BirikimEkleBaslangic extends StatelessWidget {
  const BirikimEkleBaslangic({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Birikim Hedefi'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: const BirikimEkle(),
    );
  }
}

class BirikimEkle extends StatefulWidget {
  const BirikimEkle({super.key});

  @override
  State<BirikimEkle> createState() => _BirikimEkleState();
}

class _BirikimEkleState extends State<BirikimEkle> {
  final TextEditingController hedefAdiController = TextEditingController();
  final TextEditingController hedefTutarController = TextEditingController();

  String? hedefId;
  double? mevcutDurum;

  double? sonButce;
  double? secilenOran;
  double? aylikMiktar;
  int? tahminiAy;
  DateTime? tahminiBitis;

  @override
  void initState() {
    super.initState();
    butceyiGetir();
    mevcutHedefiGetir();
  }

  void butceyiGetir() async {
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
      setState(() {
        sonButce = snapshot.docs.first.data()['tutar']?.toDouble() ?? 0;
      });
    }
  }

  Future<void> mevcutHedefiGetir() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(uid)
            .collection('hedefbutce')
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      setState(() {
        hedefId = snapshot.docs.first.id;
        hedefAdiController.text = data['hedefAdi'] ?? '';
        hedefTutarController.text = data['hedefTutar'].toString();
        mevcutDurum = (data['mevcutDurum'] ?? 0).toDouble();
        secilenOran = (data['oran'] ?? 0).toDouble();
        aylikMiktar = (data['aylikMiktar'] ?? 0).toDouble();
        tahminiAy = (data['tahminiAy'] ?? 0).toInt();
        final bitis = data['tahminiBitis'];
        if (bitis is Timestamp) tahminiBitis = bitis.toDate();
      });
    }
  }

  Future<void> hedefiKaydetVeyaGuncelle() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final hedefAdi = hedefAdiController.text.trim();
    final hedefTutar = double.tryParse(hedefTutarController.text.trim());

    if (hedefAdi.isEmpty ||
        hedefTutar == null ||
        secilenOran == null ||
        aylikMiktar == null ||
        tahminiAy == null ||
        tahminiBitis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları ve oranı doldurun!')),
      );
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(uid)
        .collection('hedefbutce');

    final veri = {
      'hedefAdi': hedefAdi,
      'hedefTutar': hedefTutar,
      'mevcutDurum': mevcutDurum ?? aylikMiktar,
      'oran': secilenOran,
      'aylikMiktar': aylikMiktar,
      'tahminiAy': tahminiAy,
      'tahminiBitis': tahminiBitis,
      'kayitTarihi': Timestamp.now(),
    };

    try {
      final perform = FirebasePerformance.instance.newTrace("birikim_kayit");
      await perform.start();
      if (hedefId != null) {
        await ref.doc(hedefId).update(veri);
      } else {
        await ref.add(veri);
      }
      await perform.stop();

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Birikim hedefi kaydedildi')),
      );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Hedef Adı'),
            const SizedBox(height: 8),
            TextField(
              controller: hedefAdiController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Örn: Tatil, Bilgisayar...',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Hedef Tutarı'),
            const SizedBox(height: 8),
            TextField(
              controller: hedefTutarController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Örn: 10000',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            if (sonButce != null && hedefTutarController.text.trim().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aylık Bütçeniz: ${sonButce!.toStringAsFixed(0)} TL'),
                  const SizedBox(height: 12),
                  const Text('Aylık birikim oranı seçin:'),
                  Wrap(
                    spacing: 12,
                    children:
                        [0.05, 0.10, 0.15, 0.20, 0.40, 0.50].map((oran) {
                          final miktar = (sonButce! * oran).round();
                          return ChoiceChip(
                            label: Text(
                              "%${(oran * 100).toInt()} ($miktar TL)",
                            ),
                            selected: secilenOran == oran,
                            onSelected: (secildi) {
                              if (secildi) {
                                final hedef =
                                    double.tryParse(
                                      hedefTutarController.text.trim(),
                                    ) ??
                                    0;
                                final aySayisi = (hedef / miktar).ceil();
                                final bitis = DateTime.now().add(
                                  Duration(days: aySayisi * 30),
                                );

                                setState(() {
                                  secilenOran = oran;
                                  aylikMiktar = miktar.toDouble();
                                  tahminiAy = aySayisi;
                                  tahminiBitis = bitis;
                                });
                              }
                            },
                          );
                        }).toList(),
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Kendi oranınızı girin (%)',
                      border: OutlineInputBorder(),
                      hintText: 'Örn: 12.5',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (deger) {
                      final oran =
                          double.tryParse(deger.replaceAll(',', '.')) ?? 0;
                      if (oran > 0 && oran <= 100 && sonButce != null) {
                        final yuzde = oran / 100;
                        final hedef =
                            double.tryParse(hedefTutarController.text.trim()) ??
                            0;
                        final miktar = (sonButce! * yuzde).round();
                        final aySayisi = (hedef / miktar).ceil();
                        final bitis = DateTime.now().add(
                          Duration(days: aySayisi * 30),
                        );
                        setState(() {
                          secilenOran = yuzde;
                          aylikMiktar = miktar.toDouble();
                          tahminiAy = aySayisi;
                          tahminiBitis = bitis;
                        });
                      }
                    },
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (tahminiAy != null && tahminiBitis != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Seçilen oran: %${(secilenOran! * 100).toInt()} → ${aylikMiktar!.toStringAsFixed(0)} TL/ay",
                  ),
                  const SizedBox(height: 6),
                  Text("Hedefe ulaşmak için tahmini süre: $tahminiAy ay"),
                  Text(
                    "Tahmini bitiş tarihi: ${tahminiBitis!.day}.${tahminiBitis!.month}.${tahminiBitis!.year}",
                  ),
                ],
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: hedefiKaydetVeyaGuncelle,
              child: Text(hedefId == null ? 'Kaydet' : 'Güncelle'),
            ),
          ],
        ),
      ),
    );
  }
}
