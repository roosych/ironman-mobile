import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/core/theme/app_button_styles.dart';
import '../../../shared/utils/alert_helper.dart';
import '../../../shared/utils/image_url_helper.dart';
import '../application/user_photos_notifier.dart';
import '../application/user_photos_state.dart';
import '../domain/user_photo.dart';
import 'photo_viewer_screen.dart';

class PhotoGalleryScreen extends ConsumerStatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  ConsumerState<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends ConsumerState<PhotoGalleryScreen> {
  @override
  void initState() {
    super.initState();
    // Load photos on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userPhotosProvider.notifier).loadPhotos();
    });
  }

  Future<void> _onDeletePhoto(UserPhoto photo) async {
    final localizations = AppLocalizations.of(context)!;
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      localizations.photo_delete_title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 24,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Confirm button
              SizedBox(
                width: double.infinity,
                child: AppButtonStyles.primaryGradientButton(
                  text: localizations.photo_delete_button,
                  onPressed: () => Navigator.of(context).pop(true),
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(userPhotosProvider.notifier).deletePhoto(photo.id);
      if (success && mounted) {
        AlertHelper.showSuccess(context, localizations.photo_deleted);
      }
    }
  }

  Future<void> _onAddPhoto() async {
    final localizations = AppLocalizations.of(context)!;
    final success = await ref.read(userPhotosProvider.notifier).uploadPhoto();
    if (success && mounted) {
      AlertHelper.showSuccess(context, localizations.photo_uploaded);
    }
  }

  void _onViewPhoto(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(initialIndex: index),
      ),
    );
  }

  Future<void> _onSetAsAvatar(UserPhoto photo) async {
    final localizations = AppLocalizations.of(context)!;
    // Don't allow setting if already avatar
    if (photo.isAvatar) {
      AlertHelper.showInfo(context, localizations.photo_already_avatar);
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      localizations.photo_set_avatar_title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 24,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Confirm button
              SizedBox(
                width: double.infinity,
                child: AppButtonStyles.primaryGradientButton(
                  text: localizations.photo_set_button,
                  onPressed: () => Navigator.of(context).pop(true),
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(userPhotosProvider.notifier).setAvatar(photo.id);
      if (success && mounted) {
        AlertHelper.showSuccess(context, localizations.photo_avatar_updated);
      }
    }
  }

  String _localizeError(String error, AppLocalizations? loc) {
    if (loc == null) return error;
    switch (error) {
      case 'photo_avatar_set_error':
        return loc.photo_avatar_set_error;
      default:
        return error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final photosState = ref.watch(userPhotosProvider);
    final localizations = AppLocalizations.of(context)!;

    // Listen for errors
    ref.listen(userPhotosProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        final loc = AppLocalizations.of(context);
        final errorMessage = _localizeError(next.error!, loc);
        AlertHelper.showError(
          context,
          errorMessage,
          buttonText: loc?.error_ok,
        );
        ref.read(userPhotosProvider.notifier).clearError();
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
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          localizations.profile_photo_gallery,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Show subtle refresh indicator when refreshing
          if (photosState.isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(photosState),
    );
  }

  Widget _buildBody(UserPhotosState state) {
    // Show loading state with just the Add Photo button
    if (state.isFullLoading) {
      return RefreshIndicator(
        onRefresh: () => ref.read(userPhotosProvider.notifier).refreshPhotos(),
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: 1, // Only the "Add Photo" button
          itemBuilder: (context, index) {
            return _AddPhotoCard(
              onTap: _onAddPhoto,
              isLoading: true,
            );
          },
        ),
      );
    }

    // Show empty state if no photos and not loading
    // But still show the grid with "Add Photo" button
    if (state.photos.isEmpty && !state.isLoading) {
      return RefreshIndicator(
        onRefresh: () => ref.read(userPhotosProvider.notifier).refreshPhotos(),
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: 1, // Only the "Add Photo" card
          itemBuilder: (context, index) {
            return _AddPhotoCard(
              onTap: _onAddPhoto,
              isLoading: state.isLoading,
            );
          },
        ),
      );
    }

    // +1 for the "Add Photo" card
    final itemCount = state.photos.length + 1;

    return RefreshIndicator(
      onRefresh: () => ref.read(userPhotosProvider.notifier).refreshPhotos(),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // First item is the "Add Photo" card
          if (index == 0) {
            return _AddPhotoCard(
              onTap: _onAddPhoto,
              isLoading: state.isLoading || state.isRefreshing,
            );
          }

          // Remaining items are photos (index - 1 because of the add card)
          final photoIndex = index - 1;
          final photo = state.photos[photoIndex];
          return _PhotoCard(
            photo: photo,
            onTap: () => _onViewPhoto(photoIndex),
            onDelete: () => _onDeletePhoto(photo),
            onSetAvatar: () => _onSetAsAvatar(photo),
          );
        },
      ),
    );
  }
}

class _AddPhotoCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const _AddPhotoCard({
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedImageAdd02,
                  size: 32,
                  color: AppColors.ironmanWhite,
                ),
              ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final UserPhoto photo;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onSetAvatar;

  const _PhotoCard({
    required this.photo,
    required this.onTap,
    required this.onDelete,
    required this.onSetAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo image with caching
          CachedNetworkImage(
            imageUrl: ImageUrlHelper.getFullImageUrl(photo.url),
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedImageNotFound01,
                color: Theme.of(context).colorScheme.outline,
                size: 24,
              ),
            ),
          ),

          // Avatar badge
          if (photo.isAvatar)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedStar,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      AppLocalizations.of(context)!.photo_avatar,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),

          // Action buttons overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Delete button
                  _ActionButton(
                    icon: HugeIcons.strokeRoundedDelete02,
                    onTap: onDelete,
                    tooltip: AppLocalizations.of(context)!.photo_delete,
                  ),
                  // Set as avatar button
                  _ActionButton(
                    icon: HugeIcons.strokeRoundedUser,
                    onTap: onSetAvatar,
                    tooltip: AppLocalizations.of(context)!.photo_set_as_avatar,
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: HugeIcon(
              icon: icon,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
