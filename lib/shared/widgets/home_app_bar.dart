import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../features/auth/application/auth_notifier.dart';
import '../../features/notifications/application/notifications_notifier.dart';
import '../utils/image_url_helper.dart';

/// TopBar widget that displays user avatar (left), logo (center), notifications (right).
/// Avatar is read from AuthState.user.avatarUrl (Single Source of Truth)
class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotificationsTap;

  const HomeAppBar({
    super.key,
    this.onAvatarTap,
    this.onNotificationsTap,
  });

  static const double _appBarHeight = 72;

  @override
  Size get preferredSize => const Size.fromHeight(_appBarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final avatarUrl = authState.user?.avatarUrl;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final unreadCount = ref.watch(notificationsProvider.select((s) => s.unreadCount));
    // Для залогиненного пользователя не показываем стрелку «назад» — только аватар
    final showBackButton = canPop && !authState.isAuthenticated;

    return AppBar(
      toolbarHeight: _appBarHeight,
      leadingWidth: 72,
      leading: showBackButton
          ? IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: GestureDetector(
                onTap: onAvatarTap,
                child: Center(
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    backgroundImage:
                        (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(ImageUrlHelper.getFullImageUrl(avatarUrl)) : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? HugeIcon(
                            icon: HugeIcons.strokeRoundedUser,
                            size: 24,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          )
                        : null,
                  ),
                ),
              ),
            ),
      title: null,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: IconButton(
            onPressed: onNotificationsTap,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedNotification02,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).appBarTheme.backgroundColor ??
                              Theme.of(context).colorScheme.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
