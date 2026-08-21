import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Formatter utilities for Gaming Lounge
class AppFormatters {
  static final NumberFormat _currencyFormatter = NumberFormat('#,##0', 'en_US');

  /// Formats currency with IQD suffix, e.g. "3,000 د.ع"
  static String formatCurrency(double amount) {
    final rounded = amount.round();
    return '${_currencyFormatter.format(rounded)} ${AppConstants.currencyIQD}';
  }

  /// Formats exact duration into HH:MM:SS (e.g. "01:24:05")
  static String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Formats duration into human readable Arabic (e.g. "ساعة و 15 دقيقة")
  static String formatDurationArabic(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours == 0 && minutes == 0) {
      return 'أقل من دقيقة';
    }

    final parts = <String>[];
    if (hours > 0) {
      if (hours == 1) {
        parts.add('ساعة');
      } else if (hours == 2) {
        parts.add('ساعتان');
      } else if (hours >= 3 && hours <= 10) {
        parts.add('$hours ساعات');
      } else {
        parts.add('$hours ساعة');
      }
    }

    if (minutes > 0) {
      if (minutes == 1) {
        parts.add('دقيقة واحدة');
      } else if (minutes == 2) {
        parts.add('دقيقتان');
      } else if (minutes >= 3 && minutes <= 10) {
        parts.add('$minutes دقائق');
      } else {
        parts.add('$minutes دقيقة');
      }
    }

    return parts.join(' و ');
  }

  /// Formats date and time in Arabic format
  static String formatDateTime(DateTime dateTime) {
    try {
      final formatter = DateFormat('yyyy/MM/dd - hh:mm a', 'ar');
      return formatter.format(dateTime);
    } catch (_) {
      final h = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final m = dateTime.minute.toString().padLeft(2, '0');
      final ampm = dateTime.hour >= 12 ? 'م' : 'ص';
      return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} - $h:$m $ampm';
    }
  }

  /// Formats time only in Arabic format (e.g. "08:30 م")
  static String formatTimeOnly(DateTime dateTime) {
    try {
      final formatter = DateFormat('hh:mm a', 'ar');
      return formatter.format(dateTime);
    } catch (_) {
      final h = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final m = dateTime.minute.toString().padLeft(2, '0');
      final ampm = dateTime.hour >= 12 ? 'م' : 'ص';
      return '$h:$m $ampm';
    }
  }

  /// Formats date only (e.g. "2026/08/20")
  static String formatDateOnly(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
  }
}
