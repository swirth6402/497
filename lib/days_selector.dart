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
  final List<String> dayLabels = const ['Sun','Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ToggleButtons(
        isSelected: widget.selectedDays,
        onPressed: (int index) {
          setState(() {
            widget.selectedDays[index] = !widget.selectedDays[index];
          });
          widget.onChanged(widget.selectedDays);
        },
        children: dayLabels
            .map((day) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(day),
                ))
            .toList(),
      ),
    );
  }

}
