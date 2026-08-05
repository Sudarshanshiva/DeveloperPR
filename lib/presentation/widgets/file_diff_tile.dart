import 'package:flutter/material.dart';
import '../../domain/entities/file_change.dart';

class FileDiffTile extends StatelessWidget {
  final FileChange file;

  const FileDiffTile({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          file.filename,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Row(
          children: [
            _buildStatusChip(file.status),
            const SizedBox(width: 8),
            Text(
              '+${file.additions}',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(width: 6),
            Text(
              '-${file.deletions}',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        children: [
          if (file.patch != null && file.patch!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0F172A)
                  : Colors.grey.shade100,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  file.patch!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Binary file or no patch detail available.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'added':
        color = Colors.green;
        break;
      case 'removed':
        color = Colors.red;
        break;
      case 'renamed':
        color = Colors.amber;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
