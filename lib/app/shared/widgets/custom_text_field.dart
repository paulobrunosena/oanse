import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:validatorless/validatorless.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? textInputType;
  final Function(String)? onChanged;
  final Function(String?)? onSaved;
  final bool? enabled;
  final bool isCpf;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const CustomTextField({
    Key? key,
    this.hint,
    this.prefix,
    this.suffix,
    this.obscure = false,
    this.textInputType,
    this.onChanged,
    this.onSaved,
    this.enabled,
    this.controller,
    this.isCpf = false,
    this.textInputAction,
    this.onFieldSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String? Function(String?)> validadores = [];
    final List<TextInputFormatter> inputFormatters = [];
    validadores.add(Validatorless.required('* Campo obrigatório'));
    if (isCpf) {
      validadores.add(Validatorless.cpf('* CPF inválido'));
      inputFormatters.add(FilteringTextInputFormatter.digitsOnly);
      inputFormatters.add(CpfInputFormatter());
    }
    return TextFormField(
      validator: Validatorless.multiple(validadores),
      controller: controller,
      obscureText: obscure,
      keyboardType: textInputType,
      onChanged: onChanged,
      onSaved: onSaved,
      enabled: enabled,
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        labelText: hint,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: prefix,
        suffixIcon: suffix,
      ),
      textAlignVertical: TextAlignVertical.center,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
