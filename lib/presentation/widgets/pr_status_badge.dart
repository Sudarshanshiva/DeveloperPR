import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PRStatusBadge extends StatelessWidget {
  final String state;
  final bool isDraft;

  const PRStatusBadge({
    super.key,
    required this.state,
    this.isDraft = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDraft) {
      return _buildBadge(
        label: 'Draft',
        color: AppTheme.draftGrey,
        icon: Icons.edit_note_rounded,
      );
    }

    switch (state.toLowerCase()) {
      case 'open':
        return _buildBadge(
          label: 'Open',
          color: AppTheme.openGreen,
          icon: Icons.call_merge_rounded,
        );
      case 'closed':
      case 'merged':
        return _buildBadge(
          label: state.toLowerCase() == 'merged' ? 'Merged' : 'Closed',
          color: AppTheme.closedPurple,
          icon: Icons.done_all_rounded,
        );
      default:
        return _buildBadge(
          label: state,
          color: AppTheme.draftGrey,
          icon: Icons.info_outline,
        );
    }
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class CIBadge extends StatelessWidget {
  final String? ciState;

  const CIBadge({super.key, this.ciState});

  @override
  Widget build(BuildContext context) {
    if (ciState == null || ciState == 'unknown') return const SizedBox.shrink();

    Color color;
    IconData icon;
    String label;

    switch (ciState!.toLowerCase()) {
      case 'success':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        label = 'CI Passed';
        break;
      case 'failure':
      case 'error':
        color = Colors.red;
        icon = Icons.error_outline;
        label = 'CI Failed';
        break;
      case 'pending':
        color = Colors.amber;
        icon = Icons.hourglass_top;
        label = 'CI Pending';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
