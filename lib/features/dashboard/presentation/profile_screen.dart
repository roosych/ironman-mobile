import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import '../../../shared/utils/alert_helper.dart';
import '../../../shared/utils/image_url_helper.dart';
import '../../auth/application/auth_notifier.dart';
import '../../profile/application/profile_avatar_notifier.dart';
import '../../profile/presentation/photo_gallery_screen.dart';
import '../../profile/presentation/edit_profile_screen.dart';
import '../../profile/presentation/change_password_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../upcoming_races/presentation/my_races_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _cachedUserName;
  String? _cachedAvatarUrl;
  int? _cachedUserId;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final avatarState = ref.watch(profileAvatarProvider);
    final localizations = AppLocalizations.of(context)!;

    // Очищаем кэш, если сменился пользователь (новый user.id)
    if (user != null && user.id != _cachedUserId) {
      _cachedUserName = null;
      _cachedAvatarUrl = null;
      _cachedUserId = user.id;
    }

    // Сохраняем имя и аватар в кэш, если они есть и не идет logout
    // Всегда обновляем кэш при изменении avatarUrl, даже если он стал null
    if (user != null && !authState.isLoading) {
      _cachedUserName = user.name;
      // Обновляем кэш аватара при любом изменении (включая null)
      if (_cachedAvatarUrl != user.avatarUrl) {
        _cachedAvatarUrl = user.avatarUrl;
      }
      _cachedUserId = user.id;
    }

    // Используем кэшированные значения, если user стал null (во время logout)
    final displayName = _cachedUserName ?? user?.name ?? localizations.profile_user_fallback;
    final avatarUrl = _cachedAvatarUrl ?? user?.avatarUrl;


    // Listen for avatar upload errors
    ref.listen(profileAvatarProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        AlertHelper.showError(
          context,
          next.error!,
          buttonText: localizations.error_ok,
        );
        ref.read(profileAvatarProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Theme.of(context).colorScheme.onSurface,
            size: 24,
          ),
          onPressed: authState.isLoading
              ? null
              : () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          localizations.profile_title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Profile Header Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: (avatarState.isLoading || authState.isLoading)
                          ? null
                          : () {
                              ref
                                  .read(profileAvatarProvider.notifier)
                                  .pickAndUploadAvatar();
                            },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(ImageUrlHelper.getFullImageUrl(avatarUrl))
                                : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? HugeIcon(
                                    icon: HugeIcons.strokeRoundedUser,
                                    size: 50,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                              child: const HugeIcon(
                                icon: HugeIcons.strokeRoundedCamera01,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        displayName.toUpperCase(),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Menu Sections
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide.none,
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: HugeIcon(
                        icon: HugeIcons.strokeRoundedUser,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      title: Text(localizations.profile_information),
                      trailing: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      onTap: authState.isLoading
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              ),
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    ListTile(
                      leading: HugeIcon(
                        icon: HugeIcons.strokeRoundedImage01,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      title: Text(localizations.profile_photo_gallery),
                      trailing: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      onTap: authState.isLoading
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PhotoGalleryScreen(),
                                ),
                              ),
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    ListTile(
                      leading: HugeIcon(
                        icon: HugeIcons.strokeRoundedCalendar03,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      title: Text(localizations.my_races_title),
                      trailing: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      onTap: authState.isLoading
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const MyRacesScreen(),
                                ),
                              ),
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    ListTile(
                      leading: HugeIcon(
                        icon: HugeIcons.strokeRoundedSettings01,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      title: Text(localizations.settings_title),
                      trailing: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      onTap: authState.isLoading
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              ),
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    ListTile(
                      leading: HugeIcon(
                        icon: HugeIcons.strokeRoundedLockPassword,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      title: Text(localizations.profile_security),
                      trailing: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      onTap: authState.isLoading
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ChangePasswordScreen(),
                                ),
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Logout Button
              OutlinedButton(
                onPressed: authState.isLoading
                    ? null
                    : () {
                        ref.read(authProvider.notifier).logout();
                      },
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        localizations.logout_button,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ],
          ),
          if (avatarState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          if (authState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
