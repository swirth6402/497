import 'package:flutter/material.dart';

class DaysSelector extends StatefulWidget {
  final List<bool> selectedDays;
  final void Function(List<bool>) onChanged;

  const DaysSelector({
    Key? key,
    required this.selectedDays,
    required this.onChanged,
  }) : super(key: key);

  @override
  _DaysSelectorState createState() => _DaysSelectorState();
}

class _DaysSelectorState extends State<DaysSelector> {
  // Day labels for Monday to Sunday
  final List<String> dayLabels = const ['S','M', 'T', 'W', 'TH', 'F', 'S'];

  @override
Widget build(BuildContext context) {
  return Center(
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(dayLabels.length, (index) {
        final selected = widget.selectedDays[index];
        return OutlinedButton(
          onPressed: () {
            final newDays = List<bool>.from(widget.selectedDays);
            newDays[index] = !newDays[index];
            widget.onChanged(newDays);
          },
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: selected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                : Colors.transparent,
            side: BorderSide(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade400,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          child: Text(
            dayLabels[index],
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black87,
            ),
          ),
        );
      }),
    ),
  );
}


}
