import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:borno_keyboard/ui/borno_app.dart';
import 'package:borno_keyboard/ui/chat_preview.dart';
import 'package:borno_keyboard/ui/keyboard_demo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void useSurface(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('landing page renders brand, hero and live demo', (tester) async {
    useSurface(tester, const Size(1440, 1200));
    await tester.pumpWidget(const BornoApp());
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Borno'), findsWidgets);
    expect(find.text('এখনই টাইপ করুন'), findsOneWidget);
    expect(find.byType(KeyboardDemo), findsOneWidget);
    expect(find.byType(ChatPreview), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phonetic keys compose Bangla in the live composer', (
    tester,
  ) async {
    useSurface(tester, const Size(1600, 2000));
    await tester.pumpWidget(const BornoApp());
    await tester.pump(const Duration(milliseconds: 900));

    for (final key in ['a', 'm', 'i']) {
      await tester.tap(find.text(key).first);
      await tester.pump(const Duration(milliseconds: 80));
    }

    final preview = tester.widget<ChatPreview>(find.byType(ChatPreview));
    expect(preview.text, 'আমি');
    expect(preview.romanBuffer, 'ami');

    await tester.tap(find.text('স্পেস').first);
    await tester.pump(const Duration(milliseconds: 100));

    final spaced = tester.widget<ChatPreview>(find.byType(ChatPreview));
    expect(spaced.text, 'আমি ');
    expect(spaced.romanBuffer, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('backspace swipe selects and deletes composer text', (
    tester,
  ) async {
    useSurface(tester, const Size(1600, 2000));
    await tester.pumpWidget(const BornoApp());
    await tester.pump(const Duration(milliseconds: 900));

    for (final key in ['a', 'm', 'i']) {
      await tester.tap(find.text(key).first);
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.tap(find.text('স্পেস').first);
    await tester.pump(const Duration(milliseconds: 100));

    var preview = tester.widget<ChatPreview>(find.byType(ChatPreview));
    expect(preview.text, 'আমি ');
    expect(preview.selectionLength, 0);

    final backspace = find.byIcon(Icons.backspace_outlined);
    expect(backspace, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(backspace));
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveBy(const Offset(-24, 0));
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveBy(const Offset(-24, 0));
    await tester.pump(const Duration(milliseconds: 20));

    preview = tester.widget<ChatPreview>(find.byType(ChatPreview));
    expect(preview.selectionLength, greaterThan(0));
    expect(preview.text, 'আমি ');

    await gesture.up();
    await tester.pump();

    preview = tester.widget<ChatPreview>(find.byType(ChatPreview));
    expect(preview.selectionLength, 0);
    expect(preview.text, isNot('আমি '));
    expect(preview.text.length, lessThan(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile layout builds without overflow', (tester) async {
    useSurface(tester, const Size(320, 800));
    await tester.pumpWidget(const BornoApp());
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byType(KeyboardDemo), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
