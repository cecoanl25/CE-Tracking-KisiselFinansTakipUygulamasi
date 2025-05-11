import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';

class HarcamaEkleBaslangic extends StatelessWidget {
  const HarcamaEkleBaslangic({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gider Bilgisi'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: const HarcamaEkle(),
    );
  }
}

class HarcamaEkle extends StatefulWidget {
  const HarcamaEkle({super.key});

  @override
  State<HarcamaEkle> createState() => _HarcamaEkleState();
}

class _HarcamaEkleState extends State<HarcamaEkle> {
  final TextEditingController tutarController = TextEditingController();
  final TextEditingController aciklamaController = TextEditingController();
  DateTime secilenTarih = DateTime.now();
  String secilenKategori = 'Yiyecek';
  String? guncellenecekId;

  final List<String> kategoriler = [
    'Yiyecek',
    'Ulaşım',
    'Eğlence',
    'Zorunlu Giderler',
    'Diğer',
  ];

  Future<void> harcamaKaydetVeyaGuncelle() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String kategori = secilenKategori;
    String tutar = tutarController.text.trim();
    String aciklama = aciklamaController.text.trim();

    if (tutar.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen tutar girin')));
      return;
    }

    final data = {
      'kategori': kategori,
      'tutar': double.tryParse(tutar) ?? 0,
      'aciklama': aciklama,
      'tarih': Timestamp.fromDate(secilenTarih),
    };

    try {
      final perform = FirebasePerformance.instance.newTrace("harcama_kayit");
      await perform.start();
      final ref = FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(uid)
          .collection('harcamalar');

      if (guncellenecekId != null) {
        await ref.doc(guncellenecekId).update(data);
      } else {
        await ref.add(data);
      }
      await perform.stop();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            guncellenecekId != null
                ? 'Harcama güncellendi'
                : 'Harcama kaydedildi',
          ),
        ),
      );

      setState(() {
        tutarController.clear();
        aciklamaController.clear();
        secilenTarih = DateTime.now();
        secilenKategori = 'Yiyecek';
        guncellenecekId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> harcamaSil(String docId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(uid)
        .collection('harcamalar')
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(
      // ignore: use_build_context_synchronously
      context,
    ).showSnackBar(const SnackBar(content: Text('Harcama silindi')));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mevcut Harcamalar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('kullanicilar')
                      .doc(uid)
                      .collection('harcamalar')
                      .orderBy('tarih', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Text('Henüz kayıtlı harcama yok.');
                }
                return Column(
                  children:
                      docs.map((doc) {
                        final veri = doc.data() as Map<String, dynamic>;
                        final kategori = veri['kategori'] ?? '-';
                        final tutar = (veri['tutar'] ?? 0).toDouble();
                        final tarih = (veri['tarih'] as Timestamp?)?.toDate();
                        final aciklama = veri['aciklama'] ?? '';
                        final tarihStr =
                            tarih != null
                                ? "${tarih.day}.${tarih.month}.${tarih.year}"
                                : '-';

                        return ListTile(
                          title: Text(
                            '$kategori – ${tutar.toStringAsFixed(2)} TL',
                          ),
                          subtitle: Text('$aciklama\nTarih: $tarihStr'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                ),
                                onPressed: () {
                                  setState(() {
                                    tutarController.text = tutar.toString();
                                    aciklamaController.text = aciklama;
                                    secilenTarih = tarih ?? DateTime.now();
                                    secilenKategori = kategori;
                                    guncellenecekId = doc.id;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => harcamaSil(doc.id),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                );
              },
            ),
            const Divider(height: 32),
            const Text(
              'Kategori',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: secilenKategori,
              items:
                  kategoriler
                      .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                      .toList(),
              onChanged: (deger) {
                setState(() {
                  secilenKategori = deger!;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Tutar', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: tutarController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Örn: 150',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Açıklama',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: aciklamaController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'İsteğe bağlı not...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'Tarih: ${secilenTarih.day}/${secilenTarih.month}/${secilenTarih.year}',
            ),
            ElevatedButton(
              onPressed: () async {
                DateTime? yeniTarih = await showDatePicker(
                  context: context,
                  initialDate: secilenTarih,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (yeniTarih != null) {
                  setState(() {
                    secilenTarih = yeniTarih;
                  });
                }
              },
              child: const Text('Tarih Seç'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: harcamaKaydetVeyaGuncelle,
              child: Text(guncellenecekId == null ? 'Kaydet' : 'Güncelle'),
            ),
          ],
        ),
      ),
    );
  }
}
