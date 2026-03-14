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
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeTab(key: const ValueKey('home')),
      ResultsScreen(key: const ValueKey('results'), onBack: _backToHome),
      RatingsScreen(key: const ValueKey('ratings'), onBack: _backToHome),
      AthletesScreen(key: const ValueKey('athletes'), onBack: _backToHome),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(authProvider.notifier).refreshUser();
    });
  }

  void _backToHome() => _onTabSelected(0);

  void _onTabSelected(int index) {
    final wasDifferentTab = _currentIndex != index;
    if (wasDifferentTab) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    setState(() {
      _currentIndex = index;
    });
    if (wasDifferentTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (index == 1) {
          final resultsState = ref.read(raceResultsProvider);
          final user = ref.read(authProvider).user;
          final profileId = user?.profile?.id;
          final shouldSkipMyResults = resultsState.isLoading ||
              (resultsState.results.isNotEmpty &&
                  profileId != null &&
                  resultsState.results.first.userProfileId == profileId);
          if (profileId != null && !shouldSkipMyResults) {
            ref.read(raceResultsProvider.notifier).loadResults(profileId);
          }
          final allResultsState = ref.read(allRaceResultsProvider);
          if (!allResultsState.isLoading && allResultsState.results.isEmpty) {
            ref.read(allRaceResultsProvider.notifier).loadAllResults();
          }
        } else if (index == 3) {
          ref.read(athletesProvider.notifier).loadAthletes();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0F10),
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          _screens.length,
          (i) => ExcludeFocus(
            excluding: i != _currentIndex,
            child: _screens[i],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
