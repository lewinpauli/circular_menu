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
    this.backgroundWidget,
    this.animationDuration = const Duration(milliseconds: 500),
    this.curve = Curves.bounceOut,
    this.reverseCurve = Curves.fastOutSlowIn,
    this.toggleButtonOnPressed,
    this.toggleButtonColor,
    this.toggleButtonBoxShadow,
    this.toggleButtonMargin = 10,
    this.toggleButtonPadding = 10,
    this.toggleButtonSize = 40,
    this.toggleButtonIconColor,
    this.toggleButtonAnimatedIconData,
    this.toggleButtonIconActive,
    this.toggleButtonIconInactive,
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
  late int _itemsCount;
  late Animation<double> _animation;

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
    _itemsCount = widget.items.length;
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
      widget.items.asMap().forEach((index, item) {
        double angle = _completeAngle == (2 * math.pi)
            ? (_initialAngle + (_completeAngle! / (_itemsCount)) * index)
            : (_initialAngle + (_completeAngle! / (_itemsCount - 1)) * index);

        items.add(Positioned.fill(
          child: _buildPositionedItem(item, angle),
        ));
      });
      return items;
    }
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
            _animationController.status == AnimationStatus.dismissed
                ? (_animationController).forward()
                : (_animationController).reverse();
            if (widget.toggleButtonOnPressed != null) {
              widget.toggleButtonOnPressed!();
            }
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        widget.backgroundWidget ?? Container(),
        ..._buildMenuItems(),
        _buildMenuButton(context),
      ],
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
