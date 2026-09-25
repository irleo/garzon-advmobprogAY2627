import 'package:intl/intl.dart';

abstract final class CurrencyFormatter {
  static final NumberFormat _pesoFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '\u20B1',
    decimalDigits: 2,
  );

  static String peso(num amount) => _pesoFormat.format(amount);
}
