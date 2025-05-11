import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:finanstakip/profil.dart';
import 'package:finanstakip/secenekler.dart';
import 'package:finanstakip/main.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> with RouteAware {
  String ad = '';
  String soyad = '';
  double? butce;
  double? kalan;

  @override
  void initState() {
    super.initState();
    sayfaPerformansiOlc();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {
      kullaniciBilgileriniGetir();
      butceBilgisiGetir();
      birikimHedefleriGetir();
      kategorilereGoreHarcamalar();
      analizVerileriniGetir();
    });
  }

  Future<void> sayfaPerformansiOlc() async {
    final trace = FirebasePerformance.instance.newTrace(
      "verilerin_guncel_kaydi",
    );
    await trace.start();

    await kullaniciBilgileriniGetir();
    await butceBilgisiGetir();
    await birikimHedefleriGetir();
    await kategorilereGoreHarcamalar();
    await analizVerileriniGetir();

    await trace.stop();
  }

  Future<void> kullaniciBilgileriniGetir() async {
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
      });
    }
  }

  Future<void> butceBilgisiGetir() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance
            .collection("kullanicilar")
            .doc(uid)
            .collection("analiz")
            .doc("ozet")
            .get();

    final data = doc.data();
    if (data != null) {
      setState(() {
        butce = data['butce']?.toDouble() ?? 0;
        kalan = data['kalan']?.toDouble() ?? 0;
      });
    }
  }

  Future<List<Map<String, dynamic>>> birikimHedefleriGetir() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(uid)
            .collection('hedefbutce')
            .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<Map<String, dynamic>> analizVerileriniGetir() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final abonelikSnapshot =
        await FirebaseFirestore.instance
            .collection("kullanicilar")
            .doc(uid)
            .collection("abonelik")
            .orderBy("tutar", descending: true)
            .get();

    return {'abonelikler': abonelikSnapshot.docs.map((e) => e.data()).toList()};
  }

  Future<Map<String, double>> kategorilereGoreHarcamalar() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(uid)
            .collection('analiz')
            .get();

    Map<String, double> veri = {};
    for (final doc in snapshot.docs) {
      if (doc.id.startsWith('kategoriharcamalar_')) {
        final data = doc.data();
        final kategori = data['kategori'] ?? 'Diğer';
        final tutar = (data['tutar'] ?? 0).toDouble();
        veri[kategori] = tutar;
      }
    }
    return veri;
  }

  Future<Map<String, double>> kategorilereGoreAbonelikler() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(uid)
            .collection('analiz')
            .get();

    Map<String, double> veri = {};
    for (final doc in snapshot.docs) {
      if (doc.id.startsWith('kategoriabonelik_')) {
        final data = doc.data();
        final kategori = data['kategori'] ?? 'Diğer';
        final tutar = (data['tutar'] ?? 0).toDouble();
        veri[kategori] = tutar;
      }
    }
    return veri;
  }

  @override
  Widget build(BuildContext context) {
    double harcanan = (butce ?? 0) - (kalan ?? 0);
    double oran =
        (butce != null && butce! > 0) ? (harcanan / butce!).clamp(0.0, 1.0) : 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ana Sayfa"),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.account_circle),
          tooltip: 'Profil',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Profil()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Seçenekler',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Secenekler()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: sayfaPerformansiOlc,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Hoş Geldin, $ad $soyad! 👋',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Bütçe Durumum",
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        butce == null
                            ? const Text(
                              "Herhangi bir bilgi girilmedi.",
                              style: TextStyle(color: Colors.grey),
                            )
                            : _satir("Toplam Bütçe", butce),
                        _satir("Harcanan", harcanan),
                        _satir("Kalan", kalan),

                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: oran,
                            backgroundColor: Colors.grey.shade300,
                            color: Colors.orangeAccent,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Kullanım: ${(oran * 100).toStringAsFixed(1)}%",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                  ),
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: birikimHedefleriGetir(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Hata: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text(
                        'Herhangi bir birikim hedefi bulunamadı.',
                      );
                    }

                    return ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children:
                          snapshot.data!.map((hedef) {
                            final String ad = hedef['hedefAdi'] ?? 'Hedef';
                            final double mevcut =
                                (hedef['mevcutDurum'] ?? 0).toDouble();
                            final double hedefTutar =
                                (hedef['hedefTutar'] ?? 1).toDouble();
                            final double oran = (mevcut / hedefTutar).clamp(
                              0.0,
                              1.0,
                            );
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              color: Colors.orange.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.flag_circle,
                                            color: Colors.orange.shade700,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Birikim Hedefim - $ad",
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    Text(
                                      "Hedef Tutar: ${hedefTutar.toStringAsFixed(2)} TL",
                                    ),
                                    Text(
                                      "Mevcut Birikim: ${mevcut.toStringAsFixed(2)} TL",
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: oran,
                                        backgroundColor: Colors.grey.shade300,
                                        color: Colors.green,
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Tamamlanma: ${(oran * 100).toStringAsFixed(1)}%",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: Colors.blueGrey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
                FutureBuilder<Map<String, dynamic>>(
                  future: analizVerileriniGetir(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final abonelikler = snapshot.data?["abonelikler"] ?? [];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                      color: Colors.indigo.shade50,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.subscriptions_outlined,
                                    color: Colors.indigo.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Mevcut Aboneliklerim",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Servis Adı -> Maliyet - Ödeme Tarihi",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...abonelikler.map<Widget>((abone) {
                              final tarih =
                                  (abone["odemeTarihi"] as Timestamp?)
                                      ?.toDate();
                              final servis = abone["servisAdi"] ?? "-";
                              final tutar = (abone["tutar"] ?? 0).toDouble();
                              final tarihStr =
                                  tarih != null
                                      ? "${tarih.day}.${tarih.month}.${tarih.year}"
                                      : "-";
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(servis),
                                    Text(
                                      "$tutar TL – $tarihStr",
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                FutureBuilder<Map<String, double>>(
                  future: kategorilereGoreHarcamalar(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Hata: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Herhangi bir harcama girilmedi.');
                    } else {
                      final veri = snapshot.data!;
                      final toplam = veri.values.fold(0.0, (a, b) => a + b);

                      final List<PieChartSectionData> bolumler =
                          veri.entries.map((entry) {
                            final oran = (entry.value / toplam);
                            return PieChartSectionData(
                              color: _kategoriRenkHarcama(entry.key),
                              value: entry.value,
                              radius: 60,
                              showTitle: true,
                              title: '${(oran * 100).toStringAsFixed(1)}%',
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              titlePositionPercentageOffset: 0.6,
                            );
                          }).toList();

                      final List<Widget> aciklamalar =
                          veri.entries.map((entry) {
                            final oran = (entry.value / toplam) * 100;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: _kategoriRenkHarcama(entry.key),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${entry.key}: ${entry.value.toStringAsFixed(0)} TL (${oran.toStringAsFixed(1)}%)',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey.shade800),
                                  ),
                                ],
                              ),
                            );
                          }).toList();

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                        color: Colors.deepPurple.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.pie_chart,
                                      color: Colors.deepPurple,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Harcamalarım",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AspectRatio(
                                aspectRatio: 1.3,
                                child: PieChart(
                                  PieChartData(
                                    sections: bolumler,
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 40,
                                  ),
                                ),
                              ),
                              ...aciklamalar,
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
                FutureBuilder<Map<String, double>>(
                  future: kategorilereGoreAbonelikler(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Hata: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Herhangi bir abonelik girilmedi.');
                    } else {
                      final veri = snapshot.data!;
                      final toplam = veri.values.fold(0.0, (a, b) => a + b);

                      final List<PieChartSectionData> bolumler =
                          veri.entries.map((entry) {
                            final oran = (entry.value / toplam);
                            return PieChartSectionData(
                              color: _kategoriRenkAbonelik(entry.key),
                              value: entry.value,
                              radius: 60,
                              showTitle: true,
                              title: '${(oran * 100).toStringAsFixed(1)}%',
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              titlePositionPercentageOffset: 0.6,
                            );
                          }).toList();

                      final List<Widget> aciklamalar =
                          veri.entries.map((entry) {
                            final oran = (entry.value / toplam) * 100;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: _kategoriRenkAbonelik(entry.key),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${entry.key}: ${entry.value.toStringAsFixed(0)} TL (${oran.toStringAsFixed(1)}%)',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey.shade800),
                                  ),
                                ],
                              ),
                            );
                          }).toList();

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                        color: Colors.blueGrey.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.repeat,
                                      color: Colors.blueGrey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Aboneliklerim",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AspectRatio(
                                aspectRatio: 1.3,
                                child: PieChart(
                                  PieChartData(
                                    sections: bolumler,
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 40,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ...aciklamalar,
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _satir(String baslik, double? deger) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(baslik, style: TextStyle(color: Colors.grey.shade800)),
      Text(
        '${deger?.toStringAsFixed(2) ?? "-"} TL',
        style: TextStyle(color: Colors.grey.shade800),
      ),
    ],
  );
}

Color _kategoriRenkHarcama(String kategori) {
  switch (kategori.toLowerCase()) {
    case 'yiyecek':
      return Colors.orangeAccent;
    case 'ulaşım':
      return Colors.blueAccent;
    case 'eğlence':
      return Colors.purpleAccent;
    case 'zorunlu giderler':
      return Colors.redAccent;
    case 'diğer':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

Color _kategoriRenkAbonelik(String kategori) {
  switch (kategori.toLowerCase()) {
    case 'internet':
      return Colors.orangeAccent;
    case 'üyelikler':
      return Colors.blueAccent;
    case 'eğlence':
      return Colors.purpleAccent;
    case 'dijital medya':
      return Colors.redAccent;
    case 'diğer':
      return Colors.green;
    default:
      return Colors.grey;
  }
}
