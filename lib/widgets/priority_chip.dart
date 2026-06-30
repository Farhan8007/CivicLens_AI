import 'package:flutter/material.dart';

class PriorityChip extends StatelessWidget {
  final String priority;

  const PriorityChip({super.key, required this.priority});

  Color _foregroundColor() {
    switch (priority.trim().toLowerCase()) {
      case 'high':
        return Colors.red.shade700;
      case 'medium':
        return Colors.orange.shade800;
      case 'low':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String get _label {
    final trimmed = priority.trim();
    if (trimmed.isEmpty) return 'Unknown';
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final foregroundColor = _foregroundColor();

    return Chip(
      avatar: Icon(
        Icons.auto_awesome,
        size: 14,
        color: foregroundColor,
      ),
      label: Text(_label),
      labelStyle: TextStyle(
        color: foregroundColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: foregroundColor.withValues(alpha: 0.1),
      side: BorderSide(color: foregroundColor.withValues(alpha: 0.45)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
