import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chimshin_bible_note/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ChimshinBibleApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
