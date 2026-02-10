import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
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
  final _totalTimeController = TextEditingController();
  final _swimTimeController = TextEditingController();
  final _t1TimeController = TextEditingController();
  final _bikeTimeController = TextEditingController();
  final _t2TimeController = TextEditingController();
  final _runTimeController = TextEditingController();
  final _scrollController = ScrollController();

  // FocusNodes для управления фокусом
  late final FocusNode _locationFocusNode;
  late final FocusNode _totalTimeFocusNode;
  late final FocusNode _swimTimeFocusNode;
  late final FocusNode _t1TimeFocusNode;
  late final FocusNode _bikeTimeFocusNode;
  late final FocusNode _t2TimeFocusNode;
  late final FocusNode _runTimeFocusNode;

  DateTime? _selectedDate;
  String? _selectedRaceType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Инициализируем FocusNodes
    _locationFocusNode = FocusNode();
    _totalTimeFocusNode = FocusNode();
    _swimTimeFocusNode = FocusNode();
    _t1TimeFocusNode = FocusNode();
    _bikeTimeFocusNode = FocusNode();
    _t2TimeFocusNode = FocusNode();
    _runTimeFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _totalTimeController.dispose();
    _swimTimeController.dispose();
    _t1TimeController.dispose();
    _bikeTimeController.dispose();
    _t2TimeController.dispose();
    _runTimeController.dispose();
    _scrollController.dispose();
    _locationFocusNode.dispose();
    _totalTimeFocusNode.dispose();
    _swimTimeFocusNode.dispose();
    _t1TimeFocusNode.dispose();
    _bikeTimeFocusNode.dispose();
    _t2TimeFocusNode.dispose();
    _runTimeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          localizations.add_result_title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Form(
        key: _formKey,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
            // Info card with icon
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        localizations.add_result_info,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Basic Information Section
            _SectionHeader(
              title: localizations.add_result_section_basic_info,
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: 16),
            
            // Location field with icon
            TextFormField(
              controller: _locationController,
              focusNode: _locationFocusNode,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: localizations.add_result_location,
                hintText: localizations.add_result_location_hint,
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.add_result_location_required;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date picker with improved styling
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
                ),
                child: Text(
                  _selectedDate != null
                      ? _formatDisplayDate(_selectedDate)
                      : localizations.add_result_date_hint,
                  style: TextStyle(
                    color: _selectedDate != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Race type dropdown with icon
            DropdownButtonFormField<String>(
              initialValue: _selectedRaceType,
              decoration: InputDecoration(
                labelText: localizations.add_result_race_type,
                prefixIcon: HugeIcon(
                  icon: HugeIcons.strokeRoundedAward01,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              items: [
                {'value': 'ironman', 'label': localizations.add_result_race_type_ironman},
                {'value': 'ironman_70_3', 'label': localizations.add_result_race_type_ironman_70_3},
                {'value': '5150', 'label': localizations.add_result_race_type_5150},
              ].map((raceType) {
                return DropdownMenuItem<String>(
                  value: raceType['value'],
                  child: Text(raceType['label']!),
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
            const SizedBox(height: 32),

            // Time Section
            _SectionHeader(
              title: localizations.add_result_section_time,
              icon: Icons.access_time_outlined,
            ),
            const SizedBox(height: 16),

            // Total time
            TextFormField(
              controller: _totalTimeController,
              focusNode: _totalTimeFocusNode,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: localizations.add_result_total_time,
                hintText: localizations.add_result_time_hint,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset(
                    'assets/images/svg/flag.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    cacheWidth: 24,
                    cacheHeight: 24,
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                _TimeInputFormatter(),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.add_result_total_time_required;
                }
                if (!_isValidTimeFormat(value)) {
                  return localizations.add_result_time_format;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Disciplines - grouped in card
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.add_result_section_disciplines,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Swim time
                    TextFormField(
                      controller: _swimTimeController,
                      focusNode: _swimTimeFocusNode,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: localizations.add_result_swim,
                        hintText: localizations.add_result_time_hint,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/images/svg/swim.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            cacheWidth: 24,
                            cacheHeight: 24,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        _TimeInputFormatter(),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty && !_isValidTimeFormat(value)) {
                          return localizations.add_result_time_format;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // T1 time
                    TextFormField(
                      controller: _t1TimeController,
                      focusNode: _t1TimeFocusNode,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: localizations.add_result_t1_label,
                        hintText: localizations.add_result_time_hint,
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        _TimeInputFormatter(),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty && !_isValidTimeFormat(value)) {
                          return localizations.add_result_time_format;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Bike time
                    TextFormField(
                      controller: _bikeTimeController,
                      focusNode: _bikeTimeFocusNode,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: localizations.add_result_bike,
                        hintText: localizations.add_result_time_hint,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/images/svg/bike.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            cacheWidth: 24,
                            cacheHeight: 24,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        _TimeInputFormatter(),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty && !_isValidTimeFormat(value)) {
                          return localizations.add_result_time_format;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // T2 time
                    TextFormField(
                      controller: _t2TimeController,
                      focusNode: _t2TimeFocusNode,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: localizations.add_result_t2_label,
                        hintText: localizations.add_result_time_hint,
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        _TimeInputFormatter(),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty && !_isValidTimeFormat(value)) {
                          return localizations.add_result_time_format;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Run time
                    TextFormField(
                      controller: _runTimeController,
                      focusNode: _runTimeFocusNode,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: localizations.add_result_run,
                        hintText: localizations.add_result_time_hint,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/images/svg/run.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            cacheWidth: 24,
                            cacheHeight: 24,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        _TimeInputFormatter(),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty && !_isValidTimeFormat(value)) {
                          return localizations.add_result_time_format;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit button - more prominent
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () {
                  if (_formKey.currentState!.validate()) {
                    _saveResult();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        localizations.add_result_save,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isValidTimeFormat(String value) {
    final regex = RegExp(r'^\d{2}:\d{2}:\d{2}$');
    if (!regex.hasMatch(value)) return false;
    final parts = value.split(':');
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    final seconds = int.tryParse(parts[2]);
    return hours != null &&
        minutes != null &&
        seconds != null &&
        hours >= 0 &&
        minutes >= 0 &&
        minutes < 60 &&
        seconds >= 0 &&
        seconds < 60;
  }

  /// Конвертирует время из формата HH:MM:SS в секунды
  int _timeStringToSeconds(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 3) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;
    return hours * 3600 + minutes * 60 + seconds;
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

      // Конвертируем время в секунды
      final swimTimeSeconds = _timeStringToSeconds(_swimTimeController.text);
      final t1TimeSeconds = _timeStringToSeconds(_t1TimeController.text);
      final bikeTimeSeconds = _timeStringToSeconds(_bikeTimeController.text);
      final t2TimeSeconds = _timeStringToSeconds(_t2TimeController.text);
      final runTimeSeconds = _timeStringToSeconds(_runTimeController.text);
      final totalTimeSeconds = _timeStringToSeconds(_totalTimeController.text);

      final api = RaceResultsApi();
      await api.createRaceResult(
        raceDate: formattedDate,
        location: _locationController.text.trim(),
        raceType: _selectedRaceType!,
        swimTime: swimTimeSeconds,
        t1Time: t1TimeSeconds,
        bikeTime: bikeTimeSeconds,
        t2Time: t2TimeSeconds,
        runTime: runTimeSeconds,
        totalTime: totalTimeSeconds,
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

/// Section header widget for better visual hierarchy
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}


/// TextInputFormatter для маски времени HH:MM:SS
class _TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String formatted = '';
    for (int i = 0; i < text.length && i < 6; i++) {
      if (i == 2 || i == 4) {
        formatted += ':';
      }
      formatted += text[i];
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
