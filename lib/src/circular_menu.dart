import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'circular_menu_item.dart';

class CircularMenu extends StatefulWidget {
  /// use global key to control animation anywhere in the code
  final GlobalKey<CircularMenuState>? key;

  /// list of CircularMenuItem contains at least two items.
  final List<CircularMenuItem> items;

  /// menu alignment
  final AlignmentGeometry alignment;

  /// menu radius
  final double radius;

  /// List specifying the maximum number of items per row/ring.
  /// e.g., [5, 10, 20] means 5 items in first row, 10 in second, 20+ in subsequent rows.
  /// If the list is shorter than the number of rows needed, the last value is repeated.
  /// Set to null to put all items in a single row.
  final List<int>? itemsPerRow;

  /// Spacing between rows (added to radius for each additional row)
  final double rowSpacing;

  /// widget holds actual page content
  final Widget? backgroundWidget;

  /// animation duration
  final Duration animationDuration;

  /// animation curve in forward
  final Curve curve;

  /// animation curve in rverse
  final Curve reverseCurve;

  /// callback
  final VoidCallback? toggleButtonOnPressed;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final Color? toggleButtonColor;
  final double toggleButtonSize;
  final List<BoxShadow>? toggleButtonBoxShadow;
  final double toggleButtonPadding;
  final double toggleButtonMargin;
  final Color? toggleButtonIconColor;
  final AnimatedIconData? toggleButtonAnimatedIconData;

  //when you want to use your own icon instead of animated icon
  final IconData? toggleButtonIconActive; //when menu is open
  final IconData? toggleButtonIconInactive; //when menu is closed

  /// badge properties for the toggle button
  final bool toggleButtonBadgeEnabled;
  final bool toggleButtonBadgeHideOnOpen;
  final double? toggleButtonBadgeRightOffset;
  final double? toggleButtonBadgeLeftOffset;
  final double? toggleButtonBadgeTopOffset;
  final double? toggleButtonBadgeBottomOffset;
  final double? toggleButtonBadgeRadius;
  final TextStyle? toggleButtonBadgeTextStyle;
  final String? toggleButtonBadgeLabel;
  final Color? toggleButtonBadgeTextColor;
  final Color? toggleButtonBadgeColor;

  /// staring angle in clockwise radian
  final double? startingAngleInRadian;

  /// ending angle in clockwise radian
  final double? endingAngleInRadian;

  //text will only be displayed if no items have been provided
  final String errorMessageIfItemsIsEmpty;

  /// creates a circular menu with specific [radius] and [alignment] .
  /// [toggleButtonElevation] ,[toggleButtonPadding] and [toggleButtonMargin] must be
  /// equal or greater than zero.
  /// [items] must not be null and it must contains two elements at least.
  CircularMenu({
    required this.items,
    this.alignment = Alignment.bottomCenter,
    this.radius = 100,
    this.itemsPerRow = const [6],
    this.rowSpacing = 50,
    this.backgroundWidget,
    this.animationDuration = const Duration(milliseconds: 500),
    this.curve = Curves.bounceOut,
    this.reverseCurve = Curves.fastOutSlowIn,
    this.toggleButtonOnPressed,
    this.onOpen,
    this.onClose,
    this.toggleButtonColor,
    this.toggleButtonBoxShadow,
    this.toggleButtonMargin = 10,
    this.toggleButtonPadding = 10,
    this.toggleButtonSize = 40,
    this.toggleButtonIconColor,
    this.toggleButtonAnimatedIconData,
    this.toggleButtonIconActive,
    this.toggleButtonIconInactive,
    this.toggleButtonBadgeEnabled = false,
    this.toggleButtonBadgeHideOnOpen = true,
    this.toggleButtonBadgeRightOffset,
    this.toggleButtonBadgeLeftOffset,
    this.toggleButtonBadgeTopOffset,
    this.toggleButtonBadgeBottomOffset,
    this.toggleButtonBadgeRadius,
    this.toggleButtonBadgeTextStyle,
    this.toggleButtonBadgeLabel,
    this.toggleButtonBadgeTextColor,
    this.toggleButtonBadgeColor,
    this.key,
    this.startingAngleInRadian,
    this.endingAngleInRadian,
    this.errorMessageIfItemsIsEmpty = 'No Items',
  }) //  : assert(items.isNotEmpty, 'items can not be empty list'),
  //       assert(items.length > 1, 'if you have one item no need to use a Menu'),
  : super(key: key);

  @override
  CircularMenuState createState() => CircularMenuState();
}

class CircularMenuState extends State<CircularMenu> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double? _completeAngle;
  late double _initialAngle;
  double? _endAngle;
  double? _startAngle;
  late Animation<double> _animation;
  bool _isVisible = true;

  /// Returns true if the menu is currently open
  bool get isOpen => _animationController.status != AnimationStatus.dismissed;

  /// Shows the menu button (used by MultiCircularMenu coordination)
  void show() {
    if (mounted) setState(() => _isVisible = true);
  }

  /// Hides the menu button (used by MultiCircularMenu coordination)
  void hide() {
    if (mounted) setState(() => _isVisible = false);
  }

  /// forward animation
  void forwardAnimation() {
    _animationController.forward();
  }

  /// reverse animation
  void reverseAnimation() {
    _animationController.reverse();
  }

  @override
  void initState() {
    _configure();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: widget.curve, reverseCurve: widget.reverseCurve),
    );
    super.initState();
  }

  void _configure() {
    if (widget.toggleButtonAnimatedIconData == null &&
        widget.toggleButtonIconInactive == null &&
        widget.toggleButtonIconActive == null) {
      throw 'you must provide a value for toggleButtonAnimatedIconData or toggleButtonIconActive and toggleButtonIconInactive';
    }

    if (widget.toggleButtonAnimatedIconData == null &&
            (widget.toggleButtonIconInactive != null && widget.toggleButtonIconActive == null) ||
        (widget.toggleButtonIconInactive == null && widget.toggleButtonIconActive != null)) {
      throw 'you must provide both toggleButtonIconActive and toggleButtonIconInactive, if you dont want to use toggleButtonAnimatedIconData';
    }

    if (widget.startingAngleInRadian != null || widget.endingAngleInRadian != null) {
      if (widget.startingAngleInRadian == null) {
        throw ('startingAngleInRadian can not be null');
      }
      if (widget.endingAngleInRadian == null) {
        throw ('endingAngleInRadian can not be null');
      }

      if (widget.startingAngleInRadian! < 0) {
        throw 'startingAngleInRadian has to be in clockwise radian';
      }
      if (widget.endingAngleInRadian! < 0) {
        throw 'endingAngleInRadian has to be in clockwise radian';
      }
      _startAngle = (widget.startingAngleInRadian! / math.pi) % 2;
      _endAngle = (widget.endingAngleInRadian! / math.pi) % 2;
      if (_endAngle! < _startAngle!) {
        throw 'startingAngleInRadian can not be greater than endingAngleInRadian';
      }
      _completeAngle = _startAngle == _endAngle ? 2 * math.pi : (_endAngle! - _startAngle!) * math.pi;
      _initialAngle = _startAngle! * math.pi;
    } else {
      switch (widget.alignment.toString()) {
        case 'Alignment.bottomCenter':
          _completeAngle = 1 * math.pi;
          _initialAngle = 1 * math.pi;
          break;
        case 'Alignment.topCenter':
          _completeAngle = 1 * math.pi;
          _initialAngle = 0 * math.pi;
          break;
        case 'Alignment.centerLeft':
          _completeAngle = 1 * math.pi;
          _initialAngle = 1.5 * math.pi;
          break;
        case 'Alignment.centerRight':
          _completeAngle = 1 * math.pi;
          _initialAngle = 0.5 * math.pi;
          break;
        case 'Alignment.center':
          _completeAngle = 2 * math.pi;
          _initialAngle = 0 * math.pi;
          break;
        case 'Alignment.bottomRight':
          _completeAngle = 0.5 * math.pi;
          _initialAngle = 1 * math.pi;
          break;
        case 'Alignment.bottomLeft':
          _completeAngle = 0.5 * math.pi;
          _initialAngle = 1.5 * math.pi;
          break;
        case 'Alignment.topLeft':
          _completeAngle = 0.5 * math.pi;
          _initialAngle = 0 * math.pi;
          break;
        case 'Alignment.topRight':
          _completeAngle = 0.5 * math.pi;
          _initialAngle = 0.5 * math.pi;
          break;
        default:
          throw 'startingAngleInRadian and endingAngleInRadian can not be null';
      }
    }
  }

  @override
  void didUpdateWidget(oldWidget) {
    _configure();
    super.didUpdateWidget(oldWidget);
  }

  Widget _buildAnimatedItem(Widget child) {
    return Transform.scale(
      scale: _animation.value,
      child: Transform.rotate(
        angle: _animation.value * (math.pi * 2),
        child: child,
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    if (widget.items.isEmpty) {
      return [
        Positioned.fill(
          child: _buildPositionedItem(
            Container(
              padding: EdgeInsets.all(10),
              width: 100,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                widget.errorMessageIfItemsIsEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
            _initialAngle,
          ),
        ),
      ];
    } else if (widget.items.length == 1) {
      return [
        Positioned.fill(
          child: _buildPositionedItem(widget.items[0], _initialAngle),
        ),
      ];
    } else {
      List<Widget> items = [];

      // Calculate rows if itemsPerRow is set
      final List<int>? perRowList = widget.itemsPerRow;
      final int totalItems = widget.items.length;

      // Group items into rows
      int itemIndex = 0;
      int rowIndex = 0;

      while (itemIndex < totalItems) {
        // Get max items for this row from the list (repeat last value if list is shorter)
        final int maxPerRow;
        if (perRowList == null || perRowList.isEmpty) {
          maxPerRow = totalItems; // All items in one row
        } else if (rowIndex < perRowList.length) {
          maxPerRow = perRowList[rowIndex];
        } else {
          maxPerRow = perRowList.last; // Repeat last value for remaining rows
        }

        // Calculate how many items in this row
        final int itemsInThisRow = (itemIndex + maxPerRow <= totalItems) ? maxPerRow : totalItems - itemIndex;

        // Calculate radius for this row
        final double rowRadius = widget.radius + (rowIndex * widget.rowSpacing);

        // Add items for this row
        for (int i = 0; i < itemsInThisRow; i++) {
          final item = widget.items[itemIndex];

          double angle;
          if (_completeAngle == (2 * math.pi)) {
            // Full circle - evenly distribute
            angle = _initialAngle + (_completeAngle! / itemsInThisRow) * i;
          } else {
            // Partial arc
            if (itemsInThisRow == 1) {
              angle = _initialAngle + _completeAngle! / 2;
            } else {
              angle = _initialAngle + (_completeAngle! / (itemsInThisRow - 1)) * i;
            }
          }

          items.add(Positioned.fill(
            child: _buildPositionedItemWithRadius(item, angle, rowRadius),
          ));

          itemIndex++;
        }
        rowIndex++;
      }
      return items;
    }
  }

  Widget _buildPositionedItemWithRadius(Widget child, double angle, double itemRadius) {
    final offset = Offset.fromDirection(angle, _animation.value * itemRadius);

    // Get base alignment
    final baseAlignment = widget.alignment.resolve(TextDirection.ltr);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Convert pixel offset to alignment units
        // Alignment goes from -1 to 1 across width/height
        final alignmentOffsetX = (offset.dx / constraints.maxWidth) * 2;
        final alignmentOffsetY = (offset.dy / constraints.maxHeight) * 2;

        final targetAlignment = Alignment(
          baseAlignment.x + alignmentOffsetX,
          baseAlignment.y + alignmentOffsetY,
        );

        return Align(
          alignment: targetAlignment,
          child: IgnorePointer(
            ignoring: _animation.value == 0,
            child: _buildAnimatedItem(child),
          ),
        );
      },
    );
  }

  Widget _buildPositionedItem(Widget child, double angle) {
    final offset = Offset.fromDirection(angle, _animation.value * widget.radius);

    // Get base alignment
    final baseAlignment = widget.alignment.resolve(TextDirection.ltr);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Convert pixel offset to alignment units
        // Alignment goes from -1 to 1 across width/height
        final alignmentOffsetX = (offset.dx / constraints.maxWidth) * 2;
        final alignmentOffsetY = (offset.dy / constraints.maxHeight) * 2;

        final targetAlignment = Alignment(
          baseAlignment.x + alignmentOffsetX,
          baseAlignment.y + alignmentOffsetY,
        );

        return Align(
          alignment: targetAlignment,
          child: IgnorePointer(
            ignoring: _animation.value == 0,
            child: _buildAnimatedItem(child),
          ),
        );
      },
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: widget.alignment,
        child: CircularMenuItem(
          icon: widget.toggleButtonIconInactive != null && widget.toggleButtonIconActive != null
              ? (_animationController.status == AnimationStatus.dismissed
                  ? widget.toggleButtonIconInactive
                  : widget.toggleButtonIconActive)
              : null,
          margin: widget.toggleButtonMargin,
          color: widget.toggleButtonColor ?? Theme.of(context).primaryColor,
          padding: (-_animation.value * widget.toggleButtonPadding * 0.5) + widget.toggleButtonPadding,
          onTap: () {
            if (_animationController.status == AnimationStatus.dismissed) {
              _animationController.forward();
              widget.onOpen?.call();
            } else {
              _animationController.reverse();
              widget.onClose?.call();
            }
            widget.toggleButtonOnPressed?.call();
          },
          boxShadow: widget.toggleButtonBoxShadow,
          animatedIcon: widget.toggleButtonIconInactive == null && widget.toggleButtonIconActive == null
              ? AnimatedIcon(
                  icon: widget.toggleButtonAnimatedIconData!, //AnimatedIcons.menu_close,
                  size: widget.toggleButtonSize,
                  color: widget.toggleButtonIconColor ?? Colors.white,
                  progress: _animation,
                )
              : null,
          enableBadge: widget.toggleButtonBadgeEnabled &&
              !(widget.toggleButtonBadgeHideOnOpen && _animationController.status != AnimationStatus.dismissed),
          badgeRightOffset: widget.toggleButtonBadgeRightOffset,
          badgeLeftOffset: widget.toggleButtonBadgeLeftOffset,
          badgeTopOffset: widget.toggleButtonBadgeTopOffset,
          badgeBottomOffset: widget.toggleButtonBadgeBottomOffset,
          badgeRadius: widget.toggleButtonBadgeRadius,
          badgeTextStyle: widget.toggleButtonBadgeTextStyle,
          badgeLabel: widget.toggleButtonBadgeLabel,
          badgeTextColor: widget.toggleButtonBadgeTextColor,
          badgeColor: widget.toggleButtonBadgeColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !_isVisible,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            widget.backgroundWidget ?? Container(),
            ..._buildMenuItems(),
            _buildMenuButton(context),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _animationController.removeListener(() {});
    _animation.removeListener(() {});
    super.dispose();
  }
}
