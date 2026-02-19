import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_button_styles.dart';
import '../../models/eligible_athlete_model.dart';
import '../../application/eligible_athletes_state.dart';
import '../../providers/transfer_providers.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../results/application/race_results_notifier.dart';

/// BottomSheet для выбора атлета-донора результатов
class AthleteSelectionBottomSheet extends ConsumerStatefulWidget {
  const AthleteSelectionBottomSheet({super.key});

  @override
  ConsumerState<AthleteSelectionBottomSheet> createState() =>
      _AthleteSelectionBottomSheetState();
}

class _AthleteSelectionBottomSheetState
    extends ConsumerState<AthleteSelectionBottomSheet> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Автоматически загружаем список всех доступных атлетов при открытии
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(eligibleAthletesProvider.notifier).loadAllAthletes();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Обработка клика по карточке атлета (только выбор)
  void _onAthleteSelected(EligibleAthleteModel athlete) {
    ref.read(eligibleAthletesProvider.notifier).selectAthlete(athlete);
  }

  /// Обработка сохранения выбранного атлета
  Future<void> _onSavePressed(EligibleAthleteModel athlete) async {
    if (_isSaving) return;

    final localizations = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);

    // Показываем dialog подтверждения
    final confirmed = await _showConfirmationDialog(athlete, localizations);
    if (!confirmed) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Запускаем создание заявки
      final success = await ref
          .read(transferStatusProvider.notifier)
          .createTransferRequest(athlete.id);

      if (!mounted) return;

      if (success) {
        // Сразу закрываем BottomSheet
        navigator.pop();

        // Показываем успешное уведомление
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.transfer_request_created),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Обновляем результаты пользователя
        _refreshUserResults();
      } else {
        // Показываем ошибку
        final error = ref.read(transferStatusProvider).error ??
            localizations.transfer_request_error;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }


  /// Показывает dialog подтверждения выбора атлета
  Future<bool> _showConfirmationDialog(
    EligibleAthleteModel athlete,
    AppLocalizations localizations,
  ) async {
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
                  // Заголовок с кнопкой закрытия
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          localizations.transfer_confirm_title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Описание действия
                  Text(
                    localizations.transfer_confirm_description(athlete.name.toUpperCase()),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Кнопки
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(localizations.common_cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(localizations.transfer_confirm_button),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  /// Обновляет результаты пользователя после успешной заявки
  void _refreshUserResults() {
    final user = ref.read(authProvider).user;
    final profileId = user?.profile?.id;

    if (profileId != null) {
      ref.read(raceResultsProvider.notifier).refreshResults(profileId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final athletesState = ref.watch(eligibleAthletesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(
              color: AppColors.ironmanGray,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Drag indicator
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.transfer_select_athlete,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: (value) {
                    ref.read(eligibleAthletesProvider.notifier)
                        .searchAthletes(value);
                  },
                  decoration: InputDecoration(
                    hintText: localizations.transfer_search_athletes,
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      size: 24,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              size: 24,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(eligibleAthletesProvider.notifier).searchAthletes('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
              ),

              const SizedBox(height: 16),

              // Athletes list
              Expanded(
                child: _buildAthletesList(
                  athletesState,
                  scrollController,
                  localizations,
                  theme,
                ),
              ),

              // Save button - показывается только при выборе атлета
              if (athletesState.isAthleteSelected)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
                    child: _buildSaveButton(athletesState, localizations),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Строит список атлетов
  Widget _buildAthletesList(
    EligibleAthletesState athletesState,
    ScrollController scrollController,
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    // Получаем высоту системных кнопок для нижнего отступа
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Состояние: загрузка (если еще не загружались все атлеты)
    if (athletesState.isLoading && !athletesState.allAthletesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    // Состояние: ошибка при первоначальной загрузке
    if (athletesState.hasError && !athletesState.allAthletesLoaded) {
      return _buildErrorState(athletesState.error!, localizations, theme);
    }

    // Состояние: ничего не найдено
    if (athletesState.canShowEmptyMessage) {
      return _buildEmptyState(
        localizations.transfer_no_athletes_found,
        HugeIcons.strokeRoundedUserRemove02,
        theme,
      );
    }

    // Список атлетов
    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        bottom: bottomPadding + 16.0 + (athletesState.isAthleteSelected ? 100.0 : 0.0), // Учитываем системные кнопки + место для кнопки "Сохранить"
      ),
      itemCount: athletesState.athletes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final athlete = athletesState.athletes[index];
        final isSelected = athletesState.selectedAthlete?.id == athlete.id;
        return _buildAthleteCard(athlete, isSelected, localizations, theme);
      },
    );
  }

  /// Строит состояние пустого экрана
  Widget _buildEmptyState(String message, IconData icon, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: icon,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Строит состояние ошибки
  Widget _buildErrorState(
    String error,
    AppLocalizations localizations,
    ThemeData theme,
  ) {
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
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                ref.read(eligibleAthletesProvider.notifier).retrySearch();
              },
              child: Text(localizations.common_retry),
            ),
          ],
        ),
      ),
    );
  }

  /// Строит карточку атлета
  Widget _buildAthleteCard(
    EligibleAthleteModel athlete,
    bool isSelected,
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: () => _onAthleteSelected(athlete),
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
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      athlete.name.toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.transfer_results_count(
                        athlete.totalRaces,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.ironmanTextSecondary,
                      ),
                    ),
                    if (athlete.lastRaceLocation != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        localizations.transfer_last_race(
                          athlete.lastRaceLocation!,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.ironmanTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
  Widget _buildSaveButton(EligibleAthletesState state, AppLocalizations localizations) {
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
        text: localizations.transfer_confirm_button,
        onPressed: () => _onSavePressed(state.selectedAthlete!),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

}