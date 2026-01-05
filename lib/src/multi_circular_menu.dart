import 'package:flutter/material.dart';

import 'circular_menu.dart';

/// Callback type for when a menu should be brought to front
typedef OnBringToFrontCallback = void Function(GlobalKey<CircularMenuState> key);

/// Controller to manage multiple CircularMenu instances.
/// Use this to coordinate menus so that when one opens, others hide.
class CircularMenuGroupController extends ChangeNotifier {
  final List<GlobalKey<CircularMenuState>> _menuKeys = [];
  GlobalKey<CircularMenuState>? _activeMenuKey;

  /// Optional callback to handle bringing a menu to front (z-order)
  /// Useful for map markers where you need to reorder the marker list
  OnBringToFrontCallback? onBringToFront;

  /// Returns the list of registered menu keys (read-only copy)
  List<GlobalKey<CircularMenuState>> get menuKeys => List.unmodifiable(_menuKeys);

  /// Returns the index of a key in the registration order
  int indexOf(GlobalKey<CircularMenuState> key) => _menuKeys.indexOf(key);

  /// Register a menu key with this controller
  void register(GlobalKey<CircularMenuState> key) {
    if (!_menuKeys.contains(key)) {
      _menuKeys.add(key);
    }
  }

  /// Unregister a menu key from this controller
  void unregister(GlobalKey<CircularMenuState> key) {
    _menuKeys.remove(key);
    if (_activeMenuKey == key) {
      _activeMenuKey = null;
    }
  }

  /// Moves a key to the end of the list (bringing it to front in z-order)
  /// Returns the old index of the key, or -1 if not found
  int bringKeyToFront(GlobalKey<CircularMenuState> key) {
    final index = _menuKeys.indexOf(key);
    if (index == -1 || index == _menuKeys.length - 1) return index;

    _menuKeys.removeAt(index);
    _menuKeys.add(key);
    return index;
  }

  /// Called when a menu is opened - closes all other menus and optionally brings to front
  void onMenuOpened(GlobalKey<CircularMenuState> openedKey) {
    _activeMenuKey = openedKey;
    for (final key in _menuKeys) {
      if (key != openedKey && key.currentState != null) {
        // Close any other open menus
        if (key.currentState!.isOpen) {
          key.currentState!.reverseAnimation();
        }
      }
    }
    // Call the bring-to-front callback if set
    onBringToFront?.call(openedKey);
    notifyListeners();
  }

  /// Called when a menu is closed
  void onMenuClosed(GlobalKey<CircularMenuState> closedKey) {
    if (_activeMenuKey == closedKey) {
      _activeMenuKey = null;
      notifyListeners();
    }
  }

  /// Returns true if there's an active (open) menu
  bool get hasActiveMenu => _activeMenuKey != null;

  /// Returns the key of the currently active menu, if any
  GlobalKey<CircularMenuState>? get activeMenuKey => _activeMenuKey;
}

class MultiCircularMenu extends StatefulWidget {
  /// List of CircularMenu contains at least two CircularMenu objects.
  final List<CircularMenu> menus;

  /// widget holds actual page content
  final Widget? backgroundWidget;

  /// When true, opening one menu will hide all other menus.
  /// They will reappear when the active menu is closed.
  final bool hideOthersOnOpen;

  const MultiCircularMenu({
    required this.menus,
    this.backgroundWidget,
    this.hideOthersOnOpen = false,
  })  : assert(menus.length != 0, 'menus can not be empty list'),
        assert(menus.length > 1, 'no need to use MultiCircularMenu you can directly use CircularMenu');

  @override
  State<MultiCircularMenu> createState() => _MultiCircularMenuState();
}

class _MultiCircularMenuState extends State<MultiCircularMenu> {
  late CircularMenuGroupController _controller;
  late List<CircularMenu> _wrappedMenus;

  @override
  void initState() {
    super.initState();
    _controller = CircularMenuGroupController();
    _wrappedMenus = _wrapMenus();
  }

  @override
  void didUpdateWidget(MultiCircularMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menus != widget.menus || oldWidget.hideOthersOnOpen != widget.hideOthersOnOpen) {
      _wrappedMenus = _wrapMenus();
    }
  }

  List<CircularMenu> _wrapMenus() {
    if (!widget.hideOthersOnOpen) {
      return widget.menus;
    }

    return widget.menus.map((menu) {
      // Use existing key or create a new one
      final key = menu.key ?? GlobalKey<CircularMenuState>();
      _controller.register(key);

      // Wrap the original callbacks
      final originalOnOpen = menu.onOpen;
      final originalOnClose = menu.onClose;

      return CircularMenu(
        key: key,
        items: menu.items,
        alignment: menu.alignment,
        radius: menu.radius,
        backgroundWidget: menu.backgroundWidget,
        animationDuration: menu.animationDuration,
        curve: menu.curve,
        reverseCurve: menu.reverseCurve,
        toggleButtonOnPressed: menu.toggleButtonOnPressed,
        onOpen: () {
          _controller.onMenuOpened(key);
          originalOnOpen?.call();
        },
        onClose: () {
          _controller.onMenuClosed(key);
          originalOnClose?.call();
        },
        toggleButtonColor: menu.toggleButtonColor,
        toggleButtonBoxShadow: menu.toggleButtonBoxShadow,
        toggleButtonMargin: menu.toggleButtonMargin,
        toggleButtonPadding: menu.toggleButtonPadding,
        toggleButtonSize: menu.toggleButtonSize,
        toggleButtonIconColor: menu.toggleButtonIconColor,
        toggleButtonAnimatedIconData: menu.toggleButtonAnimatedIconData,
        toggleButtonIconActive: menu.toggleButtonIconActive,
        toggleButtonIconInactive: menu.toggleButtonIconInactive,
        toggleButtonBadgeEnabled: menu.toggleButtonBadgeEnabled,
        toggleButtonBadgeHideOnOpen: menu.toggleButtonBadgeHideOnOpen,
        toggleButtonBadgeRightOffset: menu.toggleButtonBadgeRightOffset,
        toggleButtonBadgeLeftOffset: menu.toggleButtonBadgeLeftOffset,
        toggleButtonBadgeTopOffset: menu.toggleButtonBadgeTopOffset,
        toggleButtonBadgeBottomOffset: menu.toggleButtonBadgeBottomOffset,
        toggleButtonBadgeRadius: menu.toggleButtonBadgeRadius,
        toggleButtonBadgeTextStyle: menu.toggleButtonBadgeTextStyle,
        toggleButtonBadgeLabel: menu.toggleButtonBadgeLabel,
        toggleButtonBadgeTextColor: menu.toggleButtonBadgeTextColor,
        toggleButtonBadgeColor: menu.toggleButtonBadgeColor,
        startingAngleInRadian: menu.startingAngleInRadian,
        endingAngleInRadian: menu.endingAngleInRadian,
        errorMessageIfItemsIsEmpty: menu.errorMessageIfItemsIsEmpty,
      );
    }).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.backgroundWidget ?? Container(),
        ..._wrappedMenus,
      ],
    );
  }
}
