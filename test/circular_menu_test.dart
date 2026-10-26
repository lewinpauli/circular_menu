import 'package:circular_menu/circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _closedIcon = Icons.ev_station;
const _openIcon = Icons.close;

/// Item icons, one per item, so each item can be located on screen.
const _itemIcons = [
  Icons.looks_one,
  Icons.looks_two,
  Icons.looks_3,
  Icons.looks_4,
  Icons.looks_5,
  Icons.looks_6,
];

List<CircularMenuItem> _items(int count, {void Function(int index)? onTap}) {
  return [
    for (var i = 0; i < count; i++) CircularMenuItem(icon: _itemIcons[i], onTap: () => onTap?.call(i)),
  ];
}

CircularMenu _menu({
  GlobalKey<CircularMenuState>? key,
  List<CircularMenuItem>? items,
  List<int>? itemsPerRow = const [6],
  VoidCallback? onOpen,
  VoidCallback? onClose,
  VoidCallback? toggleButtonOnPressed,
  bool toggleButtonBadgeEnabled = false,
  bool toggleButtonBadgeHideOnOpen = true,
  String? toggleButtonBadgeLabel,
  double? toggleButtonBadgeTopOffset,
  VoidCallback? toggleButtonBadgeOnTap,
  String errorMessageIfItemsIsEmpty = 'No Items',
  double toggleButtonMargin = 10,
  double toggleButtonPadding = 10,
}) {
  return CircularMenu(
    key: key,
    alignment: Alignment.center,
    toggleButtonIconInactive: _closedIcon,
    toggleButtonIconActive: _openIcon,
    items: items ?? _items(2),
    itemsPerRow: itemsPerRow,
    onOpen: onOpen,
    onClose: onClose,
    toggleButtonOnPressed: toggleButtonOnPressed,
    toggleButtonBadgeEnabled: toggleButtonBadgeEnabled,
    toggleButtonBadgeHideOnOpen: toggleButtonBadgeHideOnOpen,
    toggleButtonBadgeLabel: toggleButtonBadgeLabel,
    toggleButtonBadgeTopOffset: toggleButtonBadgeTopOffset,
    toggleButtonBadgeOnTap: toggleButtonBadgeOnTap,
    errorMessageIfItemsIsEmpty: errorMessageIfItemsIsEmpty,
    toggleButtonMargin: toggleButtonMargin,
    toggleButtonPadding: toggleButtonPadding,
  );
}

Future<void> _pump(WidgetTester tester, Widget menu) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(body: Center(child: SizedBox(width: 400, height: 400, child: menu))),
  ));
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byIcon(_closedIcon));
  await tester.pumpAndSettle();
}

/// Whether taps on [icon] are blocked by the menu's closed-state IgnorePointer.
bool _ignoresPointer(WidgetTester tester, IconData icon) {
  return tester
      .widgetList<IgnorePointer>(find.ancestor(of: find.byIcon(icon), matching: find.byType(IgnorePointer)))
      .any((w) => w.ignoring);
}

/// Distance of every item (in item order) from the toggle button's center.
List<double> _itemDistances(WidgetTester tester, int count) {
  final center = tester.getCenter(find.byIcon(_openIcon));
  return [for (var i = 0; i < count; i++) (tester.getCenter(find.byIcon(_itemIcons[i])) - center).distance];
}

void main() {
  group('CircularMenu toggle', () {
    testWidgets('tapping the button opens and closes the menu', (tester) async {
      var opened = 0;
      var closed = 0;
      var pressed = 0;
      final key = GlobalKey<CircularMenuState>();
      await _pump(
        tester,
        _menu(
          key: key,
          onOpen: () => opened++,
          onClose: () => closed++,
          toggleButtonOnPressed: () => pressed++,
        ),
      );
      expect(key.currentState!.isOpen, isFalse);
      expect(find.byIcon(_closedIcon), findsOneWidget);

      await _open(tester);
      expect(key.currentState!.isOpen, isTrue);
      expect(find.byIcon(_openIcon), findsOneWidget);
      expect(find.byIcon(_closedIcon), findsNothing);
      expect([opened, closed, pressed], [1, 0, 1]);

      await tester.tap(find.byIcon(_openIcon));
      await tester.pumpAndSettle();
      expect(key.currentState!.isOpen, isFalse);
      expect(find.byIcon(_closedIcon), findsOneWidget);
      expect([opened, closed, pressed], [1, 1, 2]);
    });

    testWidgets('items only accept taps while the menu is open', (tester) async {
      final tapped = <int>[];
      await _pump(tester, _menu(items: _items(2, onTap: tapped.add)));
      expect(_ignoresPointer(tester, _itemIcons[0]), isTrue);

      await _open(tester);
      expect(_ignoresPointer(tester, _itemIcons[0]), isFalse);

      await tester.tap(find.byIcon(_itemIcons[1]));
      expect(tapped, [1]);
    });

    testWidgets('forwardAnimation / reverseAnimation control it programmatically', (tester) async {
      var opened = 0;
      final key = GlobalKey<CircularMenuState>();
      await _pump(tester, _menu(key: key, onOpen: () => opened++));

      key.currentState!.forwardAnimation();
      await tester.pumpAndSettle();
      expect(key.currentState!.isOpen, isTrue);
      expect(find.byIcon(_openIcon), findsOneWidget);
      // Only a tap on the button reports onOpen.
      expect(opened, 0);

      key.currentState!.reverseAnimation();
      await tester.pumpAndSettle();
      expect(key.currentState!.isOpen, isFalse);
    });

    testWidgets('hide() makes the menu invisible and untappable, show() restores it', (tester) async {
      var opened = 0;
      final key = GlobalKey<CircularMenuState>();
      await _pump(tester, _menu(key: key, onOpen: () => opened++));

      key.currentState!.hide();
      await tester.pumpAndSettle();
      final opacity = tester.widget<AnimatedOpacity>(
        find.ancestor(of: find.byIcon(_closedIcon), matching: find.byType(AnimatedOpacity)).first,
      );
      expect(opacity.opacity, 0);
      await tester.tap(find.byIcon(_closedIcon), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(opened, 0);

      key.currentState!.show();
      await tester.pumpAndSettle();
      await _open(tester);
      expect(opened, 1);
    });

    testWidgets('uses the animated icon when no icons are given', (tester) async {
      await _pump(
        tester,
        CircularMenu(
          alignment: Alignment.center,
          toggleButtonAnimatedIconData: AnimatedIcons.menu_close,
          items: _items(2),
        ),
      );
      expect(find.byType(AnimatedIcon), findsOneWidget);
    });
  });

  group('CircularMenu configuration errors', () {
    testWidgets('throws without any toggle icon', (tester) async {
      await _pump(tester, CircularMenu(alignment: Alignment.center, items: _items(2)));
      expect(tester.takeException(), contains('you must provide a value'));
    });

    testWidgets('throws when only one of the two toggle icons is given', (tester) async {
      await _pump(
        tester,
        CircularMenu(alignment: Alignment.center, toggleButtonIconInactive: _closedIcon, items: _items(2)),
      );
      expect(tester.takeException(), contains('you must provide both'));
    });

    testWidgets('throws when only one of the angles is given', (tester) async {
      await _pump(
        tester,
        CircularMenu(
          toggleButtonIconInactive: _closedIcon,
          toggleButtonIconActive: _openIcon,
          startingAngleInRadian: 0,
          items: _items(2),
        ),
      );
      expect(tester.takeException(), contains('endingAngleInRadian can not be null'));
    });

    testWidgets('throws when the starting angle is greater than the ending angle', (tester) async {
      await _pump(
        tester,
        CircularMenu(
          toggleButtonIconInactive: _closedIcon,
          toggleButtonIconActive: _openIcon,
          startingAngleInRadian: 3,
          endingAngleInRadian: 1,
          items: _items(2),
        ),
      );
      expect(tester.takeException(), contains('can not be greater than'));
    });
  });

  group('CircularMenu items', () {
    testWidgets('shows errorMessageIfItemsIsEmpty when there are no items', (tester) async {
      await _pump(tester, _menu(items: [], errorMessageIfItemsIsEmpty: 'Keine Ladepunkte'));
      await _open(tester);
      expect(find.text('Keine Ladepunkte'), findsOneWidget);
    });

    testWidgets('a single item is placed at the radius', (tester) async {
      await _pump(tester, _menu(items: _items(1)));
      await _open(tester);
      expect(_itemDistances(tester, 1).single, greaterThan(0));
    });

    testWidgets('all items share one ring when they fit into itemsPerRow', (tester) async {
      await _pump(tester, _menu(items: _items(5), itemsPerRow: const [6]));
      await _open(tester);

      final distances = _itemDistances(tester, 5);
      for (final d in distances) {
        expect(d, closeTo(distances.first, 0.5));
      }
    });

    testWidgets('itemsPerRow: null puts every item into a single ring', (tester) async {
      await _pump(tester, _menu(items: _items(6), itemsPerRow: null));
      await _open(tester);

      final distances = _itemDistances(tester, 6);
      for (final d in distances) {
        expect(d, closeTo(distances.first, 0.5));
      }
    });

    testWidgets('overflowing items go into further rings, repeating the last itemsPerRow value', (tester) async {
      // [1, 2] with 5 items: ring 1 = 1 item, ring 2 = 2 items, ring 3 = 2 items.
      await _pump(tester, _menu(items: _items(5), itemsPerRow: const [1, 2]));
      await _open(tester);

      final d = _itemDistances(tester, 5);
      // radius 100, rowSpacing 50 -> rings at 100, 150 and 200 (scaled alike).
      expect(d[1], closeTo(d[2], 0.5));
      expect(d[3], closeTo(d[4], 0.5));
      expect(d[1] / d[0], closeTo(1.5, 0.01));
      expect(d[3] / d[0], closeTo(2.0, 0.01));
    });
  });

  group('CircularMenu toggle button badge', () {
    testWidgets('is hidden while open by default', (tester) async {
      await _pump(tester, _menu(toggleButtonBadgeEnabled: true, toggleButtonBadgeLabel: 'TS006130'));
      expect(find.text('TS006130'), findsOneWidget);

      await _open(tester);
      expect(find.text('TS006130'), findsNothing);
    });

    testWidgets('stays visible while open with toggleButtonBadgeHideOnOpen: false', (tester) async {
      await _pump(
        tester,
        _menu(toggleButtonBadgeEnabled: true, toggleButtonBadgeHideOnOpen: false, toggleButtonBadgeLabel: 'TS006130'),
      );
      await _open(tester);
      expect(find.text('TS006130'), findsOneWidget);
    });

    testWidgets('tapping it toggles the menu without toggleButtonBadgeOnTap', (tester) async {
      var opened = 0;
      await _pump(
        tester,
        _menu(
          onOpen: () => opened++,
          toggleButtonBadgeEnabled: true,
          toggleButtonBadgeHideOnOpen: false,
          toggleButtonBadgeLabel: 'TS006130',
        ),
      );

      await tester.tap(find.text('TS006130'));
      await tester.pumpAndSettle();
      expect(opened, 1);
    });

    testWidgets('tapping it below the button calls toggleButtonBadgeOnTap and does not open the menu', (tester) async {
      var badgeTaps = 0;
      var opened = 0;
      await _pump(
        tester,
        _menu(
          onOpen: () => opened++,
          // Same sizes as the station markers in the webinterface map: the
          // button is ~40 px high, so a badge at top 40 lies outside it.
          toggleButtonMargin: 0,
          toggleButtonPadding: 5,
          toggleButtonBadgeEnabled: true,
          toggleButtonBadgeHideOnOpen: false,
          toggleButtonBadgeTopOffset: 40,
          toggleButtonBadgeLabel: 'TS006130',
          toggleButtonBadgeOnTap: () => badgeTaps++,
        ),
      );

      await tester.tap(find.text('TS006130'));
      await tester.pumpAndSettle();
      expect(badgeTaps, 1);
      expect(opened, 0);

      // The button itself still toggles the menu.
      await _open(tester);
      expect(opened, 1);
      expect(badgeTaps, 1);
    });
  });
}
