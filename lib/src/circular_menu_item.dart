import 'package:flutter/material.dart';

class CircularMenuItem extends StatelessWidget {
  /// if icon and animatedIcon are passed, icon will be ignored
  final IconData? icon;
  final Color? color;
  final Color? iconColor;
  final VoidCallback onTap;
  final double iconSize;
  final double padding;
  final double margin;
  final List<BoxShadow>? boxShadow;
  final bool enableBadge;
  final double? badgeRightOffset;
  final double? badgeLeftOffset;
  final double? badgeTopOffset;
  final double? badgeBottomOffset;
  final double? badgeRadius;
  final TextStyle? badgeTextStyle;
  final String? badgeLabel;
  final Color? badgeTextColor;
  final Color? badgeColor;

  /// Status indicator - shows a small colored circle (e.g., green=active, red=inactive)
  final bool enableStatusIndicator;
  final bool? isActive;
  final Color? statusActiveColor;
  final Color? statusInactiveColor;
  final double statusIndicatorSize;
  final double? statusIndicatorRightOffset;
  final double? statusIndicatorTopOffset;

  /// if animatedIcon and icon are passed, icon will be ignored
  final AnimatedIcon? animatedIcon;

  /// creates a menu item .
  /// [onTap] must not be null.
  /// [padding] and [margin]  must be equal or greater than zero.
  CircularMenuItem({
    required this.onTap,
    this.icon,
    this.color,
    this.iconSize = 30,
    this.boxShadow,
    this.iconColor,
    this.animatedIcon,
    this.padding = 10,
    this.margin = 10,
    this.enableBadge = false,
    this.badgeBottomOffset,
    this.badgeLeftOffset,
    this.badgeRightOffset,
    this.badgeTopOffset,
    this.badgeRadius,
    this.badgeTextStyle,
    this.badgeLabel,
    this.badgeTextColor,
    this.badgeColor,
    this.enableStatusIndicator = false,
    this.isActive,
    this.statusActiveColor,
    this.statusInactiveColor,
    this.statusIndicatorSize = 10,
    this.statusIndicatorRightOffset,
    this.statusIndicatorTopOffset,
  })  : assert(padding >= 0.0),
        assert(margin >= 0.0);

  Widget _buildCircularMenuItem(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: color ?? Theme.of(context).primaryColor,
                blurRadius: 10,
              ),
            ],
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Material(
          color: color ?? Theme.of(context).primaryColor,
          child: InkWell(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: animatedIcon == null
                  ? Icon(
                      icon,
                      size: iconSize,
                      color: iconColor ?? Colors.white,
                    )
                  : animatedIcon,
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  Widget _buildCircularMenuItemWithBadge(BuildContext context) {
    return _Badge(
      color: badgeColor,
      bottomOffset: badgeBottomOffset,
      rightOffset: badgeRightOffset,
      leftOffset: badgeLeftOffset,
      topOffset: badgeTopOffset,
      radius: badgeRadius,
      textStyle: badgeTextStyle,
      onTap: onTap,
      textColor: badgeTextColor,
      label: badgeLabel,
      child: _buildCircularMenuItem(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget item = enableBadge ? _buildCircularMenuItemWithBadge(context) : _buildCircularMenuItem(context);

    if (enableStatusIndicator) {
      item = _buildWithStatusIndicator(context, item);
    }

    return item;
  }

  Widget _buildWithStatusIndicator(BuildContext context, Widget child) {
    final Color indicatorColor =
        isActive == true ? (statusActiveColor ?? Colors.green) : (statusInactiveColor ?? Colors.red);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: statusIndicatorRightOffset ?? -2,
          top: statusIndicatorTopOffset ?? -2,
          child: Container(
            width: statusIndicatorSize,
            height: statusIndicatorSize,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    Key? key,
    required this.child,
    required this.label,
    this.color,
    this.textColor,
    this.onTap,
    this.radius,
    this.bottomOffset,
    this.leftOffset,
    this.rightOffset,
    this.topOffset,
    this.textStyle,
  }) : super(key: key);

  final Widget child;
  final String? label;
  final Color? color;
  final Color? textColor;
  final Function? onTap;
  final double? rightOffset;
  final double? leftOffset;
  final double? topOffset;
  final double? bottomOffset;
  final double? radius;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: rightOffset,
          top: topOffset,
          left: leftOffset,
          bottom: bottomOffset,
          child: FittedBox(
            child: GestureDetector(
              onTap: onTap as void Function()? ?? () {},
              child: Container(
                // maxRadius: radius ?? 10,
                // minRadius: radius ?? 10,
                //backgroundcolor: color ?? Theme.of(context).primaryColor,
                decoration: BoxDecoration(
                  color: color ?? Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(radius ?? 10),
                ),

                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Text(
                      label ?? '',
                      textAlign: TextAlign.center,
                      style: textStyle ??
                          TextStyle(fontSize: 10, color: textColor ?? Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
