// lib/shared/widgets/date_range_picker_button.dart
import 'package:flutter/material.dart';
import '../../core/utils/date_utils.dart';
import '../../core/theme/app_theme.dart';

class DateRangePickerButton extends StatelessWidget {
  final DateTimeRange range;
  final ValueChanged<DateTimeRange> onChanged;

  const DateRangePickerButton({
    super.key,
    required this.range,
    required this.onChanged,
  });

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _pick(BuildContext context) async {
    final result = await showModalBottomSheet<DateTimeRange>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _DateRangeSheet(
        current: range,
        onCustomPick: () async {
          Navigator.pop(sheetContext);

          final now = DateTime.now();
          final firstDate = DateTime(2000, 1, 1);
          final lastDate = _dateOnly(now.add(const Duration(days: 1)));

          final initialRange = DateTimeRange(
            start: _dateOnly(range.start),
            end: _dateOnly(range.end).isAfter(lastDate)
                ? lastDate
                : _dateOnly(range.end),
          );

          final picked = await showDateRangePicker(
            context: context,
            firstDate: firstDate,
            lastDate: lastDate,
            initialDateRange: initialRange,
          );

          if (picked != null) {
            onChanged(picked);
          }
        },
      ),
    );

    if (result != null) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
      onPressed: () => _pick(context),
      icon: const Icon(Icons.calendar_month_outlined, size: 18),
      label: Text(
        '${AppDateUtils.formatDate(range.start)} – ${AppDateUtils.formatDate(range.end)}',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _DateRangeSheet extends StatelessWidget {
  final DateTimeRange current;
  final VoidCallback onCustomPick;

  const _DateRangeSheet({required this.current, required this.onCustomPick});

  @override
  Widget build(BuildContext context) {
    final presets = [
      _Preset('Este mes', AppDateUtils.currentMonth()),
      _Preset('Últimos 30 días', AppDateUtils.last30Days()),
      _Preset('Este año', AppDateUtils.currentYear()),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleccionar período',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...presets.map((p) => ListTile(
            title: Text(p.label),
            trailing: const Icon(Icons.chevron_right),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () => Navigator.pop(context, p.range),
          )),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.date_range_outlined, color: AppTheme.primary),
            title: const Text('Rango personalizado'),
            trailing: const Icon(Icons.chevron_right),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: onCustomPick,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Preset {
  final String label;
  final DateTimeRange range;
  const _Preset(this.label, this.range);
}
