import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';

class AbonelikEkleBaslangic extends StatelessWidget {
  const AbonelikEkleBaslangic({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonelikler'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: const AbonelikEkle(),
    );
  }
}

class AbonelikEkle extends StatefulWidget {
  const AbonelikEkle({super.key});

  @override
  State<AbonelikEkle> createState() => _AbonelikEkleState();
}

class _AbonelikEkleState extends State<AbonelikEkle> {
  final TextEditingController servisAdiController = TextEditingController();
  final TextEditingController tutarController = TextEditingController();
  DateTime? odemeTarihi;
  String secilenKategori = 'Dijital Medya';
  String? guncellenecekId;

  final List<String> kategoriler = [
    'Dijital Medya',
    'İnternet',
    'Üyelikler',
    'Diğer',
  ];

  Future<void> abonelikEkleVeyaGuncelle() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String servisadi = servisAdiController.text.trim();
    String tutar = tutarController.text.trim();
    String secilenkategori = secilenKategori;

    if (servisadi.isEmpty || tutar.isEmpty || odemeTarihi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun!')),
      );
      return;
    }

    final data = {
      'servisAdi': servisadi,
      'tutar': double.tryParse(tutar) ?? 0,
      'kategori': secilenkategori,
      'odemeTarihi': Timestamp.fromDate(odemeTarihi!),
    };

    try {
      final perform = FirebasePerformance.instance.newTrace("abonelik_kayit");
      await perform.start();
      final ref = FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(uid)
          .collection('abonelik');

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
                ? 'Abonelik güncellendi'
                : 'Abonelik eklendi',
          ),
        ),
      );

      setState(() {
        servisAdiController.clear();
        tutarController.clear();
        odemeTarihi = null;
        secilenKategori = 'Dijital Medya';
        guncellenecekId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Hata oluştu: $e')));
    }
  }

  Future<void> abonelikSil(String docId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(uid)
        .collection('abonelik')
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(
      // ignore: use_build_context_synchronously
      context,
    ).showSnackBar(const SnackBar(content: Text('Abonelik silindi')));
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
              'Mevcut Abonelikler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('kullanicilar')
                      .doc(uid)
                      .collection('abonelik')
                      .orderBy('tutar', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Text('Henüz abonelik yok.');
                }
                return Column(
                  children:
                      docs.map((doc) {
                        final veri = doc.data() as Map<String, dynamic>;
                        final servis = veri['servisAdi'] ?? '-';
                        final tutar = (veri['tutar'] ?? 0).toDouble();
                        final tarih =
                            (veri['odemeTarihi'] as Timestamp?)?.toDate();
                        final tarihStr =
                            tarih != null
                                ? "${tarih.day}.${tarih.month}.${tarih.year}"
                                : '-';
                        return ListTile(
                          title: Text(
                            '$servis – ${tutar.toStringAsFixed(2)} TL',
                          ),
                          subtitle: Text('Son ödeme: $tarihStr'),
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
                                    servisAdiController.text = servis;
                                    tutarController.text = tutar.toString();
                                    odemeTarihi = tarih;
                                    secilenKategori =
                                        veri['kategori'] ?? 'Dijital Medya';
                                    guncellenecekId = doc.id;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => abonelikSil(doc.id),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                );
              },
            ),
            const Divider(height: 32),
            const Text('Servis Adı'),
            const SizedBox(height: 8),
            TextField(
              controller: servisAdiController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Örn: Netflix, Spotify...',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Tutar'),
            const SizedBox(height: 8),
            TextField(
              controller: tutarController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Örn: 79.99',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Kategori'),
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
            const Text('Ödeme Tarihi'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final secilen = await showDatePicker(
                  context: context,
                  initialDate: odemeTarihi ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (secilen != null) {
                  setState(() {
                    odemeTarihi = secilen;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 12.0,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  odemeTarihi == null
                      ? 'Tarih Seç'
                      : '${odemeTarihi!.day}.${odemeTarihi!.month}.${odemeTarihi!.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: abonelikEkleVeyaGuncelle,
              child: Text(guncellenecekId == null ? 'Kaydet' : 'Güncelle'),
            ),
          ],
        ),
      ),
    );
  }
}
