import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finanstakip/giris/giris_ekrani.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../anasayfa.dart';

class KayitEkraniBaslangic extends StatelessWidget {
  const KayitEkraniBaslangic({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Olun'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: const KayitEkrani(),
    );
  }
}

class KayitEkrani extends StatefulWidget {
  const KayitEkrani({super.key});

  @override
  State<KayitEkrani> createState() => _KayitEkraniState();
}

class _KayitEkraniState extends State<KayitEkrani> {
  final TextEditingController epostaController = TextEditingController();
  final TextEditingController sifreController = TextEditingController();
  final TextEditingController tekrarSifreController = TextEditingController();

  final TextEditingController adController = TextEditingController();
  final TextEditingController soyadController = TextEditingController();
  final TextEditingController dogumTarihiController = TextEditingController();

  void kayitOl() async {
    String email = epostaController.text.trim();
    String sifre = sifreController.text.trim();
    String ad = adController.text.trim();
    String soyad = soyadController.text.trim();
    String dogumTarihi = dogumTarihiController.text.trim();

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: sifre);
      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('kullanicilar').doc(uid).set({
        'ad': ad,
        'soyad': soyad,
        'dogumTarihi': dogumTarihi,
        'email': email,
      });

      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(const SnackBar(content: Text('Kayıt başarılı!')));

      Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const AnaSayfa()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firebase Auth Hatası: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Bir hata oluştu: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.person_add_alt, size: 100, color: Colors.amber),
              const SizedBox(height: 16),
              const Text(
                "Lütfen Bilgilerinizi Giriniz",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: adController,
                      decoration: const InputDecoration(
                        labelText: 'Ad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: soyadController,
                      decoration: const InputDecoration(
                        labelText: 'Soyad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dogumTarihiController,
                readOnly: true,
                onTap: () async {
                  DateTime? secilenTarih = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000, 1, 1),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );

                  if (secilenTarih != null) {
                    String formatted =
                        "${secilenTarih.day.toString().padLeft(2, '0')}/"
                        "${secilenTarih.month.toString().padLeft(2, '0')}/"
                        "${secilenTarih.year}";
                    setState(() {
                      dogumTarihiController.text = formatted;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Doğum Tarihi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: epostaController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: sifreController,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: tekrarSifreController,
                decoration: const InputDecoration(
                  labelText: 'Şifre (Tekrar)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (epostaController.text == "" ||
                      sifreController.text == "" ||
                      tekrarSifreController.text == "" ||
                      adController.text == "" ||
                      soyadController.text == "" ||
                      dogumTarihiController.text == "") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lütfen tüm bilgileri doldurunuz!'),
                      ),
                    );
                  } else if (sifreController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Şifreniz en az 6 karakter uzunlukta olmalıdır.',
                        ),
                      ),
                    );
                  } else if (sifreController.text !=
                      tekrarSifreController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Şifreler uyuşmuyor!')),
                    );
                  } else {
                    kayitOl();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Kayıt Ol'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Zaten bir hesabınız mı var?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GirisEkraniBaslangic(),
                        ),
                      );
                    },
                    child: const Text("Hemen giriş yapın!"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
