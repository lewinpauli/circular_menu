import 'package:circular_menu/circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpItem(WidgetTester tester, CircularMenuItem item) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: item))));
}

/// The status indicator is the only circle with a border.
Finder _statusIndicator() {
  return find.byWidgetPredicate((widget) {
    if (widget is! Container || widget.decoration is! BoxDecoration) return false;
    final decoration = widget.decoration as BoxDecoration;
    return decoration.shape == BoxShape.circle && decoration.border != null;
  });
}

Color? _statusIndicatorColor(WidgetTester tester) {
  final container = tester.widget<Container>(_statusIndicator());
  return (container.decoration as BoxDecoration).color;
}

void main() {
  group('CircularMenuItem', () {
    testWidgets('renders its icon and calls onTap', (tester) async {
      var taps = 0;
      await _pumpItem(tester, CircularMenuItem(icon: Icons.power, onTap: () => taps++));

      expect(find.byIcon(Icons.power), findsOneWidget);
      await tester.tap(find.byIcon(Icons.power));
      expect(taps, 1);
    });

    testWidgets('animatedIcon wins over icon', (tester) async {
      await _pumpItem(
        tester,
        CircularMenuItem(
          icon: Icons.power,
          animatedIcon: const AnimatedIcon(icon: AnimatedIcons.menu_close, progress: AlwaysStoppedAnimation(0)),
          onTap: () {},
        ),
      );

      expect(find.byType(AnimatedIcon), findsOneWidget);
      expect(find.byIcon(Icons.power), findsNothing);
    });

    test('asserts on negative padding or margin', () {
      expect(() => CircularMenuItem(onTap: () {}, padding: -1), throwsAssertionError);
      expect(() => CircularMenuItem(onTap: () {}, margin: -1), throwsAssertionError);
    });
  });

  group('CircularMenuItem badge', () {
    testWidgets('shows the label only when enableBadge is true', (tester) async {
      await _pumpItem(tester, CircularMenuItem(icon: Icons.power, onTap: () {}, badgeLabel: 'CP1'));
      expect(find.text('CP1'), findsNothing);

      await _pumpItem(
        tester,
        CircularMenuItem(icon: Icons.power, onTap: () {}, enableBadge: true, badgeLabel: 'CP1'),
      );
      expect(find.text('CP1'), findsOneWidget);
    });

    testWidgets('tapping the badge falls back to onTap without onBadgeTap', (tester) async {
      var taps = 0;
      await _pumpItem(
        tester,
        CircularMenuItem(icon: Icons.power, onTap: () => taps++, enableBadge: true, badgeLabel: 'CP1'),
      );

      await tester.tap(find.text('CP1'));
      expect(taps, 1);
    });

    testWidgets('tapping the badge calls only onBadgeTap when set', (tester) async {
      var taps = 0;
      var badgeTaps = 0;
      await _pumpItem(
        tester,
        CircularMenuItem(
          icon: Icons.power,
          onTap: () => taps++,
          onBadgeTap: () => badgeTaps++,
          enableBadge: true,
          // Without offsets the badge sits on top of the icon's center.
          badgeTopOffset: 60,
          badgeLabel: 'CP1',
        ),
      );

      await tester.tap(find.text('CP1'));
      expect(badgeTaps, 1);
      expect(taps, 0);

      await tester.tap(find.byIcon(Icons.power));
      expect(taps, 1);
      expect(badgeTaps, 1);
    });

    testWidgets('badge positioned outside the item bounds is still tappable', (tester) async {
      var badgeTaps = 0;
      await _pumpItem(
        tester,
        CircularMenuItem(
          icon: Icons.power,
          onTap: () {},
          onBadgeTap: () => badgeTaps++,
          enableBadge: true,
          badgeTopOffset: 60,
          badgeLabel: 'TS006130',
        ),
      );

      // The badge really sits below the item, i.e. outside its Stack.
      final itemBottom = tester.getBottomLeft(find.byType(ClipOval)).dy;
      expect(tester.getCenter(find.text('TS006130')).dy, greaterThan(itemBottom));

      await tester.tap(find.text('TS006130'));
      expect(badgeTaps, 1);
    });
  });

  group('CircularMenuItem status indicator', () {
    testWidgets('is not shown by default', (tester) async {
      await _pumpItem(tester, CircularMenuItem(icon: Icons.power, onTap: () {}, isActive: true));
      expect(_statusIndicator(), findsNothing);
    });

    testWidgets('is green when active', (tester) async {
      await _pumpItem(
        tester,
        CircularMenuItem(icon: Icons.power, onTap: () {}, enableStatusIndicator: true, isActive: true),
      );
      expect(_statusIndicator(), findsOneWidget);
      expect(_statusIndicatorColor(tester), Colors.green);
    });

    testWidgets('is red when inactive or unknown', (tester) async {
      await _pumpItem(
        tester,
        CircularMenuItem(icon: Icons.power, onTap: () {}, enableStatusIndicator: true, isActive: false),
      );
      expect(_statusIndicatorColor(tester), Colors.red);

      await _pumpItem(tester, CircularMenuItem(icon: Icons.power, onTap: () {}, enableStatusIndicator: true));
      expect(_statusIndicatorColor(tester), Colors.red);
    });

    testWidgets('uses custom colors and size', (tester) async {
      await _pumpItem(
        tester,
        CircularMenuItem(
          icon: Icons.power,
          onTap: () {},
          enableStatusIndicator: true,
          isActive: true,
          statusActiveColor: Colors.blue,
          statusIndicatorSize: 14,
        ),
      );
      expect(_statusIndicatorColor(tester), Colors.blue);
      expect(tester.getSize(_statusIndicator()), const Size(14, 14));

      await _pumpItem(
        tester,
        CircularMenuItem(
          icon: Icons.power,
          onTap: () {},
          enableStatusIndicator: true,
          isActive: false,
          statusInactiveColor: Colors.orange,
        ),
      );
      expect(_statusIndicatorColor(tester), Colors.orange);
    });

    testWidgets('works together with a badge', (tester) async {
      await _pumpItem(
        tester,
        CircularMenuItem(
          icon: Icons.power,
          onTap: () {},
          enableBadge: true,
          badgeLabel: 'CP1',
          enableStatusIndicator: true,
          isActive: true,
        ),
      );
      expect(find.text('CP1'), findsOneWidget);
      expect(_statusIndicatorColor(tester), Colors.green);
    });
  });
}
