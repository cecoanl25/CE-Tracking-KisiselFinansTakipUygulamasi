import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finanstakip/giris/sifre_guncelle.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'giris/giris_ekrani.dart';

class Profil extends StatefulWidget {
  const Profil({super.key});

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  String ad = '';
  String soyad = '';
  String dogumTarihi = '';
  String email = '';
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    verileriCek();
  }

  Future<void> verileriCek() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc =
          await FirebaseFirestore.instance
              .collection('kullanicilar')
              .doc(uid)
              .get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          ad = data['ad'] ?? '';
          soyad = data['soyad'] ?? '';
          dogumTarihi = data['dogumTarihi'] ?? '';
          email = data['email'] ?? '';
          yukleniyor = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Veri çekme hatası: $e');
    }
  }

  Future<void> altVerileriSil() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final kullaniciRef = FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(uid);
    final List<String> altKoleksiyonlar = [
      'butce',
      'harcamalar',
      'hedefbutce',
      'abonelik',
      'analiz',
    ];

    for (final koleksiyon in altKoleksiyonlar) {
      final snapshot = await kullaniciRef.collection(koleksiyon).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  void kullaniciCikisYap() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const GirisEkraniBaslangic()),
        (route) => false,
      );
    }
  }

  void kullaniciHesapSil() async {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;
    final kullaniciRef = FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(uid);

    await altVerileriSil();
    await kullaniciRef.delete();
    await user.delete();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const GirisEkraniBaslangic()),
        (route) => false,
      );
    }
  }

  void kullaniciVeriSifirla() async {
    await altVerileriSil();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const GirisEkraniBaslangic()),
        (route) => false,
      );
    }
  }

  void onayDialog({
    required String baslik,
    required String icerik,
    required VoidCallback onayFonksiyonu,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(baslik),
            content: Text(icerik),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onayFonksiyonu();
                },
                child: const Text('Evet', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body:
          yukleniyor
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      child: Icon(Icons.account_circle, size: 64),
                    ),
                    Text(
                      "$ad $soyad",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ad Soyad',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('$ad $soyad'),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'E-posta',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(email),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            const Text(
                              'Doğum Tarihi',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(dogumTarihi),
                          ],
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const SifreGuncelleBaslangic(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.lock),
                      label: const Text("Şifreni Değiştir"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade100,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const Spacer(),

                    TextButton(
                      onPressed: () {
                        onayDialog(
                          baslik: 'Çıkış Yap',
                          icerik:
                              'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
                          onayFonksiyonu: kullaniciCikisYap,
                        );
                      },
                      child: const Text(
                        'Çıkış Yap',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        onayDialog(
                          baslik: 'Verilerimi Sıfırla',
                          icerik:
                              'Tüm verilerinizi silmek istediğinize emin misiniz?\nBu işlem geri alınamaz.',
                          onayFonksiyonu: kullaniciVeriSifirla,
                        );
                      },
                      child: const Text(
                        'Verilerimi Sıfırla',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        onayDialog(
                          baslik: 'Hesabımı Sil',
                          icerik:
                              'Hesabınızı ve tüm verilerinizi silmek istediğinize emin misiniz?\nBu işlem geri alınamaz.',
                          onayFonksiyonu: kullaniciHesapSil,
                        );
                      },
                      child: const Text(
                        'Hesabımı Sil',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
