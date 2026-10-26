import 'package:circular_menu/circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CircularMenu _menu(
  GlobalKey<CircularMenuState> key,
  Alignment alignment,
  IconData closedIcon, {
  VoidCallback? onOpen,
  VoidCallback? onClose,
  String? badgeLabel,
  VoidCallback? onBadgeTap,
}) {
  return CircularMenu(
    key: key,
    alignment: alignment,
    toggleButtonIconInactive: closedIcon,
    toggleButtonIconActive: Icons.close,
    onOpen: onOpen,
    onClose: onClose,
    toggleButtonBadgeEnabled: badgeLabel != null,
    toggleButtonBadgeHideOnOpen: false,
    toggleButtonBadgeLabel: badgeLabel,
    toggleButtonBadgeOnTap: onBadgeTap,
    items: [
      CircularMenuItem(icon: Icons.power, onTap: () {}),
      CircularMenuItem(icon: Icons.bolt, onTap: () {}),
    ],
  );
}

/// Two independent menus in one Stack (like two stations on the map).
Future<void> _pumpTwoMenus(
  WidgetTester tester,
  GlobalKey<CircularMenuState> keyA,
  GlobalKey<CircularMenuState> keyB, {
  VoidCallback? onOpenA,
}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 800,
        height: 800,
        child: Stack(children: [
          _menu(keyA, Alignment.topLeft, Icons.looks_one, onOpen: onOpenA),
          _menu(keyB, Alignment.bottomRight, Icons.looks_two),
        ]),
      ),
    ),
  ));
}

void main() {
  group('CircularMenuGroupController registration', () {
    test('register ignores duplicates and keeps the order', () {
      final controller = CircularMenuGroupController();
      final a = GlobalKey<CircularMenuState>();
      final b = GlobalKey<CircularMenuState>();

      controller.register(a);
      controller.register(b);
      controller.register(a);

      expect(controller.menuKeys, [a, b]);
      expect(controller.indexOf(b), 1);
      expect(() => controller.menuKeys.add(a), throwsUnsupportedError);
    });

    test('unregister removes the key and clears it as active menu', () {
      final controller = CircularMenuGroupController();
      final a = GlobalKey<CircularMenuState>();
      controller.register(a);
      controller.onMenuOpened(a);
      expect(controller.activeMenuKey, a);

      controller.unregister(a);
      expect(controller.menuKeys, isEmpty);
      expect(controller.hasActiveMenu, isFalse);
    });

    test('bringKeyToFront moves the key to the end and returns its old index', () {
      final controller = CircularMenuGroupController();
      final a = GlobalKey<CircularMenuState>();
      final b = GlobalKey<CircularMenuState>();
      final c = GlobalKey<CircularMenuState>();
      for (final key in [a, b, c]) {
        controller.register(key);
      }

      expect(controller.bringKeyToFront(a), 0);
      expect(controller.menuKeys, [b, c, a]);

      // Already in front: index returned, order unchanged.
      expect(controller.bringKeyToFront(a), 2);
      expect(controller.menuKeys, [b, c, a]);

      expect(controller.bringKeyToFront(GlobalKey<CircularMenuState>()), -1);
      expect(controller.menuKeys, [b, c, a]);
    });
  });

  group('CircularMenuGroupController open / close', () {
    test('onMenuOpened sets the active menu, calls onBringToFront and notifies', () {
      final controller = CircularMenuGroupController();
      final a = GlobalKey<CircularMenuState>();
      controller.register(a);
      final broughtToFront = <GlobalKey<CircularMenuState>>[];
      controller.onBringToFront = broughtToFront.add;
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.onMenuOpened(a);

      expect(controller.activeMenuKey, a);
      expect(controller.hasActiveMenu, isTrue);
      expect(broughtToFront, [a]);
      expect(notifications, 1);
    });

    test('onMenuClosed only clears the active menu for that menu', () {
      final controller = CircularMenuGroupController();
      final a = GlobalKey<CircularMenuState>();
      final b = GlobalKey<CircularMenuState>();
      controller.onMenuOpened(a);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.onMenuClosed(b);
      expect(controller.activeMenuKey, a);
      expect(notifications, 0);

      controller.onMenuClosed(a);
      expect(controller.hasActiveMenu, isFalse);
      expect(notifications, 1);
    });

    testWidgets('onMenuOpened closes every other open menu', (tester) async {
      final controller = CircularMenuGroupController();
      final keyA = GlobalKey<CircularMenuState>();
      final keyB = GlobalKey<CircularMenuState>();
      controller
        ..register(keyA)
        ..register(keyB);
      await _pumpTwoMenus(tester, keyA, keyB);

      keyA.currentState!.forwardAnimation();
      await tester.pumpAndSettle();
      keyB.currentState!.forwardAnimation();
      await tester.pumpAndSettle();
      expect(keyA.currentState!.isOpen, isTrue);

      controller.onMenuOpened(keyB);
      await tester.pumpAndSettle();

      expect(keyA.currentState!.isOpen, isFalse);
      expect(keyB.currentState!.isOpen, isTrue);
    });
  });

  group('MultiCircularMenu', () {
    Future<void> pumpMulti(
      WidgetTester tester,
      List<CircularMenu> menus, {
      bool hideOthersOnOpen = true,
    }) {
      return tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 800,
            child: MultiCircularMenu(hideOthersOnOpen: hideOthersOnOpen, menus: menus),
          ),
        ),
      ));
    }

    test('asserts at least two menus', () {
      final key = GlobalKey<CircularMenuState>();
      expect(() => MultiCircularMenu(menus: const []), throwsAssertionError);
      expect(
        () => MultiCircularMenu(menus: [_menu(key, Alignment.center, Icons.looks_one)]),
        throwsAssertionError,
      );
    });

    testWidgets('with hideOthersOnOpen, opening one menu closes the other', (tester) async {
      final keyA = GlobalKey<CircularMenuState>();
      final keyB = GlobalKey<CircularMenuState>();
      var openedA = 0;
      await pumpMulti(tester, [
        _menu(keyA, Alignment.topLeft, Icons.looks_one, onOpen: () => openedA++),
        _menu(keyB, Alignment.bottomRight, Icons.looks_two),
      ]);

      await tester.tap(find.byIcon(Icons.looks_one));
      await tester.pumpAndSettle();
      expect(keyA.currentState!.isOpen, isTrue);
      // The menu's own onOpen is still called.
      expect(openedA, 1);

      await tester.tap(find.byIcon(Icons.looks_two));
      await tester.pumpAndSettle();
      expect(keyB.currentState!.isOpen, isTrue);
      expect(keyA.currentState!.isOpen, isFalse);
    });

    testWidgets('without hideOthersOnOpen, several menus can be open', (tester) async {
      final keyA = GlobalKey<CircularMenuState>();
      final keyB = GlobalKey<CircularMenuState>();
      await pumpMulti(
        tester,
        [
          _menu(keyA, Alignment.topLeft, Icons.looks_one),
          _menu(keyB, Alignment.bottomRight, Icons.looks_two),
        ],
        hideOthersOnOpen: false,
      );

      await tester.tap(find.byIcon(Icons.looks_one));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.looks_two));
      await tester.pumpAndSettle();

      expect(keyA.currentState!.isOpen, isTrue);
      expect(keyB.currentState!.isOpen, isTrue);
    });

    testWidgets('keeps toggleButtonBadgeOnTap when wrapping the menus', (tester) async {
      final keyA = GlobalKey<CircularMenuState>();
      final keyB = GlobalKey<CircularMenuState>();
      var badgeTaps = 0;
      await pumpMulti(tester, [
        _menu(keyA, Alignment.topLeft, Icons.looks_one, badgeLabel: 'TS001', onBadgeTap: () => badgeTaps++),
        _menu(keyB, Alignment.bottomRight, Icons.looks_two),
      ]);

      await tester.tap(find.text('TS001'));
      await tester.pumpAndSettle();

      expect(badgeTaps, 1);
      expect(keyA.currentState!.isOpen, isFalse);
    });
  });
}
