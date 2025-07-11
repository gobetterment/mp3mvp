import 'package:flutter/material.dart';

class BpmFilterBar extends StatelessWidget {
  final double min;
  final double max;
  final int divisions;
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;
  final String labelPrefix;

  const BpmFilterBar({
    super.key,
    required this.min,
    required this.max,
    required this.divisions,
    required this.values,
    required this.onChanged,
    this.labelPrefix = 'BPM',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(labelPrefix),
          Expanded(
            child: RangeSlider(
              min: min,
              max: max,
              divisions: divisions,
              values: values,
              onChanged: onChanged,
              labels: RangeLabels(
                values.start.round().toString(),
                values.end.round().toString(),
              ),
            ),
          ),
          Text('${values.start.round()} - ${values.end.round()}'),
        ],
      ),
    );
  }
}
