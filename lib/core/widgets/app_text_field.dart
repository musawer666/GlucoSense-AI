import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors/app_colors.dart';

/// Pill-shaped filled field (no stroke) matching the Luminous Vitality inputs.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.enabled = true,
    this.autofillHints,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.showObscureToggle = false,
    this.onToggleObscure,
    this.readOnly = false,
    this.onTap,
    this.fillColor,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final Widget? prefixIcon;
  final Widget? suffix;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final bool showObscureToggle;
  final VoidCallback? onToggleObscure;
  final bool readOnly;
  final VoidCallback? onTap;
  final Color? fillColor;

  static const double _radius = 32;

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    );

    final hintStyle = GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.neutral500,
    );

    final decoration = InputDecoration(
      isDense: true,
      filled: true,
      fillColor: fillColor ?? AppColors.buttonSecondary,
      hintText: hintText,
      labelText: labelText,
      hintStyle: hintStyle,
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      floatingLabelBehavior: labelText == null
          ? FloatingLabelBehavior.never
          : FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: AppColors.destructive, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: AppColors.destructive, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      prefixIcon: prefixIcon,
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      suffixIcon: _buildSuffix(),
      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    );

    if (validator != null) {
      return TextFormField(
        controller: controller,
        focusNode: focusNode,
        style: baseStyle,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        enabled: enabled,
        autofillHints: autofillHints,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        obscureText: obscureText,
        readOnly: readOnly,
        onTap: onTap,
        cursorColor: AppColors.primary600,
        decoration: decoration,
      );
    }

    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: baseStyle,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onFieldSubmitted,
      enabled: enabled,
      autofillHints: autofillHints,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      cursorColor: AppColors.primary600,
      decoration: decoration,
    );
  }

  Widget? _buildSuffix() {
    if (showObscureToggle) {
      return IconButton(
        onPressed: enabled ? onToggleObscure : null,
        splashRadius: 22,
        icon: Icon(
          obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.neutral600,
          size: 22,
        ),
      );
    }
    return suffix;
  }
}
