import 'package:flutter/material.dart';
import '../../domain/entities/review.dart';

class ReviewerTile extends StatelessWidget {
  final Review review;

  const ReviewerTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData icon;

    switch (review.state.toUpperCase()) {
      case 'APPROVED':
        badgeColor = Colors.green;
        icon = Icons.check_circle_rounded;
        break;
      case 'CHANGES_REQUESTED':
        badgeColor = Colors.red;
        icon = Icons.error_rounded;
        break;
      case 'COMMENTED':
        badgeColor = Colors.blue;
        icon = Icons.comment_rounded;
        break;
      default:
        badgeColor = Colors.amber;
        icon = Icons.hourglass_empty_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: review.userAvatar.isNotEmpty ? NetworkImage(review.userAvatar) : null,
          child: review.userAvatar.isEmpty ? Text(review.userLogin[0].toUpperCase()) : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                review.userLogin,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: badgeColor),
                  const SizedBox(width: 4),
                  Text(
                    review.state.replaceAll('_', ' '),
                    style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: review.body.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  review.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              )
            : null,
      ),
    );
  }
}
