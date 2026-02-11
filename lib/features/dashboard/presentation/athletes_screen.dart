import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/features/dashboard/domain/athlete.dart';
import 'package:ironman_mobile/features/dashboard/application/athletes_notifier.dart';
import 'package:ironman_mobile/features/dashboard/application/athletes_state.dart';
import 'package:ironman_mobile/features/dashboard/presentation/athlete_profile_screen.dart';

class AthletesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const AthletesScreen({super.key, this.onBack});

  @override
  ConsumerState<AthletesScreen> createState() => _AthletesScreenState();
}

class _AthletesScreenState extends ConsumerState<AthletesScreen> {
  String _searchQuery = '';
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // НЕ загружаем данные в initState, так как экран может быть не виден
    // Загрузка будет происходить через dashboard_screen при переключении вкладок
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Athlete> get _filteredAthletes {
    final athletesState = ref.watch(athletesProvider);
    var filtered = athletesState.athletes;

    // Применяем поиск
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((a) {
        return a.name.toLowerCase().contains(query) ||
            a.id.toString().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final athletesState = ref.watch(athletesProvider);

    return GestureDetector(
      onTap: () {
        // Скрываем клавиатуру при тапе вне поля ввода
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: AppColors.ironmanWhite,
              size: 24,
            ),
            onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            localizations.athletes_list_title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Поисковая строка
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: localizations.athletes_search_hint,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  prefixIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 24,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            size: 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
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

            // Список атлетов
            Expanded(child: _buildAthletesList(athletesState)),
          ],
        ),
      ),
    );
  }

  Widget _buildAthleteCard(BuildContext context, Athlete athlete) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AthleteProfileScreen(athlete: athlete),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            // Аватар с бейджем
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.ironmanLightGray,
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: athlete.avatar != null
                        ? Image.network(
                            athlete.avatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar(theme);
                            },
                          )
                        : _buildDefaultAvatar(theme),
                  ),
                ),
                // Бейдж с номером Ironman
                if (athlete.ironmanNumber != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.ironmanRed,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${athlete.ironmanNumber}',
                          style: const TextStyle(
                            color: AppColors.ironmanWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Имя и IRONMAN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    athlete.name.toUpperCase(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                  // Показываем текст IRONMANx{количество} если race_counts.ironman > 0
                  if (athlete.raceCounts.ironman > 0) ...[
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: 'IRONMAN',
                            style: TextStyle(
                              color: AppColors.ironmanWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: ' x${athlete.raceCounts.ironman}',
                            style: TextStyle(
                              color: AppColors.ironmanRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Стрелка навигации
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: AppColors.ironmanWhite,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedUser,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildAthletesList(AthletesState state) {
    // Показываем индикатор загрузки если данные загружаются или список пуст и нет ошибки
    if (state.isLoading || (state.athletes.isEmpty && !state.hasError)) {
      return const Center(child: CircularProgressIndicator());
    }

    // Показываем ошибку, если она есть и нет загрузки (включая случай pull-to-refresh)
    if (state.hasError && !state.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.error ?? 'Ошибка загрузки',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(athletesProvider.notifier).loadAthletes();
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(athletesProvider.notifier).loadAthletes();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: _filteredAthletes.length,
        itemBuilder: (context, index) {
          return _buildAthleteCard(context, _filteredAthletes[index]);
        },
      ),
    );
  }
}
