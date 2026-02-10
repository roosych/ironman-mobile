import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/features/upcoming_races/application/upcoming_races_notifier.dart';
import 'package:ironman_mobile/features/settings/application/locale_notifier.dart';
import 'package:ironman_mobile/shared/utils/alert_helper.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';
import 'package:ironman_mobile/core/theme/app_button_styles.dart';

class AddUpcomingRaceBottomSheet extends ConsumerStatefulWidget {
  const AddUpcomingRaceBottomSheet({super.key});

  @override
  ConsumerState<AddUpcomingRaceBottomSheet> createState() =>
      _AddUpcomingRaceBottomSheetState();
}

class _AddUpcomingRaceBottomSheetState
    extends ConsumerState<AddUpcomingRaceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedRaceType;
  bool _isSaving = false;
  List<DropdownMenuItem<String>>? _cachedRaceTypeItems;
  List<Widget>? _cachedSelectedItemBuilder;

  List<Map<String, String>> _getRaceTypes(AppLocalizations localizations) {
    return [
      {'value': 'Ironman', 'label': localizations.add_result_race_type_ironman},
      {
        'value': 'Ironman 70.3',
        'label': localizations.add_result_race_type_ironman_70_3,
      },
      {'value': '5150', 'label': localizations.add_result_race_type_5150},
    ];
  }

  String _getRaceTypeDisplayText(String value) {
    switch (value) {
      case 'Ironman':
        return 'IRONMAN';
      case 'Ironman 70.3':
        return 'IRONMAN 70.3';
      case '5150':
        return '5150';
      default:
        return value;
    }
  }

  void _buildRaceTypeItems(AppLocalizations localizations) {
    final raceTypes = _getRaceTypes(localizations);
    _cachedRaceTypeItems = raceTypes.map((raceType) {
      return DropdownMenuItem<String>(
        value: raceType['value'],
        child: Text(_getRaceTypeDisplayText(raceType['value']!)),
      );
    }).toList();
    _cachedSelectedItemBuilder = raceTypes.map((raceType) {
      return Text(
        _getRaceTypeDisplayText(raceType['value']!),
        overflow: TextOverflow.ellipsis,
      );
    }).toList();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: ref.read(localeProvider),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDisplayDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  Future<void> _saveRace() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Валидируем дату
      if (_selectedDate == null) {
        throw Exception('Пожалуйста, выберите дату гонки');
      }

      // Преобразуем race type в формат API
      String apiRaceType;
      switch (_selectedRaceType!.toLowerCase()) {
        case 'ironman':
          apiRaceType = 'ironman';
          break;
        case 'ironman 70.3':
          apiRaceType = 'ironman_70_3';
          break;
        case '5150':
          apiRaceType = '5150';
          break;
        default:
          apiRaceType = _selectedRaceType!.toLowerCase().replaceAll(' ', '_');
      }

      // Форматируем дату в формат YYYY-MM-DD
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      await ref.read(globalUpcomingRacesProvider.notifier).createUpcomingRace(
        raceType: apiRaceType,
        location: _locationController.text.trim(),
        raceDate: formattedDate,
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
      final localizations = AppLocalizations.of(context);

      navigator.pop();

      if (localizations != null) {
        AlertHelper.showSuccess(context, localizations.home_add_race_title);
      }
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Кэшируем элементы dropdown при первом построении
    if (_cachedRaceTypeItems == null) {
      final localizations = AppLocalizations.of(context);
      if (localizations != null) {
        _buildRaceTypeItems(localizations);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    // Обновляем кэш если локализация изменилась
    if (_cachedRaceTypeItems == null) {
      _buildRaceTypeItems(localizations);
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(color: AppColors.ironmanGray, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with title and close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.home_add_race_title,
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
                  const SizedBox(height: 24),

                  // Race type dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRaceType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: localizations.add_result_race_type,
                      prefixIcon: HugeIcon(
                        icon: HugeIcons.strokeRoundedAward01,
                        color: Colors.white,
                        size: 20,
                      ),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    selectedItemBuilder: _cachedSelectedItemBuilder != null
                        ? (BuildContext context) => _cachedSelectedItemBuilder!
                        : (BuildContext context) => [],
                    items: _cachedRaceTypeItems ?? [],
                    menuMaxHeight: 200,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRaceType = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.add_result_race_type_required;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location field
                  TextFormField(
                    controller: _locationController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: localizations.add_result_location,
                      hintText: localizations.add_result_location_hint,
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.add_result_location_required;
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date picker
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: localizations.add_result_date,
                        hintText: localizations.add_result_date_hint,
                        prefixIcon: Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        border: const OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? _formatDisplayDate(_selectedDate!)
                            : localizations.add_result_date_hint,
                        style: TextStyle(
                          color: _selectedDate != null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  _isSaving
                      ? SizedBox(
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : AppButtonStyles.gradientElevatedButton(
                          text: localizations.add_result_save,
                          onPressed: _saveRace,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function to show the Add Upcoming Race Bottom Sheet
void showAddUpcomingRaceBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AddUpcomingRaceBottomSheet(),
  );
}