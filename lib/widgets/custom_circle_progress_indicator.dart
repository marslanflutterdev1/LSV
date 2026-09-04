import 'package:flutter/material.dart';

import '../core/theme/custom_colors.dart';


class CustomCircleProgressIndicator extends StatefulWidget {
  final double? width;
  final double? height;
  final double? strokeWidth;
  final Color? backgroundColor;
  final Animation<Color?>? valueColor;
  const CustomCircleProgressIndicator({
    super.key,
    this.width,
    this.height,
    this.strokeWidth,
    this.backgroundColor,
    this.valueColor,
  });

  @override
  State<CustomCircleProgressIndicator> createState() =>
      _CustomCircleProgressIndicatorState();
}

class _CustomCircleProgressIndicatorState
    extends State<CustomCircleProgressIndicator> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? 24,
      height: widget.height ?? 24,
      child: CircularProgressIndicator(
        strokeWidth: widget.strokeWidth ?? 1,
        backgroundColor: widget.backgroundColor ?? Colors.grey,
        valueColor: widget.valueColor ?? AlwaysStoppedAnimation<Color>(CustomColors.white),
      ),
    );
  }
}
