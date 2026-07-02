import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// A themed text field pre-configured for RTL Arabic input.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.isPassword = false,
    this.validator,
    this.onFieldSubmitted,
    this.autofillHints,
    this.focusNode,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool isPassword;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: widget.isPassword && _obscureText,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      autofillHints: widget.autofillHints,
      style: GoogleFonts.tajawal(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.charcoal,
      ),
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20)
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.grey500,
                ),
                onPressed: () {
                  setState(() => _obscureText = !_obscureText);
                },
              )
            : null,
      ),
    );
  }
}
