// ─────────────────────────────────────────────────────────────────────────────
// history_tile.dart — List tile for scan history
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/scan_result.dart';

class HistoryTile extends StatelessWidget {
  final ScanResult scan;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const HistoryTile({
    super.key,
    required this.scan,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('MMM d, h:mm a').format(scan.timestamp);

    return Semantics(
      label: '${scan.objectName}. Scanned $formattedTime. Double tap to hear description.',
      button: true,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                _buildThumbnail(),
                const SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              scan.objectName,
                              style: const TextStyle(
                                fontSize: kFontSizeBody,
                                fontWeight: FontWeight.w700,
                                color: kColorTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (scan.isOffline)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: kColorAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: kColorAccent.withOpacity(0.5),
                                ),
                              ),
                              child: const Text(
                                'OFFLINE',
                                style: TextStyle(
                                  color: kColorAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        scan.shortDescription,
                        style: const TextStyle(
                          fontSize: kFontSizeCaption,
                          color: kColorTextSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: kColorTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 13,
                              color: kColorTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: kColorPrimary),
                      tooltip: 'Read aloud',
                      onPressed: onTap,
                    ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: kColorError, size: 22),
                        tooltip: 'Delete scan',
                        onPressed: onDelete,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    const size = 72.0;
    const radius = BorderRadius.all(Radius.circular(12));

    if (scan.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: scan.imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholderBox(size),
          errorWidget: (_, __, ___) => _placeholderBox(size),
        ),
      );
    }

    return _placeholderBox(size);
  }

  Widget _placeholderBox(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kColorCard,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: kColorDivider),
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: kColorTextSecondary,
        size: 28,
      ),
    );
  }
}
