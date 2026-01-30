import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import '../../../shared/utils/alert_helper.dart';
import '../application/user_photos_notifier.dart';
import '../domain/user_photo.dart';

class PhotoViewerScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.initialIndex,
  });

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _onDelete(UserPhoto photo) async {
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.photo_delete_title),
        content: photo.isAvatar
            ? Text(localizations.photo_delete_avatar_warning)
            : Text(localizations.photo_delete_irreversible),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.common_cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.photo_delete_button),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(userPhotosProvider.notifier).deletePhoto(photo.id);
      if (success && mounted) {
        final photos = ref.read(userPhotosProvider).photos;

        // If no photos left, close the viewer
        if (photos.isEmpty) {
          Navigator.of(context).pop();
          return;
        }

        // Adjust current index if needed
        if (_currentIndex >= photos.length) {
          setState(() {
            _currentIndex = photos.length - 1;
          });
          _pageController.jumpToPage(_currentIndex);
        }

        AlertHelper.showSuccess(context, localizations.photo_deleted);
      }
    }
  }

  Future<void> _onSetAvatar(UserPhoto photo) async {
    final localizations = AppLocalizations.of(context)!;
    if (photo.isAvatar) {
      AlertHelper.showInfo(context, localizations.photo_already_avatar);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.photo_set_avatar_title),
        content: Text(localizations.photo_set_avatar_description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.photo_set_button),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(userPhotosProvider.notifier).setAvatar(photo.id);
      if (success && mounted) {
        AlertHelper.showSuccess(context, localizations.photo_avatar_updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photosState = ref.watch(userPhotosProvider);
    final photos = photosState.photos;

    // Handle empty photos (e.g., all deleted)
    if (photos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Ensure current index is valid
    final safeIndex = _currentIndex.clamp(0, photos.length - 1);
    final currentPhoto = photos[safeIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return _PhotoPage(photo: photo);
            },
          ),

          // Top bar with close button and counter
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    // Avatar badge
                    if (currentPhoto.isAvatar)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedStar,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.photo_avatar,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        '${safeIndex + 1} / ${photos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // Bottom action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Delete button
                    _ActionButton(
                      icon: HugeIcons.strokeRoundedDelete02,
                      label: AppLocalizations.of(context)!.photo_delete,
                      onTap: photosState.isLoading
                          ? null
                          : () => _onDelete(currentPhoto),
                    ),
                    // Set as avatar button
                    _ActionButton(
                      icon: currentPhoto.isAvatar
                          ? HugeIcons.strokeRoundedStar
                          : HugeIcons.strokeRoundedUser,
                      label: currentPhoto.isAvatar 
                          ? AppLocalizations.of(context)!.photo_avatar 
                          : AppLocalizations.of(context)!.photo_set_as_avatar,
                      onTap: photosState.isLoading || currentPhoto.isAvatar
                          ? null
                          : () => _onSetAvatar(currentPhoto),
                      isActive: currentPhoto.isAvatar,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (photosState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : isDisabled
            ? Colors.white38
            : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPage extends StatefulWidget {
  final UserPhoto photo;

  const _PhotoPage({required this.photo});

  @override
  State<_PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<_PhotoPage> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _resetZoom,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 4.0,
        child: Center(
          child: Image.network(
            widget.photo.url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedImageNotFound01,
                  color: Colors.white54,
                  size: 64,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
