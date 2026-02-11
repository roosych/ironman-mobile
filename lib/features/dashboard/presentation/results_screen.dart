import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/core/theme/app_colors.dart';
import 'package:ironman_mobile/features/auth/application/auth_notifier.dart';
import 'package:ironman_mobile/features/auth/application/auth_state.dart';
import 'package:ironman_mobile/features/results/application/race_results_notifier.dart';
import 'package:ironman_mobile/features/results/application/race_results_state.dart';
import 'package:ironman_mobile/shared/widgets/result_card.dart';
import 'package:ironman_mobile/features/results/presentation/add_result_screen.dart';
import 'package:ironman_mobile/shared/widgets/unauthenticated_bottom_nav.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const ResultsScreen({super.key, this.onBack});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  TabController? _tabController;
  String _searchQuery = '';
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // Проверяем авторизацию для определения количества табов
    final isAuthenticated = _isUserAuthenticated();
    final tabCount = isAuthenticated ? 2 : 0; // 0 табов для неавторизованных
    if (tabCount > 0) {
      _tabController = TabController(length: tabCount, vsync: this, initialIndex: 0);
      _tabController!.addListener(_onTabChanged);
    }

    // Загружаем все результаты для всех пользователей (авторизованных и неавторизованных)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAllResults();
      }
    });
    _searchController = TextEditingController();
    WidgetsBinding.instance.addObserver(this);
  }

  void _onTabChanged() {
    if (_isUserAuthenticated() && _tabController != null && !_tabController!.indexIsChanging) {
      // Load my results when switching to "My Results" tab (index 1)
      // Only for authenticated users
      if (_tabController!.index == 1) {
        // Используем addPostFrameCallback чтобы избежать модификации провайдера во время построения
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          
          // Дополнительная проверка в UI для предотвращения лишних вызовов
          final resultsState = ref.read(raceResultsProvider);
          final profileId = _getProfileId();
          
          // Не вызываем загрузку, если:
          // 1. Уже идет загрузка
          // 2. Результаты уже есть и они от текущего пользователя
          if (resultsState.isLoading) {
            return; // Уже идет загрузка
          }
          
          if (resultsState.results.isNotEmpty && profileId != null) {
            final firstResult = resultsState.results.first;
            if (firstResult.userProfileId == profileId) {
              return; // Результаты уже загружены для этого пользователя
            }
          }
          
          // Провайдер сам проверит еще раз, нужно ли загружать данные
          _loadResults();
        });
      }
    }
  }

  @override
  void dispose() {
    if (_tabController != null) {
      _tabController!.removeListener(_onTabChanged);
      _tabController!.dispose();
    }
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Используем addPostFrameCallback чтобы избежать модификации провайдера во время жизненного цикла
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isUserAuthenticated() && _tabController != null) {
          _loadAllResults();
          if (_tabController!.index == 1) {
            _loadResults();
          }
        }
      });
    }
  }

  int? _getProfileId() {
    final user = ref.read(authProvider).user;
    if (user?.profile is Map<String, dynamic>) {
      final profile = user!.profile as Map<String, dynamic>;
      return profile['id'] as int?;
    }
    return null;
  }

  bool _isUserAuthenticated() {
    final authState = ref.read(authProvider);
    return authState.status == AuthStatus.authenticated && authState.user != null;
  }

  List<Widget> _buildTabs(BuildContext context) {
    final tabs = <Widget>[
      Tab(
        text: AppLocalizations.of(context)!.results_all_athletes,
      ),
    ];

    if (_isUserAuthenticated()) {
      tabs.add(
        Tab(
          text: AppLocalizations.of(context)!.results_my_results,
        ),
      );
    }

    return tabs;
  }

  List<Widget> _buildTabViews(RaceResultsState allResultsState, RaceResultsState myResultsState) {
    final views = <Widget>[
      _buildAllAthletesTab(allResultsState),
    ];

    if (_isUserAuthenticated()) {
      views.add(_buildMyResultsTab(myResultsState));
    }

    return views;
  }

  void _loadResults() {
    final profileId = _getProfileId();
    if (profileId != null) {
      ref.read(raceResultsProvider.notifier).loadResults(profileId);
    }
  }

  Future<void> _refreshResults() async {
    final profileId = _getProfileId();
    if (profileId != null) {
      try {
        await ref.read(raceResultsProvider.notifier).refreshResults(profileId);
      } catch (e) {
        // Ошибка уже обработана в провайдере, алерт покажется через listener
      }
    }
  }

  void _loadNextPage() {
    final profileId = _getProfileId();
    if (profileId != null) {
      ref.read(raceResultsProvider.notifier).loadNextPage(profileId);
    }
  }

  void _loadAllResults() {
    ref.read(allRaceResultsProvider.notifier).loadAllResults();
  }

  Future<void> _refreshAllResults() async {
    try {
      await ref.read(allRaceResultsProvider.notifier).refreshAllResults();
    } catch (e) {
      // Ошибка уже обработана в провайдере, алерт покажется через listener
    }
  }

  List<dynamic> _filterResults(List<dynamic> results) {
    if (_searchQuery.isEmpty) return results;

    final query = _searchQuery.toLowerCase();
    return results.where((result) {
      final athleteName = (result.athleteName ?? '').toLowerCase();
      final location = result.location.toLowerCase();
      final raceType = result.raceType.toLowerCase();

      return athleteName.contains(query) ||
             location.contains(query) ||
             raceType.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final myResultsState = ref.watch(raceResultsProvider);
    final allResultsState = ref.watch(allRaceResultsProvider);

    // Listen for auth status changes to recreate tabs if needed
    ref.listen(authProvider, (previous, next) {
      if (mounted && previous?.status != next.status) {
        final wasAuthenticated = previous?.status == AuthStatus.authenticated;
        final isAuthenticated = _isUserAuthenticated();

        if (wasAuthenticated && _tabController != null) {
          // User logged out - dispose existing controller
          _tabController!.removeListener(_onTabChanged);
          _tabController!.dispose();
          _tabController = null;
        }

        if (isAuthenticated) {
          // User logged in - create controller
          final tabCount = 2;
          _tabController = TabController(length: tabCount, vsync: this, initialIndex: 0);
          _tabController!.addListener(_onTabChanged);
        }

        setState(() {}); // Rebuild to show new content
      }
    });

    // Show different content based on authentication status
    if (!_isUserAuthenticated()) {
      // For unauthenticated users, show only "All Results" without tabs
      return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context)!.results_title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            backgroundColor: AppColors.ironmanBlack,
            foregroundColor: AppColors.ironmanWhite,
            leading: widget.onBack != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onBack,
                  )
                : null,
          ),
          body: Column(
            children: [
              // Search bar
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
                    hintText: AppLocalizations.of(context)!.athletes_search_hint,
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      size: 24,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              // Results content
              Expanded(
                child: _buildAllAthletesTab(allResultsState),
              ),
            ],
          ),
          // Add bottom navigation for unauthenticated users
          bottomNavigationBar: const UnauthenticatedBottomNav(currentIndex: 0), // 0 = Results
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Скрываем клавиатуру при тапе вне поля ввода
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        floatingActionButton: _tabController != null ? AnimatedBuilder(
          animation: _tabController!,
          builder: (context, child) {
            return _tabController!.index == 1
                ? FloatingActionButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddResultScreen(),
                        ),
                      );
                    },
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add),
                  )
                : const SizedBox.shrink();
          },
        ) : null,
        body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              leading: IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24,
                ),
                onPressed:
                    widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
              title: Text(
                AppLocalizations.of(context)!.results_title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              pinned: true,
              floating: false,
              snap: false,
              forceElevated: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight + 80),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        color: Colors.black.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Поле поиска
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.athletes_search_hint,
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            prefixIcon: HugeIcon(
                              icon: HugeIcons.strokeRoundedSearch01,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              size: 24,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: HugeIcon(
                                      icon: HugeIcons.strokeRoundedCancel01,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(
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
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      // TabBar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.ironmanGray,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: TabBar(
                            controller: _tabController!,
                            labelColor: Colors.white,
                            labelStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            unselectedLabelColor: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.ironmanRed,
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            indicatorPadding: EdgeInsets.zero,
                            tabs: _buildTabs(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController!,
          physics: const BouncingScrollPhysics(),
          children: _buildTabViews(allResultsState, myResultsState),
        ),
      ),
      ),
    );
  }


  Widget _buildMyResultsTab(RaceResultsState state) {
    // Фильтруем только подтвержденные результаты и применяем поиск
    final approvedResults = state.results.where((r) => r.isApproved).toList();
    final filteredResults = _filterResults(approvedResults);

    if (state.isLoading && state.results.isEmpty) {
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
                state.error ??
                    AppLocalizations.of(context)!.common_loading_error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadResults,
                child: Text(AppLocalizations.of(context)!.common_retry),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredResults.isEmpty && !state.isLoading) {
      return Center(
        child: Text(AppLocalizations.of(context)!.results_no_results),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshResults,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          // Загружаем следующую страницу, когда пользователь прокрутил до 80% списка
          if (scrollInfo.metrics.pixels >=
              scrollInfo.metrics.maxScrollExtent * 0.8) {
            if (state.hasMorePages &&
                !state.isLoadingMore &&
                !state.isLoading) {
              // Используем addPostFrameCallback чтобы избежать модификации провайдера во время обработки события
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _loadNextPage();
                }
              });
            }
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: filteredResults.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Показываем индикатор загрузки в конце списка
            if (index == filteredResults.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ResultCard(
                result: filteredResults[index],
                isMyResults: true,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAllAthletesTab(RaceResultsState state) {
    // Фильтруем только подтвержденные результаты и применяем поиск
    final approvedResults = state.results.where((r) => r.isApproved).toList();
    final filteredResults = _filterResults(approvedResults);

    if (state.isLoading && state.results.isEmpty) {
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
                state.error ??
                    AppLocalizations.of(context)!.common_loading_error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAllResults,
                child: Text(AppLocalizations.of(context)!.common_retry),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredResults.isEmpty && !state.isLoading) {
      return Center(
        child: Text(AppLocalizations.of(context)!.results_no_results),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAllResults,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          // Загружаем следующую страницу, когда пользователь прокрутил до 80% списка
          if (scrollInfo.metrics.pixels >=
              scrollInfo.metrics.maxScrollExtent * 0.8) {
            if (state.hasMorePages &&
                !state.isLoadingMore &&
                !state.isLoading) {
              // Используем addPostFrameCallback чтобы избежать модификации провайдера во время обработки события
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ref.read(allRaceResultsProvider.notifier).loadNextPage();
                }
              });
            }
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: filteredResults.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Показываем индикатор загрузки в конце списка
            if (index == filteredResults.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ResultCard(result: filteredResults[index]),
            );
          },
        ),
      ),
    );
  }
}
