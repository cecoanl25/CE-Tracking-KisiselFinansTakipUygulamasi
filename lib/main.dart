import 'package:finanstakip/giris/giris_ekrani.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finans Takip',
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorObservers: [routeObserver],
      home: const GirisEkraniBaslangic(),
    );
  }
}
