// lib/core/utils/currency_formatter.dart
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, String currency) {
    final formatter = NumberFormat.currency(
      locale: _localeFor(currency),
      symbol: _symbolFor(currency),
      decimalDigits: currency == 'PYG' ? 0 : 2,
    );
    return formatter.format(amount);
  }

  static String _symbolFor(String currency) {
    const symbols = {
      'PYG': '₲',
      'USD': '\$',
      'EUR': '€',
      'BRL': 'R\$',
      'ARS': '\$',
    };
    return symbols[currency] ?? currency;
  }

  static String _localeFor(String currency) {
    const locales = {
      'PYG': 'es_PY',
      'USD': 'en_US',
      'EUR': 'de_DE',
      'BRL': 'pt_BR',
      'ARS': 'es_AR',
    };
    return locales[currency] ?? 'en_US';
  }
}
