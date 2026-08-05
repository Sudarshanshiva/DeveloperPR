import 'package:flutter/material.dart';
import '../../core/network/interceptors.dart';

class RateLimitBanner extends StatelessWidget {
  final RateLimitNotifier rateLimitNotifier;

  const RateLimitBanner({super.key, required this.rateLimitNotifier});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RateLimitInfo>(
      stream: rateLimitNotifier.stream,
      initialData: rateLimitNotifier.currentInfo,
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) return const SizedBox.shrink();

        if (info.isExceeded) {
          final resetTime = DateTime.fromMillisecondsSinceEpoch(info.resetTimestamp * 1000);
          final minutes = resetTime.difference(DateTime.now()).inMinutes;

          return Container(
            width: double.infinity,
            color: Colors.red.shade900,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'API Rate Limit Exceeded! Resets in ~$minutes min (${info.limit}/${info.limit} used)',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }

        if (info.isLow) {
          return Container(
            width: double.infinity,
            color: Colors.amber.shade800,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rate Limit Warning: ${info.remaining}/${info.limit} requests remaining.',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
