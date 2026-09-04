import 'package:flutter/material.dart';

import '../core/theme/custom_colors.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;

  /// Style
  final TextStyle? style;

  /// Helper
  final Widget? helper;
  final TextStyle? helperStyle;

  /// Label
  final String? labelText;
  final TextStyle? labelStyle;

  /// Hint
  final String? hintText;
  final TextStyle? hintStyle;

  /// Actual Text
  final TextStyle? textStyle;

  /// When Occur Error
  final String? errorText;
  final TextStyle? errorStyle;


  /// Keyboard Handle
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// Permission
  final bool? readOnly;
  final bool? obscureText;

  /// Prefix Icon
  final Widget? prefixIcon;
  final Color? prefixIconColor;

  /// Suffix Icon
  final Widget? suffixIcon;
  final Color? suffixIconColor;

  /// Focus
  final bool? enabled;
  final bool? autoFocus;
  final FocusNode? focusNode;

  /// Range Lines
  final int? maxLines;
  final int? minLines;

  /// Fill Color
  final Color? fillColor;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  /// Cursor Color
  final Color? cursorColor;

  /// Interactive Color
  final void Function()? onTap;
  final Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final void Function(PointerDownEvent)? onTapOutside;
  final void Function()? onEditingComplete;
  final void Function(String)? onFieldSubmitted;
  // final String? Function(String?)? validator;


  /// Border
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;

  const CustomTextFormField({
    super.key,
    this.controller,
    this.style,
    this.textStyle,
    this.hintText,
    this.hintStyle,
    this.labelText,
    this.labelStyle,
    this.helper,
    this.helperStyle,
    this.errorText,
    this.errorStyle,
    this.keyboardType,
    this.textInputAction,
    this.enabled,
    this.readOnly,
    this.autoFocus,
    this.obscureText,
    this.prefixIcon,
    this.prefixIconColor,
    this.suffixIcon,
    this.suffixIconColor,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
    this.fillColor,
    this.borderRadius = 8.0,
    this.contentPadding,
    this.cursorColor,


    /// Validate Function
    // this.validator,

    /// Interactive Function
    this.onTap,
    this.onChanged,
    this.onSaved,
    this.onTapOutside,
    this.onEditingComplete,
    this.onFieldSubmitted,


    /// Borders
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly ?? false,
      autofocus: autoFocus ?? false,
      obscureText: obscureText ?? false,
      keyboardType: keyboardType ?? TextInputType.text,
      textInputAction: textInputAction ?? TextInputAction.next,
      style: style ?? Theme.of(context).textTheme.bodyMedium,
      cursorColor: cursorColor,
      decoration: InputDecoration(



        /// Hint Text Section
        hintText: hintText ?? "Hint Text...",
        hintStyle: hintStyle ??  Theme.of(context).textTheme.labelMedium,
        hintFadeDuration: Duration(seconds: 3),

        /// Top Label Text Section
        labelText: labelText,
        labelStyle: labelStyle ?? Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),

        /// Helper
        helper: helper,
        helperStyle:helperStyle ??  TextStyle(color: Colors.amberAccent),

        /// Error Text Section
        errorText: errorText,
        errorStyle: errorStyle ?? TextStyle(color: CustomColors.error),

        /// Fill Color Field
        filled: true,
        fillColor: fillColor ?? Colors.transparent,
        contentPadding:
        contentPadding ?? EdgeInsets.symmetric(horizontal: 10, vertical: 8),

        /// Prefix Icon
        prefixIcon: prefixIcon,
        prefixIconColor: prefixIconColor ?? Theme.of(context).iconTheme.color,

        /// Suffix Icon
        suffixIcon: suffixIcon,
        suffixIconColor: suffixIconColor ?? Theme.of(context).iconTheme.color,

        /// Border Section
        border: border ?? OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: CustomColors.grey, width: 1),
        ),

        /// This enable when user outside field or initial phase or when user unfocus.
        enabledBorder:
        enabledBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: CustomColors.grey, width: 1),
            ),


        /// This enable when user typing or user on field.
        focusedBorder: focusedBorder ?? OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: CustomColors.primaryColor, width: 1),
        ),

        /// This enable when occur error.
        errorBorder: enabledBorder ?? OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: CustomColors.error, width: 1),
        ),
      ),

      /// Validator Function
      // validator: validator,

      /// Interactive Functions
      onTap: onTap,
      onChanged: onChanged,
      onSaved: onSaved,
      onTapOutside: onTapOutside ?? (v) => FocusScope.of(context).unfocus(),
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
