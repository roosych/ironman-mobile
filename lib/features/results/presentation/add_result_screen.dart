import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/core/theme/app_button_styles.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import '../../../shared/utils/alert_helper.dart';
import '../infrastructure/race_results_api.dart';
import '../../settings/application/locale_notifier.dart';

class AddResultScreen extends ConsumerStatefulWidget {
  const AddResultScreen({super.key});

  @override
  ConsumerState<AddResultScreen> createState() => _AddResultScreenState();
}

class _AddResultScreenState extends ConsumerState<AddResultScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _scrollController = ScrollController();

  // FocusNodes для управления фокусом
  late final FocusNode _locationFocusNode;

  DateTime? _selectedDate;
  String? _selectedRaceType;
  bool _isSaving = false;

  // Переменные для отслеживания валидации
  bool _showDateValidation = false;
  bool _showTotalTimeValidation = false;

  // Duration переменные для времени
  Duration _totalTime = Duration.zero;
  Duration _swimTime = Duration.zero;
  Duration _t1Time = Duration.zero;
  Duration _bikeTime = Duration.zero;
  Duration _t2Time = Duration.zero;
  Duration _runTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Инициализируем FocusNodes
    _locationFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _scrollController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: ref.read(localeProvider),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _showDateValidation = false; // Убираем ошибку после выбора даты
      });
    }
  }

  String _formatDisplayDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String formatDurationHhMmSs(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Opens a Cupertino-style timer picker (hours, minutes, seconds) in a modal.
  /// On confirm: updates the discipline [Duration], recalculates total time and
  /// paces, and refreshes UI via setState. On cancel: dismisses without changes.
  Future<void> _pickTime({
    required String title,
    required Duration initial,
    required ValueChanged<Duration> onConfirm,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();

    // Clamp to CupertinoTimerPicker range (0–23:59:59); picker uses this as initial.
    final clampedInitial = Duration(
      hours: initial.inHours.clamp(0, 23),
      minutes: initial.inMinutes.remainder(60),
      seconds: initial.inSeconds.remainder(60),
    );
    Duration selected = clampedInitial;

    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          loc.common_cancel,
                          style: const TextStyle(color: AppColors.ironmanRed),
                        ),
                      ),
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        onPressed: () {
                          onConfirm(selected);
                          Navigator.of(ctx).pop();
                        },
                        child: Text(
                          loc.pace_calculator_done,
                          style: const TextStyle(
                            color: AppColors.ironmanRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 220.h,
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hms,
                    initialTimerDuration: clampedInitial,
                    onTimerDurationChanged: (Duration d) => selected = d,
                    backgroundColor: theme.colorScheme.surface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: theme.colorScheme.onSurface,
            size: 24.r,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          localizations.add_result_title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp),
        ),
      ),
      body: Form(
        key: _formKey,
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(16.r),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [

            SizedBox(height: 16.h),

            // Location field with icon
            TextFormField(
              controller: _locationController,
              focusNode: _locationFocusNode,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: localizations.add_result_location,
                hintText: localizations.add_result_location_hint,
                hintStyle: theme.textTheme.bodyLarge,
                filled: true,
                fillColor: theme.colorScheme.surface,
                prefixIcon: HugeIcon(
                  icon: HugeIcons.strokeRoundedLocation01,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  size: 20.r,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: theme.colorScheme.error,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: theme.colorScheme.error,
                    width: 1,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.add_result_location_required;
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),

            // Date picker with improved styling
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: localizations.add_result_date,
                  hintText: localizations.add_result_date_hint,
                  hintStyle: theme.textTheme.bodyLarge,
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  prefixIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar03,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 20.r,
                  ),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  errorText: (_showDateValidation && _selectedDate == null) ? localizations.add_result_date_required : null,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: theme.colorScheme.error,
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: theme.colorScheme.error,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  _selectedDate != null
                      ? _formatDisplayDate(_selectedDate)
                      : localizations.add_result_date_hint,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _selectedDate != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Race type dropdown with icon
            DropdownButtonFormField<String>(
              initialValue: _selectedRaceType,
              decoration: InputDecoration(
                labelText: localizations.add_result_race_type,
                hintStyle: theme.textTheme.bodyLarge,
                filled: true,
                fillColor: theme.colorScheme.surface,
                prefixIcon: HugeIcon(
                  icon: HugeIcons.strokeRoundedAward01,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  size: 20.r,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: theme.colorScheme.error,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: theme.colorScheme.error,
                    width: 1,
                  ),
                ),
              ),
              items: [
                {'value': 'ironman', 'label': localizations.add_result_race_type_ironman},
                {'value': 'ironman_70_3', 'label': localizations.add_result_race_type_ironman_70_3},
                {'value': '5150', 'label': localizations.add_result_race_type_5150},
              ].map((raceType) {
                return DropdownMenuItem<String>(
                  value: raceType['value'],
                  child: Text(raceType['label']!.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRaceType = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.add_result_race_type_required;
                }
                return null;
              },
            ),
            SizedBox(height: 32.h),

            // Total time
            DisciplineCard(
              icon: Icons.flag_outlined,
              iconAsset: 'assets/images/svg/flag.png',
              label: localizations.add_result_total_time,
              duration: _totalTime,
              rightLabel: null,
              rightValue: null,
              isLocked: false,
              isSelected: false,
              onTap: () => _pickTime(
                title: localizations.add_result_total_time,
                initial: _totalTime,
                onConfirm: (d) => setState(() {
                  _totalTime = d;
                  _showTotalTimeValidation = false; // Убираем ошибку после выбора времени
                }),
              ),
            ),
            if (_showTotalTimeValidation && _totalTime.inSeconds == 0)
              Padding(
                padding: EdgeInsets.only(left: 12.w, top: 4.h),
                child: Text(
                  localizations.add_result_total_time_required,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            SizedBox(height: 8.h),

            // Swim time
            DisciplineCard(
              icon: Icons.pool_outlined,
              iconAsset: 'assets/images/svg/swim.svg',
              label: localizations.add_result_swim,
              duration: _swimTime,
              rightLabel: null,
              rightValue: null,
              isLocked: false,
              isSelected: false,
              onTap: () => _pickTime(
                title: localizations.add_result_swim,
                initial: _swimTime,
                onConfirm: (d) => setState(() => _swimTime = d),
              ),
            ),
            SizedBox(height: 4.h),

            // T1 time
            DisciplineCard(
              icon: Icons.swap_horiz,
              label: 'T1',
              duration: _t1Time,
              rightLabel: null,
              rightValue: null,
              isLocked: false,
              isSelected: false,
              onTap: () => _pickTime(
                title: localizations.add_result_t1_label,
                initial: _t1Time,
                onConfirm: (d) => setState(() => _t1Time = d),
              ),
            ),
            SizedBox(height: 4.h),

            // Bike time
            DisciplineCard(
              icon: Icons.directions_bike_outlined,
              iconAsset: 'assets/images/svg/bike.svg',
              label: localizations.add_result_bike,
              duration: _bikeTime,
              rightLabel: null,
              rightValue: null,
              isLocked: false,
              isSelected: false,
              onTap: () => _pickTime(
                title: localizations.add_result_bike,
                initial: _bikeTime,
                onConfirm: (d) => setState(() => _bikeTime = d),
              ),
            ),
            SizedBox(height: 4.h),

            // T2 time
            DisciplineCard(
              icon: Icons.swap_horiz,
              label: 'T2',
              duration: _t2Time,
              rightLabel: null,
              rightValue: null,
              isLocked: false,
              isSelected: false,
              onTap: () => _pickTime(
                title: localizations.add_result_t2_label,
                initial: _t2Time,
                onConfirm: (d) => setState(() => _t2Time = d),
              ),
            ),
            SizedBox(height: 4.h),

            // Run time
            DisciplineCard(
              icon: Icons.directions_run_outlined,
              iconAsset: 'assets/images/svg/run.svg',
              label: localizations.add_result_run,
              duration: _runTime,
              rightLabel: null,
              rightValue: null,
              isLocked: false,
              isSelected: false,
              onTap: () => _pickTime(
                title: localizations.add_result_run,
                initial: _runTime,
                onConfirm: (d) => setState(() => _runTime = d),
              ),
            ),
            SizedBox(height: 32.h),

            // Submit button - gradient style
            SizedBox(
              width: double.infinity,
              child: _isSaving
                  ? Container(
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        color: Colors.grey,
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
                    )
                  : AppButtonStyles.gradientElevatedButton(
                      text: localizations.add_result_save,
                      onPressed: () {
                        setState(() {
                          _showDateValidation = true;
                          _showTotalTimeValidation = true;
                        });
                        if (_formKey.currentState!.validate() && _selectedDate != null && _totalTime.inSeconds > 0) {
                          _saveResult();
                        }
                      },
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      borderRadius: 12.r,
                      textStyle: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    ),
            ),
                SizedBox(height: 64.h),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _saveResult() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;
    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Форматируем дату в формат YYYY-MM-DD
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      final api = RaceResultsApi();
      await api.createRaceResult(
        raceDate: formattedDate,
        location: _locationController.text.trim(),
        raceType: _selectedRaceType!,
        swimTime: _swimTime.inSeconds,
        t1Time: _t1Time.inSeconds,
        bikeTime: _bikeTime.inSeconds,
        t2Time: _t2Time.inSeconds,
        runTime: _runTime.inSeconds,
        totalTime: _totalTime.inSeconds,
      );

      if (!mounted) return;

      // Показываем сообщение об успехе
      final localizations = AppLocalizations.of(context);
      if (localizations != null) {
        final successMessage = '${localizations.add_result_success_title}\n${localizations.add_result_success_message}';
        AlertHelper.showSuccess(context, successMessage);
      }

      // Закрываем экран
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceFirst('RaceResultsApiException: ', '');
      final localizations = AppLocalizations.of(context);
      AlertHelper.showError(
        context,
        errorMessage,
        buttonText: localizations?.error_ok,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}


// ---------------------------------------------------------------------------
// Discipline icon (asset image or fallback icon)
// ---------------------------------------------------------------------------

class _DisciplineIcon extends StatelessWidget {
  const _DisciplineIcon({
    required this.icon,
    required this.color,
    required this.size,
    this.iconAsset,
  });

  final IconData icon;
  final String? iconAsset;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (iconAsset != null && iconAsset!.isNotEmpty) {
      return SvgPicture.asset(
        iconAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    return Icon(icon, color: color, size: size);
  }
}

// ---------------------------------------------------------------------------
// Discipline Card (reusable)
// ---------------------------------------------------------------------------

class DisciplineCard extends StatelessWidget {
  const DisciplineCard({
    super.key,
    required this.icon,
    required this.label,
    required this.duration,
    required this.isLocked,
    required this.isSelected,
    required this.onTap,
    this.iconAsset,
    this.rightLabel,
    this.rightValue,
  });

  final IconData icon;

  /// Optional PNG/SVG asset path (e.g. assets/images/svg/swim.svg). When set, shown instead of [icon].
  final String? iconAsset;
  final String label;
  final Duration duration;
  final String? rightLabel;
  final String? rightValue;
  final bool isLocked;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: isSelected
                ? AppColors.ironmanRed
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                // Иконка слева
                _DisciplineIcon(
                  icon: icon,
                  iconAsset: iconAsset,
                  color: isSelected
                      ? AppColors.ironmanRed
                      : AppColors.ironmanTextSecondary,
                  size: 36.r,
                ),
                SizedBox(width: 16.w),

                // Название дисциплины в центре
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 18.sp,
                        ),
                      ),
                      if (isLocked) ...[
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.lock_outline,
                          size: 18.r,
                          color: AppColors.ironmanTextSecondary,
                        ),
                      ],
                    ],
                  ),
                ),

                // Время справа
                Text(
                  formatDurationHhMmSs(duration),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String formatDurationHhMmSs(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

