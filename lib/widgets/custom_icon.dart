import 'package:flutter/material.dart';
import 'package:satellite_view/core/theme/custom_colors.dart';

class CustomIcon extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? bgColor;
  final String? iconUrl;
  final EdgeInsetsGeometry? padding;
  final void Function()? onTap;
  final BorderRadiusGeometry? borderRadius;
  const CustomIcon({
    super.key,
    this.width,
    this.height,
    this.bgColor,
    this.iconUrl,
    this.padding,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 40,
        height: height ?? 40,
        decoration: BoxDecoration(
          color: bgColor ?? CustomColors.iconBackgroundColor,
          borderRadius: borderRadius ??  BorderRadius.circular(8),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(10.0),
          child: Center(child: Image.asset("$iconUrl", color: CustomColors.primaryColor, scale: 1.0)),
        ),
      ),
    );
  }
}
