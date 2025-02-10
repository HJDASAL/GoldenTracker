import 'dart:developer';
import 'dart:math' show max, min;

import 'package:flutter/material.dart';
import 'package:golden_tracker_enterprise/widgets/index.dart';
import 'package:path/path.dart';
import '../styles/index.dart';
import 'package:intl/intl.dart';

class DateFormField extends StatelessWidget {
  DateFormField({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.selectedDate,
    this.onDateChanged,
    this.labelText,
    this.dropdown = true,
    DateTime? currentDate,
    TextEditingController? textController,
    DateFormat? dateFormatter,
  }) {
    this.currentDate = currentDate ?? DateTime.now();

    _dateFormatter = dateFormatter ?? DateFormat('MM/dd/yyyy');

    if (dropdown) {
      _focusNode.addListener(_onFocus);
    }

    _textController = textController ??
        TextEditingController(
          text: selectedDate != null
              ? _dateFormatter.format(selectedDate!)
              : null,
        );
  }

  final FocusNode _focusNode = FocusNode();
  late final MenuController _dropdownController = MenuController();
  late final TextEditingController _textController;
  late final DateFormat _dateFormatter;

  late final bool dropdown;
  final String? labelText;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? selectedDate;
  late final DateTime currentDate;

  final void Function(DateTime)? onDateChanged;
  final DateTime _now = DateTime.now();

  void _onDateChange(DateTime date) {
    log('New date: ${_dateFormatter.format(date)}');

    if (selectedDate != null) {
      log('Selected date: ${_dateFormatter.format(selectedDate!)}');
    }

    log('Current date: ${_dateFormatter.format(currentDate)}');

    _textController.text = _dateFormatter.format(date);
    onDateChanged?.call(date);

    if (date.day == selectedDate?.day &&
        date.month == selectedDate?.month &&
        date.year != selectedDate?.year) {
      return;
    }

    if (dropdown) {
      _dropdownController.close();
    }
  }

  void _onFocus() {
    if (_focusNode.hasFocus && !_dropdownController.isOpen) {
      _dropdownController.open();
      _focusNode.unfocus();
    }
  }

  void _toggleDropdownDatePicker() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
      _dropdownController.close();
    } else {
      _focusNode.requestFocus();
    }
  }

  void _togglePopupDatePicker(BuildContext context) async {
    DateTime? newDate = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: selectedDate,
    );

    if (newDate != null) {
      _onDateChange(newDate);
    }

    _focusNode.unfocus();
  }

  Widget _textFieldBuilder(
    BuildContext context, {
    bool datePickerDrops = true,
  }) {
    return TextFormField(
      readOnly: true,
      focusNode: _focusNode,
      controller: _textController,
      onTap: datePickerDrops
          ? _toggleDropdownDatePicker
          : () => _togglePopupDatePicker(context),
      decoration: kInputDecorationVariant.copyWith(
        isDense: true,
        labelText: _textController.text.isEmpty ? null : labelText,
        hintText: _textController.text.isEmpty ? labelText : null,
        suffixIcon: const Icon(Icons.today),
        focusedBorder: datePickerDrops
            ? kInputBorderVariant.copyWith(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  topLeft: Radius.circular(8),
                ),
              )
            : null,
        enabledBorder: _dropdownController.isOpen
            ? kInputBorderVariant.copyWith(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  topLeft: Radius.circular(8),
                ),
              )
            : null,
      ),
    );
  }

  Widget _responsiveBuild(BuildContext context, Layout layout) {
    return LayoutBuilder(
      builder: (context, constraints) => MenuAnchor(
        controller: _dropdownController,
        clipBehavior: Clip.none,
        alignmentOffset: const Offset(0, 0.5),
        menuChildren: [
          Container(
            color: kSurface,
            padding: const EdgeInsets.symmetric(vertical: 8),
            // height: 365,
            // constraints: BoxConstraints(minWidth: 240, maxWidth: 360),
            width: max(constraints.maxWidth, 120),
            child: CalendarDatePicker(
              initialDate: selectedDate ?? _now,
              firstDate: firstDate,
              lastDate: lastDate,
              onDateChanged: _onDateChange,
              currentDate: selectedDate,
            ),
          ),
        ],
        builder: (context, controller, child) => _textFieldBuilder(
          context,
          datePickerDrops: layout.deviceType.isDesktop,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _responsiveBuild(context, ResponsiveLayout.layoutOf(context));
  }
}
