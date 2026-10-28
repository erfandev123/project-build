import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:borno_keyboard/theme/borno_theme.dart';
import 'package:borno_keyboard/ui/keyboard.dart';
import 'package:borno_keyboard/ui/keyboard_data.dart';

const _popupKey = ValueKey('bengali-choice-popup');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void useSurface(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<List<String>> pumpKeyboard(
    WidgetTester tester, {
    bool shift = false,
    Size size = const Size(360, 800),
    List<String>? swipeEvents,
  }) async {
    useSurface(tester, size);
    final inserted = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: _KeyboardHarness(
              inserted: inserted,
              initialShift: shift,
              swipeEvents: swipeEvents,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return inserted;
  }

  Future<void> pressAndSlide(
    WidgetTester tester,
    String keyLabel, {
    double dx = 0,
    double dy = 0,
  }) async {
    final finder = find.text(keyLabel).last;
    expect(find.text(keyLabel), findsWidgets);
    final gesture = await tester.startGesture(tester.getCenter(finder));
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.byKey(_popupKey), findsOneWidget);
    if (dx != 0 || dy != 0) {
      await gesture.moveBy(Offset(dx, dy));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  group('Bengali key map', () {
    test('has the exact 12 / 9 / 9 key groups in order', () {
      expect(KeyboardData.bengaliRows.map((row) => row.length), [12, 9, 9]);

      expect(
        KeyboardData.bengaliRows[0].map((key) => key.characters).toList(),
        [
          ['দ', 'ধ'],
          ['ূ', 'ঊ'],
          ['ী', 'ঈ'],
          ['র', 'ড়', '্র', 'র্', 'র‍্য'],
          ['ট', 'ঠ'],
          ['এ', 'ঐ', 'ঞ'],
          ['ু', 'উ', 'ৎ'],
          ['ি', 'ই'],
          ['ও', 'ঔ'],
          ['প', 'ফ'],
          ['ে', 'ৈ'],
          ['ো', 'ৌ'],
        ],
      );
      expect(
        KeyboardData.bengaliRows[1].map((key) => key.characters).toList(),
        [
          ['া', 'অ'],
          ['স', 'ষ'],
          ['ড', 'ঢ'],
          ['ত', 'থ'],
          ['গ', 'ঘ'],
          ['হ', 'ঃ'],
          ['জ', 'ঝ'],
          ['ক', 'খ'],
          ['ল', 'ং'],
        ],
      );
      expect(
        KeyboardData.bengaliRows[2].map((key) => key.characters).toList(),
        [
          ['য়', '্য', 'র‍্য', 'য'],
          ['শ', 'ঢ়'],
          ['চ', 'ছ'],
          ['আ', 'ঋ'],
          ['ব', 'ভ'],
          ['ন', 'ণ'],
          ['ম', 'ঙ'],
          ['ৃ'],
          ['্', '়', 'ঁ'],
        ],
      );
    });

    test('uses canonical Unicode sequences for conjuncts and marks', () {
      final row1 = KeyboardData.bengaliRows[0];
      final row3 = KeyboardData.bengaliRows[2];

      expect(row1[3].characters[2].codeUnits, [0x09CD, 0x09B0]); // ্র
      expect(row1[3].characters[3].codeUnits, [0x09B0, 0x09CD]); // র্
      expect(
        row1[3].characters[4].codeUnits,
        [0x09B0, 0x200D, 0x09CD, 0x09AF], // র‍্য
      );
      expect(row3[0].characters[1].codeUnits, [0x09CD, 0x09AF]); // ্য
      expect(row3[0].characters[2].codeUnits, [0x09B0, 0x200D, 0x09CD, 0x09AF]);
      expect(row3[8].characters[0].codeUnits, [0x09CD]); // ্
      expect(row3[8].characters[1].codeUnits, [0x09BC]); // ়
      expect(row3[8].characters[2].codeUnits, [0x0981]); // ঁ
    });

    test('defines the Probhat Shift layer without moving any key', () {
      final shifted = KeyboardData.bengaliRows
          .map(
            (row) =>
                row.map((key) => key.primaryFor(true)).toList(growable: false),
          )
          .toList(growable: false);

      expect(shifted[0], [
        'ধ',
        'ঊ',
        'ঈ',
        'ড়',
        'ঠ',
        'ঐ',
        'উ',
        'ই',
        'ঔ',
        'ফ',
        'ৈ',
        'ৌ',
      ]);
      expect(shifted[1], ['অ', 'ষ', 'ঢ', 'থ', 'ঘ', 'ঃ', 'ঝ', 'খ', 'ং']);
      expect(shifted[2], ['য', 'ঢ়', 'ছ', 'ঋ', 'ভ', 'ণ', 'ঙ', 'ৃ', 'ঁ']);
    });
  });

  group('Bengali keyboard interaction', () {
    testWidgets('a tap inserts the primary character', (tester) async {
      final inserted = await pumpKeyboard(tester);

      await tester.tap(find.text('দ'));
      await tester.pumpAndSettle();

      expect(inserted, ['দ']);
      expect(find.byKey(_popupKey), findsNothing);
    });

    testWidgets('repeated taps insert repeated characters', (tester) async {
      final inserted = await pumpKeyboard(tester);
      final key = find.text('দ').last;

      await tester.tap(key);
      await tester.pumpAndSettle();
      await tester.tap(key);
      await tester.pumpAndSettle();

      expect(inserted, ['দ', 'দ']);
    });

    testWidgets('voice status stays inline in the keyboard', (tester) async {
      await pumpKeyboard(tester);

      await tester.tap(find.bySemanticsLabel('বাংলা ভয়েস ইনপুট'));
      await tester.pumpAndSettle();

      expect(find.text('শুনছি…'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('sliding right selects the next characters in order', (
      tester,
    ) async {
      final inserted = await pumpKeyboard(tester);

      await pressAndSlide(tester, 'র', dx: 95);

      expect(inserted, ['্র']);
    });

    testWidgets('sliding left from a Shift primary selects the previous char', (
      tester,
    ) async {
      final inserted = await pumpKeyboard(tester, shift: true);

      // Shift row 3 starts with য, which is index 3 of the ordered group.
      await pressAndSlide(tester, 'য', dx: -46);

      expect(inserted, ['র‍্য']);
    });

    testWidgets('the popup shows every choice for the pressed key', (
      tester,
    ) async {
      await pumpKeyboard(tester);

      final finder = find.text('র');
      final gesture = await tester.startGesture(tester.getCenter(finder));
      await tester.pump(const Duration(milliseconds: 320));

      expect(find.byKey(_popupKey), findsOneWidget);
      for (final choice in ['র', 'ড়', '্র', 'র্', 'র‍্য']) {
        expect(find.text(choice), findsWidgets);
      }
      expect(find.byKey(const ValueKey('choice-item-4')), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('inserts the র‍্য conjunct sequence as one character', (
      tester,
    ) async {
      final inserted = await pumpKeyboard(tester);

      await pressAndSlide(tester, 'য়', dx: 92);

      expect(inserted, ['\u09B0\u200D\u09CD\u09AF']);
      expect(inserted.single.codeUnits, [0x09B0, 0x200D, 0x09CD, 0x09AF]);
    });

    testWidgets('Shift exposes ঐ and ঞ on the same key position', (
      tester,
    ) async {
      final inserted = await pumpKeyboard(tester, shift: true);

      expect(find.text('ঐ'), findsNWidgets(2));
      expect(find.text('ঞ'), findsNothing);

      await pressAndSlide(tester, 'ঐ', dx: 46);

      expect(inserted, ['ঞ']);
    });

    testWidgets('Shift exposes য and keeps the same selection group', (
      tester,
    ) async {
      final inserted = await pumpKeyboard(tester, shift: true);

      await pressAndSlide(tester, 'য');

      expect(inserted, ['য']);
    });

    testWidgets('tapping the Shift key swaps the visible layout', (
      tester,
    ) async {
      await pumpKeyboard(tester);

      expect(find.text('দ'), findsOneWidget);
      expect(find.text('ধ'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('শিফট চালু করুন'));
      await tester.pumpAndSettle();

      expect(find.text('দ'), findsNothing);
      expect(find.text('ধ'), findsNWidgets(2));
      expect(find.text('এ'), findsNothing);
      expect(find.text('ঐ'), findsNWidgets(2));
    });

    testWidgets('keeps an edge popup inside the screen and above the key', (
      tester,
    ) async {
      await pumpKeyboard(tester, size: const Size(320, 800));

      final keyFinder = find.text('ো');
      final keyRect = tester.getRect(keyFinder);
      final gesture = await tester.startGesture(tester.getCenter(keyFinder));
      await tester.pump(const Duration(milliseconds: 320));

      final popupRect = tester.getRect(find.byKey(_popupKey));
      expect(popupRect.left, greaterThanOrEqualTo(0));
      expect(popupRect.right, lessThanOrEqualTo(320));
      expect(popupRect.top, greaterThanOrEqualTo(0));
      expect(popupRect.bottom, lessThanOrEqualTo(800));
      expect(popupRect.bottom, lessThan(keyRect.top));
      expect(tester.takeException(), isNull);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('cancelling a gesture does not insert anything', (
      tester,
    ) async {
      final inserted = await pumpKeyboard(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('র')),
      );
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveBy(const Offset(95, -400));
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byKey(_popupKey), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(inserted, isEmpty);
    });

    testWidgets('one gesture inserts exactly one character', (tester) async {
      final inserted = await pumpKeyboard(tester);

      await pressAndSlide(tester, 'র', dx: 95);

      expect(inserted.length, 1);
      expect(inserted.single, '্র');
    });

    testWidgets('backspace swipe reports leftward drag and end', (
      tester,
    ) async {
      final events = <String>[];
      await pumpKeyboard(tester, swipeEvents: events);

      final backspace = find.byIcon(Icons.backspace_outlined);
      expect(backspace, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(backspace));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(events.first, 'start');
      expect(events.last, 'end');
      final updates = events
          .where((event) => event.startsWith('update:'))
          .map((event) => double.parse(event.substring(7)))
          .toList();
      expect(updates, isNotEmpty);
      expect(updates.last, lessThan(0));
    });
  });
}

class _KeyboardHarness extends StatefulWidget {
  const _KeyboardHarness({
    required this.inserted,
    this.initialShift = false,
    this.swipeEvents,
  });

  final List<String> inserted;
  final bool initialShift;
  final List<String>? swipeEvents;

  @override
  State<_KeyboardHarness> createState() => _KeyboardHarnessState();
}

class _KeyboardHarnessState extends State<_KeyboardHarness> {
  late bool _shift = widget.initialShift;
  String _voiceStatus = '';

  @override
  Widget build(BuildContext context) {
    return BornoKeyboard(
      skin: midnightSkin,
      mode: InputMode.bengali,
      page: KeyboardPage.letters,
      shift: _shift,
      suggestions: const [],
      soundOn: false,
      hapticsOn: false,
      previewOn: true,
      canSend: false,
      onCharacter: widget.inserted.add,
      onBackspace: () {},
      onBackspaceSwipeStart: widget.swipeEvents == null
          ? null
          : () => widget.swipeEvents!.add('start'),
      onBackspaceSwipeUpdate: widget.swipeEvents == null
          ? null
          : (dx) => widget.swipeEvents!.add('update:$dx'),
      onBackspaceSwipeEnd: widget.swipeEvents == null
          ? null
          : () => widget.swipeEvents!.add('end'),
      onShift: () => setState(() => _shift = !_shift),
      onSpace: () {},
      onSend: () {},
      onPageChanged: (_) {},
      onCycleMode: () {},
      onSuggestion: (_) {},
      onVoice: () => setState(() => _voiceStatus = 'শুনছি…'),
      onOpenLayouts: () {},
      onOpenThemes: () {},
      onOpenSettings: () {},
      onToggleSound: () {},
      voiceStatus: _voiceStatus,
      onCloseVoice: () => setState(() => _voiceStatus = ''),
    );
  }
}
