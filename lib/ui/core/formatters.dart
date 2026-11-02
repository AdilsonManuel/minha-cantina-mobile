import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_AO',
    symbol: 'Kz',
    decimalDigits: 2,
    customPattern: '#,##0.00 \u00A4',
  );

  static String formatKz(double value) {
    try {
      return _currencyFormat.format(value);
    } catch (_) {
      return '${value.toStringAsFixed(2)} Kz';
    }
  }

  static String formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final df = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    return df.format(local);
  }

  static String formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final df = DateFormat('HH:mm', 'pt_BR');
    return df.format(local);
  }

  static String formatRemainingTime(int seconds) {
    if (seconds <= 0) return 'Expirado';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
