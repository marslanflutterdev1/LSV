import 'package:flutter/material.dart';
import 'package:satellite_view/widgets/custom_circle_progress_indicator.dart';
import '../core/theme/custom_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final TextStyle? textStyle;
  final WidgetStateProperty<Color?>? backgroundColor;
  final WidgetStateProperty<OutlinedBorder?>? shape;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.isLoading,
    this.width,
    this.height,
    this.textStyle,
    this.backgroundColor,
    this.shape
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
          backgroundColor: backgroundColor ??  MaterialStateProperty.all(CustomColors.primaryColor),
          shape: shape ?? MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        child: isLoading
            ? CustomCircleProgressIndicator()
            : Text(
          text,
          style:
          textStyle ??
              Theme.of(context).textTheme.titleLarge?.copyWith(
                color: CustomColors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
