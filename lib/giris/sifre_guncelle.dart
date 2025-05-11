import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../giris/giris_ekrani.dart';

class SifreGuncelleBaslangic extends StatelessWidget {
  const SifreGuncelleBaslangic({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifreni Değiştir'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: const SifreGuncelle(),
    );
  }
}

class SifreGuncelle extends StatefulWidget {
  const SifreGuncelle({super.key});

  @override
  State<SifreGuncelle> createState() => _SifreGuncelleState();
}

class _SifreGuncelleState extends State<SifreGuncelle> {
  final TextEditingController eskiSifreController = TextEditingController();
  final TextEditingController yeniSifreController = TextEditingController();

  void sifreGuncelle() async {
    String eskiSifre = eskiSifreController.text.trim();
    String yeniSifre = yeniSifreController.text.trim();

    User? user = FirebaseAuth.instance.currentUser;
    String? email = user?.email;

    if (user == null || email == null || eskiSifre.isEmpty || yeniSifre.isEmpty)
      // ignore: curly_braces_in_flow_control_structures
      return;

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: eskiSifre,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(yeniSifre);

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const GirisEkraniBaslangic()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Şifreniz başarıyla güncellendi. Lütfen tekrar giriş yapınız.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print(e);
      String mesaj = 'Bilgiler hatalı!';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mesaj)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.lock_outline, size: 100, color: Colors.amber),
              const SizedBox(height: 16),
              const Text(
                "Şifrenizi Değiştirin",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: eskiSifreController,
                decoration: const InputDecoration(
                  labelText: 'Mevcut Şifreniz',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: yeniSifreController,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifreniz',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (eskiSifreController.text.isEmpty ||
                      yeniSifreController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lütfen tüm alanları doldurunuz!'),
                      ),
                    );
                  } else if (yeniSifreController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Şifre en az 6 karakter uzunluğunda olmalıdır!',
                        ),
                      ),
                    );
                  } else if (yeniSifreController.text ==
                      eskiSifreController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Yeni şifreniz eski şifrenizle aynı olmamalı!',
                        ),
                      ),
                    );
                  } else {
                    sifreGuncelle();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Şifreyi Güncelle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
