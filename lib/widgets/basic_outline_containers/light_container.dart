import 'package:flutter/material.dart';

class LightContainer extends StatelessWidget {
  const LightContainer({
    Key? key,
    required this.child,
    this.margin,
    this.padding,
    this.width,
    this.height,
    this.borderWidth,
    this.borderRadius,
    this.borderColor,
  }) : super(key: key);

  final Widget child;
  final double? padding;
  final double? margin;
  final double? borderWidth;
  final double? width;
  final double? height;
  final double? borderRadius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: width ?? double.infinity,
        height: height,
        margin: EdgeInsets.all(margin ?? 5),
        padding: EdgeInsets.all(padding ?? 5),
        decoration: BoxDecoration(
          border: Border.all(
              color: borderColor ?? Colors.white60, width: borderWidth ?? 1),
          borderRadius: BorderRadius.all(
            Radius.circular(borderRadius ?? 5),
          ),
          color: Colors.grey[800],
        ),
        child: child);
  }
}
