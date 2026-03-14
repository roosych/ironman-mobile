import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/shared/utils/image_url_helper.dart';

class UserAvatarWidget extends StatelessWidget {
  final String? url;
  final double radius;

  const UserAvatarWidget({
    super.key,
    required this.radius,
    this.url,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;

    if (!hasUrl) {
      return _placeholder(context);
    }

    final imageUrl = ImageUrlHelper.getFullImageUrl(url);
    return ClipOval(
      child: CachedNetworkImage(
        key: ValueKey(imageUrl),
        imageUrl: imageUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (context, url) => _placeholder(context),
        errorWidget: (context, url, error) => _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedUser,
        size: radius,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}
