import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:country_flags/country_flags.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_button_styles.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/utils/alert_helper.dart';
import '../../../../features/upcoming_races/application/upcoming_races_notifier.dart';
import '../../providers/race_selection_providers.dart';
import '../../models/race_model.dart';
import '../../application/race_selection_state.dart';

/// BottomSheet для выбора гонки из списка доступных гонок.
///
/// Если [onRaceSelected] передан — при выборе гонки вызывает колбэк и закрывается
/// (режим "пик-режим", без создания апкаминг гонки).
/// Если [onRaceSelected] == null — стандартное поведение: создаёт апкаминг гонку.
class RaceSelectionBottomSheet extends ConsumerStatefulWidget {
  final ValueChanged<RaceModel>? onRaceSelected;
  /// Если true — показывать только гонки с датой в прошлом
  final bool onlyPast;

  const RaceSelectionBottomSheet({
    super.key,
    this.onRaceSelected,
    this.onlyPast = false,
  });

  @override
  ConsumerState<RaceSelectionBottomSheet> createState() =>
      _RaceSelectionBottomSheetState();
}

class _RaceSelectionBottomSheetState
    extends ConsumerState<RaceSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSaving = false;
  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    // Загружаем все гонки при открытии BottomSheet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(raceSelectionProvider.notifier).loadAllRaces();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Показать ошибку безопасно
  void _showErrorSafely(dynamic error) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ErrorHandler.showError(context, error);
    });
  }

  /// Обработка выбора гонки
  Future<void> _onRaceSelected(RaceModel race) async {
    // Пик-режим: колбэк сам закрывает боттомшит через Navigator.pop(race)
    if (widget.onRaceSelected != null) {
      widget.onRaceSelected!(race);
      return;
    }

    // Стандартный режим: создаём апкаминг гонку
    if (_isSaving) return;

    final confirmed = await _showConfirmationDialog(race);
    if (!confirmed) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(globalUpcomingRacesProvider.notifier).createUpcomingRaceFromId(
        raceId: race.id,
      );

      if (mounted) {
        await ref
            .read(globalUpcomingRacesProvider.notifier)
            .refreshUpcomingRaces();
        ref.invalidate(myRacesProvider);
        ref.invalidate(dashboardUpcomingRacesProvider);
        ref.invalidate(myDashboardUpcomingRacesProvider);
      }

      if (!mounted) return;

      final navigator = Navigator.of(context);
      final localizations = AppLocalizations.of(context)!;

      navigator.pop();

      AlertHelper.showSuccess(context, localizations.race_selection_success);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Диалог подтверждения выбора гонки
  Future<bool> _showConfirmationDialog(RaceModel race) async {
    final localizations = AppLocalizations.of(context)!;

    return await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      localizations.race_selection_confirm_title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22.sp,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 24.r,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${localizations.race_selection_confirm_description}:',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: CountryFlag.fromCountryCode(
                          race.countryIso,
                          height: 20.h,
                          width: 30.w,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          '${_shortRaceType(race.type)}, ${race.location}, ${race.formattedDate}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              // Confirm button
              SizedBox(
                width: double.infinity,
                child: AppButtonStyles.primaryGradientButton(
                  text: localizations.common_confirm,
                  onPressed: () => Navigator.of(context).pop(true),
                  borderRadius: 12.r,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  textStyle: TextStyle(
                    fontSize: 16.sp,
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
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(raceSelectionProvider);
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Слушаем ошибки
    ref.listen<RaceSelectionState>(raceSelectionProvider, (previous, next) {
      if (!mounted) return;
      if (next.hasError && next.error != null) {
        final error = next.error!;
        if ((previous?.error ?? '') != error && _lastShownError != error) {
          _lastShownError = error;
          _showErrorSafely(error);
        }
      }
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;

        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
            border: Border.all(color: theme.colorScheme.outline, width: 1),
          ),
          child: Column(
            children: [
              // Drag indicator
              Container(
                margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                height: 4.h,
                width: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.ironmanLightGray,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.race_selection_title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22.sp,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 24.r),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    ref.read(raceSelectionProvider.notifier).searchRaces(value);
                  },
                  decoration: InputDecoration(
                    hintText: localizations.race_selection_search_hint,
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      size: 24.r,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              size: 24.r,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(raceSelectionProvider.notifier).searchRaces('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
              ),

              // Race list
              Expanded(
                child: _buildRaceList(state, localizations, theme, scrollController, bottomPadding),
              ),

              // Save button - показывается только при выборе гонки
              if (state.isRaceSelected)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, bottomPadding + 20.h),
                    child: _buildSaveButton(state, localizations),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Построить список гонок
  Widget _buildRaceList(
    RaceSelectionState state,
    AppLocalizations localizations,
    ThemeData theme,
    ScrollController scrollController,
    double bottomPadding,
  ) {
    if (state.isLoading && !state.allRacesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && !state.allRacesLoaded) {
      return _buildErrorState(state.error!, localizations, theme);
    }

    if (state.canShowEmptyMessage) {
      return _buildEmptyState(localizations, theme);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final races = widget.onlyPast
        ? state.races.where((r) {
            try {
              return DateTime.parse(r.date).isBefore(today);
            } catch (_) {
              return false;
            }
          }).toList()
        : state.races;

    if (races.isEmpty) {
      return _buildEmptyState(localizations, theme);
    }

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        bottom: bottomPadding + 16.h + (state.isRaceSelected ? 100.h : 0.0),
      ),
      itemCount: races.length,
      separatorBuilder: (context, index) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final race = races[index];
        final isSelected = state.selectedRace?.id == race.id;

        return _buildRaceCard(race, isSelected, theme);
      },
    );
  }

  String _shortRaceType(String type) {
    final t = type.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    if (t.contains('703') || t.contains('70.3')) return 'IRONMAN 70.3';
    if (t.contains('5150')) return '5150';
    return 'IRONMAN';
  }

  /// Карточка гонки
  Widget _buildRaceCard(RaceModel race, bool isSelected, ThemeData theme) {
    return InkWell(
      onTap: () {
        ref.read(raceSelectionProvider.notifier).selectRace(race);
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color: isSelected ? AppColors.ironmanRed : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Race type title
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _shortRaceType(race.type),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                      color: AppColors.ironmanRed,
                      size: 24.r,
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              // Flag and location
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: CountryFlag.fromCountryCode(
                      race.countryIso,
                      height: 16.h,
                      width: 24.w,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      race.location,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              // Date
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar03,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 16.r,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    race.formattedDate,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Кнопка сохранения
  Widget _buildSaveButton(RaceSelectionState state, AppLocalizations localizations) {
    if (_isSaving) {
      return SizedBox(
        width: double.infinity,
        height: 56.h,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppButtonStyles.primaryGradient,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: SizedBox(
              height: 20.r,
              width: 20.r,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: AppButtonStyles.gradientElevatedButton(
        text: widget.onRaceSelected != null
            ? localizations.common_confirm
            : localizations.race_selection_save,
        onPressed: () => _onRaceSelected(state.selectedRace!),
        textStyle: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Состояние ошибки
  Widget _buildErrorState(String error, AppLocalizations localizations, ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              color: theme.colorScheme.error,
              size: 48.r,
            ),
            SizedBox(height: 16.h),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                ref.read(raceSelectionProvider.notifier).retrySearch();
              },
              child: Text(localizations.common_retry),
            ),
          ],
        ),
      ),
    );
  }

  /// Пустое состояние
  Widget _buildEmptyState(AppLocalizations localizations, ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              color: AppColors.ironmanTextSecondary,
              size: 48.r,
            ),
            SizedBox(height: 16.h),
            Text(
              localizations.race_selection_no_races,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.ironmanTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper функция для показа BottomSheet (стандартный режим — добавление апкаминг гонки)
void showRaceSelectionBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const RaceSelectionBottomSheet(),
  );
}

/// Helper функция для показа BottomSheet в пик-режиме — просто возвращает выбранную гонку.
/// [onlyPast] — если true, показывать только прошедшие гонки (для добавления результата).
Future<RaceModel?> showRacePickerBottomSheet(
  BuildContext context, {
  bool onlyPast = false,
}) {
  return showModalBottomSheet<RaceModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => RaceSelectionBottomSheet(
      onlyPast: onlyPast,
      onRaceSelected: (race) => Navigator.of(context).pop(race),
    ),
  );
}