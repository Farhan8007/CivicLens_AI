import 'package:flutter/material.dart';

class ReportStatusChip extends StatelessWidget {
  final String status;

  const ReportStatusChip({super.key, required this.status});

  String get _normalizedStatus {
    return status.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  }

  String get _label {
    switch (_normalizedStatus) {
      case 'pending':
        return 'Pending';
      case 'in_review':
        return 'In Review';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected';
      default:
        if (status.trim().isEmpty) return 'Unknown';
        return _normalizedStatus
            .split('_')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
    }
  }

  Color _foregroundColor() {
    switch (_normalizedStatus) {
      case 'pending':
        return Colors.orange.shade800;
      case 'in_review':
        return Colors.purple.shade700;
      case 'in_progress':
        return Colors.blue.shade700;
      case 'resolved':
        return Colors.green.shade700;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final foregroundColor = _foregroundColor();

    return Chip(
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
