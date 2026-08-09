import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:but_wallet/main.dart';

void main() {
  testWidgets('BUT Wallet app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const ButApp());
    expect(find.byType(ButApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
