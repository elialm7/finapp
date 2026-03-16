// lib/core/utils/date_utils.dart
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';

export 'package:flutter/material.dart' show DateTimeRange;

class AppDateUtils {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _monthFormat = DateFormat('MMMM yyyy', 'es');

  static String formatDate(DateTime dt) => _dateFormat.format(dt);
  static String formatDateTime(DateTime dt) => _dateTimeFormat.format(dt);
  static String formatMonth(DateTime dt) => _monthFormat.format(dt);

  static DateTimeRange currentMonth() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  static DateTimeRange currentYear() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, 1, 1),
      end: DateTime(now.year, 12, 31, 23, 59, 59),
    );
  }

  static DateTimeRange last30Days() {
    final now = DateTime.now();
    return DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
  }

  static String toIso(DateTime dt) => dt.toUtc().toIso8601String();
}
