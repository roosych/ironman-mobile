import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        // Закрываем BottomSheet и показываем диалог успеха
        navigator.pop();
        if (mounted) {
          await _showResultDialog(
            isSuccess: true,
            localizations: localizations,
          );
        }
        // Обновляем результаты пользователя
        _refreshUserResults();
      } else {
        // Показываем диалог ошибки (BottomSheet остаётся открытым)
        final error = ref.read(transferStatusProvider).error ??
            localizations.transfer_request_error;
        await _showResultDialog(
          isSuccess: false,
          localizations: localizations,
          errorMessage: error,
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
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.r),
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
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24.r,
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Описание действия
                  Text(
                    localizations.transfer_confirm_description(athlete.name.toUpperCase()),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 24.h),

                  // Кнопки
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(localizations.common_cancel),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
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

  /// Показывает диалог результата (успех или ошибка)
  Future<void> _showResultDialog({
    required bool isSuccess,
    required AppLocalizations localizations,
    String? errorMessage,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
              size: 56.r,
            ),
            SizedBox(height: 16.h),
            Text(
              isSuccess
                  ? localizations.transfer_request_created
                  : (errorMessage ?? localizations.transfer_request_error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isSuccess ? Colors.green.shade600 : Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
            ),
            child: Text(localizations.common_ok),
          ),
        ],
      ),
    );
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
                margin: EdgeInsets.only(top: 8.h),
                width: 32.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.all(20.r),
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
                        size: 24.r,
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
                padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                              ref.read(eligibleAthletesProvider.notifier).searchAthletes('');
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

              SizedBox(height: 16.h),

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
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, MediaQuery.of(context).padding.bottom + 20.h),
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
        left: 20.w,
        right: 20.w,
        bottom: bottomPadding + 16.h + (athletesState.isAthleteSelected ? 100.h : 0.0),
      ),
      itemCount: athletesState.athletes.length,
      separatorBuilder: (context, index) => SizedBox(height: 8.h),
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
            size: 48.r,
          ),
          SizedBox(height: 16.h),
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

  String _localizeError(String key, AppLocalizations loc) {
    // Обработка api_error_server:STATUS (закодированный статус-код)
    if (key.startsWith('api_error_server:')) {
      final status = key.substring('api_error_server:'.length);
      return loc.api_error_server(status.isNotEmpty ? status : '?');
    }
    switch (key) {
      case 'api_error_timeout':
        return loc.api_error_timeout;
      case 'api_error_empty_response':
        return loc.api_error_empty_response;
      case 'api_error_athletes_format':
        return loc.api_error_athletes_format;
      case 'api_error_athlete_item_format':
        return loc.api_error_athlete_item_format;
      case 'api_error_athletes_loading':
        return loc.api_error_athletes_loading;
      case 'api_error_server':
        return loc.api_error_server('?');
      case 'api_error_network_no_connection':
        return loc.api_error_network_no_connection;
      case 'api_error_unexpected':
        return loc.api_error_unexpected('');
      default:
        return key;
    }
  }

  /// Строит состояние ошибки
  Widget _buildErrorState(
    String error,
    AppLocalizations localizations,
    ThemeData theme,
  ) {
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
              _localizeError(error, localizations),
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
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
                    SizedBox(height: 4.h),
                    Text(
                      localizations.transfer_results_count(
                        athlete.totalRaces,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.ironmanTextSecondary,
                      ),
                    ),
                    if (athlete.lastRaceLocation != null) ...[
                      SizedBox(height: 2.h),
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
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: AppColors.ironmanRed,
                  size: 24.r,
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
        text: localizations.transfer_confirm_button,
        onPressed: () => _onSavePressed(state.selectedAthlete!),
        textStyle: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

}