import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Firebase 초기화 (Firebase 설정 후)
  // await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      child: ChimshinBibleApp(),
    ),
  );
}
