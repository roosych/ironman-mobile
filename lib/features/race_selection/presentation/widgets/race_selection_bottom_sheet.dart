import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// BottomSheet для выбора гонки из списка доступных гонок
class RaceSelectionBottomSheet extends ConsumerStatefulWidget {
  const RaceSelectionBottomSheet({super.key});

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

  /// Обработка выбора гонки с подтверждением
  Future<void> _onRaceSelected(RaceModel race) async {
    if (_isSaving) return;

    // Показываем диалог подтверждения
    final confirmed = await _showConfirmationDialog(race);
    if (!confirmed) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Создаем UpcomingRace используя новый API формат
      await ref.read(globalUpcomingRacesProvider.notifier).createUpcomingRaceFromId(
        raceId: race.id,
      );

      // Обновляем список гонок после успешного создания
      if (mounted) {
        await ref
            .read(globalUpcomingRacesProvider.notifier)
            .refreshUpcomingRaces();
      }

      if (!mounted) return;

      // Сохраняем контекст перед использованием
      final navigator = Navigator.of(context);
      final localizations = AppLocalizations.of(context)!;

      navigator.pop();

      // Показываем сообщение об успехе
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
                      localizations.race_selection_confirm_title,
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
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${localizations.race_selection_confirm_description}:',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CountryFlag.fromCountryCode(
                          race.countryIso,
                          height: 20,
                          width: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${race.typeLabel.toUpperCase()}, ${race.location}, ${race.formattedDate}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Confirm button
              SizedBox(
                width: double.infinity,
                child: AppButtonStyles.primaryGradientButton(
                  text: localizations.common_confirm,
                  onPressed: () => Navigator.of(context).pop(true),
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(color: AppColors.ironmanGray, width: 1),
          ),
          child: Column(
            children: [
              // Drag indicator
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.ironmanLightGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.race_selection_title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    ref.read(raceSelectionProvider.notifier).searchRaces(value);
                  },
                  decoration: InputDecoration(
                    hintText: localizations.race_selection_search_hint,
                    prefixIcon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: Colors.white,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(raceSelectionProvider.notifier).searchRaces('');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
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
                    padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 20),
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

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        bottom: bottomPadding + 16.0 + (state.isRaceSelected ? 100.0 : 0.0), // Учитываем системные кнопки + место для кнопки "Сохранить"
      ),
      itemCount: state.races.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final race = state.races[index];
        final isSelected = state.selectedRace?.id == race.id;

        return _buildRaceCard(race, isSelected, theme);
      },
    );
  }

  /// Карточка гонки
  Widget _buildRaceCard(RaceModel race, bool isSelected, ThemeData theme) {
    return InkWell(
      onTap: () {
        ref.read(raceSelectionProvider.notifier).selectRace(race);
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppColors.ironmanRed : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Флаг страны с закругленными краями
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CountryFlag.fromCountryCode(
                  race.countryIso,
                  height: 20,
                  width: 30,
                ),
              ),
              const SizedBox(width: 12),

              // Информация о гонке
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${race.typeLabel.toUpperCase()}, ${race.location}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      race.formattedDate,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.ironmanTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Индикатор выбора
              if (isSelected)
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: AppColors.ironmanRed,
                  size: 24,
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
        height: 56,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppButtonStyles.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
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
        text: localizations.race_selection_save,
        onPressed: () => _onRaceSelected(state.selectedRace!),
        textStyle: const TextStyle(
          fontSize: 16,
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              color: theme.colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              color: AppColors.ironmanTextSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
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

/// Helper функция для показа BottomSheet
void showRaceSelectionBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const RaceSelectionBottomSheet(),
  );
}