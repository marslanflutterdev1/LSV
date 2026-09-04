import 'package:flutter/material.dart';

import '../core/theme/custom_colors.dart';

class CustomDialogBox extends StatelessWidget {
  final Widget? icon;
  final EdgeInsetsGeometry? iconPadding;
  final Color? iconColor;
  final Widget? title;
  final EdgeInsetsGeometry? titlePadding;
  final TextStyle? titleTextStyle;
  final Widget? content;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? contentTextStyle;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? actionsPadding;
  final MainAxisAlignment? actionsAlignment;
  final Color? backgroundColor;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final ShapeBorder? shape;
  const CustomDialogBox({
    super.key,
    this.backgroundColor,
    this.shape,
    this.icon,
    this.iconPadding,
    this.iconColor,
    this.title,
    this.titlePadding,
    this.titleTextStyle,
    this.content,
    this.contentPadding,
    this.contentTextStyle,
    this.actions,
    this.actionsPadding,
    this.actionsAlignment,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      icon: icon,
      iconColor: iconColor ?? CustomColors.primaryColor,
      iconPadding: iconPadding,
      title: title,
      titleTextStyle: titleTextStyle,
      titlePadding: titlePadding,
      content: content,
      contentTextStyle: contentTextStyle,
      contentPadding: contentPadding,
      actions: actions,
      actionsPadding: actionsPadding,
      actionsAlignment: actionsAlignment ?? MainAxisAlignment.center,
      elevation: elevation ?? 10,
      shadowColor: shadowColor ?? CustomColors.primaryColor,
      surfaceTintColor: surfaceTintColor,
      backgroundColor: backgroundColor ?? Colors.white,
      shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      insetAnimationCurve: Curves.bounceInOut,
    );
  }
}
