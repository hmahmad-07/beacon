import 'package:flutter/services.dart';

class CNICFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldDigitsOnly = oldValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (oldDigitsOnly == digitsOnly && oldValue.text == newValue.text) {
      return newValue;
    }

    if (digitsOnly.length != newValue.text.replaceAll('-', '').length) {
      return oldValue;
    }
    if (digitsOnly.length > 13) {
      return oldValue;
    }
    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 5 || i == 12) {
        formatted += '-';
      }
      formatted += digitsOnly[i];
    }
    var cursorPosition = newValue.selection.baseOffset;
    final textBeforeCursor = newValue.text.substring(
      0,
      cursorPosition.clamp(0, newValue.text.length),
    );
    final digitsBeforeCursor = textBeforeCursor
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;

    int newCursorPos = digitsBeforeCursor;
    if (digitsBeforeCursor > 5) newCursorPos++;
    if (digitsBeforeCursor > 12) newCursorPos++;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }

    int selectionIndex = newValue.selection.baseOffset;
    if (selectionIndex > digitsOnly.length) {
      selectionIndex = digitsOnly.length;
    }

    return TextEditingValue(
      text: digitsOnly,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
