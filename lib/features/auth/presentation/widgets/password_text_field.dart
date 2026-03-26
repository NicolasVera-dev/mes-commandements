import 'package:flutter/material.dart';

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final bool enabled;
  final TextInputAction textInputAction;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final int minLines;
  final int maxLines;
  final bool autoFocus;

  const PasswordTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.errorText,
    this.onChanged,
    this.minLines = 1,
    this.maxLines = 1,
    this.autoFocus = false,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final icon = _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded;

    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscure,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      autofocus: widget.autoFocus,
      textInputAction: widget.textInputAction,
      keyboardType: TextInputType.visiblePassword,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Afficher' : 'Masquer',
          icon: Icon(icon),
          onPressed: widget.enabled
              ? () => setState(() => _obscure = !_obscure)
              : null,
        ),
      ),
    );
  }
}

