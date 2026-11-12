import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Gender dropdown mapped directly to backend DTO values (`male`, `female`, `other`).
class GenderDropdownField extends StatelessWidget {
  const GenderDropdownField({
    required this.value,
    required this.onChanged,
    this.labelText = 'Giới tính',
    this.validator,
    super.key,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String labelText;
  final FormFieldValidator<String>? validator;

  static const _options = <(String, String)>[
    ('male', 'Nam'),
    ('female', 'Nữ'),
    ('other', 'Khác'),
  ];

  @override
  Widget build(BuildContext context) {
    final normalized = _options.any((opt) => opt.$1 == value) ? value : null;
    return DropdownButtonFormField<String>(
      initialValue: normalized,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.wc_outlined),
      ),
      items: [
        for (final (code, text) in _options)
          DropdownMenuItem<String>(value: code, child: Text(text)),
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }
}

/// Date input supporting both manual `YYYY-MM-DD` entry and a calendar picker button.
class DatePickerFormField extends StatelessWidget {
  const DatePickerFormField({
    required this.controller,
    required this.labelText,
    this.validator,
    this.onPicked,
    this.firstDate,
    this.lastDate,
    super.key,
  });

  final TextEditingController controller;
  final String labelText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<DateTime>? onPicked;
  final DateTime? firstDate;
  final DateTime? lastDate;

  Future<void> _openPicker(BuildContext context) async {
    final now = DateTime.now();
    final initial =
        DateTime.tryParse(controller.text.trim()) ??
        DateTime(now.year - 25, now.month, now.day);
    final first = firstDate ?? DateTime(1900);
    final last = lastDate ?? now;
    final clamped = initial.isBefore(first)
        ? first
        : initial.isAfter(last)
        ? last
        : initial;

    final picked = await showDatePicker(
      context: context,
      initialDate: clamped,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      controller.text = formatDateApi(picked);
      onPicked?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.datetime,
    decoration: InputDecoration(
      labelText: labelText,
      hintText: 'YYYY-MM-DD',
      prefixIcon: const Icon(Icons.cake_outlined),
      suffixIcon: IconButton(
        tooltip: 'Chọn ngày',
        icon: const Icon(Icons.calendar_today_outlined),
        onPressed: () => _openPicker(context),
      ),
    ),
    validator: validator,
  );
}

