import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironman_mobile/shared/widgets/bottom_nav_bar.dart';
import 'package:ironman_mobile/features/dashboard/presentation/home_tab.dart';
import 'package:ironman_mobile/features/dashboard/presentation/results_screen.dart';
import 'package:ironman_mobile/features/dashboard/presentation/ratings_screen.dart';
import 'package:ironman_mobile/features/dashboard/presentation/athletes_screen.dart';
import 'package:ironman_mobile/features/auth/application/auth_notifier.dart';
import 'package:ironman_mobile/features/results/application/race_results_notifier.dart';
import 'package:ironman_mobile/features/dashboard/application/athletes_notifier.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    // Загружаем данные только если переключаемся на другой таб
    // (не при первом показе, так как начальный index = 0 уже установлен)
    final wasDifferentTab = _currentIndex != index;
    
    setState(() {
      _currentIndex = index;
    });

    // Загружаем данные только когда соответствующий экран становится видимым
    // и только если переключаемся на другой таб
    if (wasDifferentTab) {
      // Используем addPostFrameCallback чтобы избежать модификации провайдера во время setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (index == 1) {
          // Results tab - загружаем результаты только если они еще не загружены
          final resultsState = ref.read(raceResultsProvider);
          final user = ref.read(authProvider).user;
          int? profileId;
          if (user?.profile is Map<String, dynamic>) {
            final profile = user!.profile as Map<String, dynamic>;
            profileId = profile['id'] as int?;
          }
          
          // Не загружаем "Мои результаты" если:
          // 1. Уже идет загрузка ИЛИ
          // 2. Результаты уже есть и они от текущего пользователя
          final shouldSkipMyResults = resultsState.isLoading || 
                                     (resultsState.results.isNotEmpty && 
                                      profileId != null && 
                                      resultsState.results.first.userProfileId == profileId);
          
          if (profileId != null && !shouldSkipMyResults) {
            ref.read(raceResultsProvider.notifier).loadResults(profileId);
          }
          
          // Also load all results when Results tab is selected (only if not loaded and not loading)
          final allResultsState = ref.read(allRaceResultsProvider);
          if (!allResultsState.isLoading && allResultsState.results.isEmpty) {
            ref.read(allRaceResultsProvider.notifier).loadAllResults();
          }
        }
        // Ratings tab (index 2) - загрузка рейтингов происходит в самом RatingsScreen
        // когда экран становится активным
        else if (index == 3) {
          // Athletes tab - загружаем атлетов
          ref.read(athletesProvider.notifier).loadAthletes();
        }
        // Home tab (index 0) - данные уже загружаются в самом HomeTab
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    void backToHome() => _onTabSelected(0);

    final screens = [
      const HomeTab(key: ValueKey('home')),
      ResultsScreen(key: const ValueKey('results'), onBack: backToHome),
      RatingsScreen(key: const ValueKey('ratings'), onBack: backToHome, isActive: _currentIndex == 2),
      AthletesScreen(key: const ValueKey('athletes'), onBack: backToHome),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0E0F10),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
