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
    try {
      final df = DateFormat('dd/MM/yyyy HH:mm');
      return df.format(local);
    } catch (_) {
      final d = local.day.toString().padLeft(2, '0');
      final m = local.month.toString().padLeft(2, '0');
      final y = local.year;
      final h = local.hour.toString().padLeft(2, '0');
      final min = local.minute.toString().padLeft(2, '0');
      return '$d/$m/$y $h:$min';
    }
  }

  static String formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    try {
      final df = DateFormat('HH:mm');
      return df.format(local);
    } catch (_) {
      final h = local.hour.toString().padLeft(2, '0');
      final min = local.minute.toString().padLeft(2, '0');
      return '$h:$min';
    }
  }

  static String formatRemainingTime(int seconds) {
    if (seconds <= 0) return 'Expirado';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
