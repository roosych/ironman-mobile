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
import 'package:ironman_mobile/features/transfer/providers/transfer_providers.dart';
import 'package:ironman_mobile/features/transfer/presentation/widgets/transfer_status_card.dart';
import 'package:ironman_mobile/features/transfer/presentation/widgets/athlete_selection_bottom_sheet.dart';
import 'package:ironman_mobile/features/transfer/models/transfer_status_enum.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';

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

        // Проактивно загружаем transfer статус для авторизованных пользователей
        // чтобы при переключении на "Мои результаты" данные уже были готовы
        if (_isUserAuthenticated()) {
          _loadTransferStatus();
        }
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

          // Также проверяем актуальность transfer статуса при переходе на таб
          final transferState = ref.read(transferStatusProvider);
          // Загружаем transfer статус если:
          // 1. Статус не загружался (нет заявки и нет ошибки и не идет загрузка)
          // 2. Или есть ошибка (нужно повторить попытку)
          if ((transferState.request == null && !transferState.hasError && !transferState.isLoading) ||
              transferState.hasError) {
            _loadTransferStatus();
          }
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
    return user?.profile?.id;
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
      // Обновляем результаты (основная функциональность)
      await ref.read(raceResultsProvider.notifier).refreshResults(profileId);

      // Обновляем статус заявки на перенос независимо (если API доступен)
      try {
        ref.read(transferStatusProvider.notifier).refreshStatus();
      } catch (e) {
        // Игнорируем ошибки transfer API - это не критично для основной функциональности
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

  void _loadTransferStatus() {
    // Проверяем авторизацию перед запросом
    final authState = ref.read(authProvider);
    if (authState.status != AuthStatus.authenticated || authState.user == null) {
      debugPrint('🚫 _loadTransferStatus: пользователь не авторизован, пропускаем загрузку transfer статуса');
      return;
    }

    final transferState = ref.read(transferStatusProvider);
    debugPrint('✅ _loadTransferStatus: пользователь авторизован, загружаем transfer статус');
    debugPrint('👤 User ID: ${authState.user?.profile?.id}');
    debugPrint('🔍 Current transfer state: request=${transferState.request?.status}, isLoading=${transferState.isLoading}, hasError=${transferState.hasError}');

    try {
      ref.read(transferStatusProvider.notifier).loadCurrentStatus();
    } catch (e) {
      debugPrint('❌ _loadTransferStatus: ошибка при загрузке transfer статуса: $e');
      // Игнорируем ошибки - transfer функционал не критичен
    }
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

  /// Показывает BottomSheet для выбора атлета-донора результатов
  void _showAthleteSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AthleteSelectionBottomSheet(),
    );
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
                ? Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryGradientStart,
                          AppColors.primaryGradientEnd,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGradientShadow.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AddResultScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(28),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
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
              forceElevated: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight + 80),
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
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
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryGradientStart,
                                  AppColors.primaryGradientEnd,
                                ],
                              ),
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
                state.error != null
                    ? ErrorHandler.localizeErrorKey(state.error!, AppLocalizations.of(context)!)
                    : AppLocalizations.of(context)!.common_loading_error,
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
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // НОВОЕ: Блок статуса переноса результатов ВЫШЕ списка результатов
            Consumer(
              builder: (context, ref, _) {
                final transferState = ref.watch(transferStatusProvider);

                // Не показываем блок только если:
                // 1. Заявка одобрена - результаты уже видны
                // 2. Статус еще загружается - ждем окончательного результата
                if ((transferState.request?.status.isApproved ?? false) ||
                    transferState.isLoading) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TransferStatusCard(
                      state: transferState,
                      onTransferRequest: () => _showAthleteSelectionBottomSheet(context),
                    ),
                  ),
                );
              },
            ),

            // Список результатов или empty state
            filteredResults.isEmpty && !state.isLoading
                ? SliverFillRemaining(
                    child: Center(
                      child: Text(AppLocalizations.of(context)!.results_no_results),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
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
                              showBorder: false,
                            ),
                          );
                        },
                        childCount: filteredResults.length + (state.isLoadingMore ? 1 : 0),
                      ),
                    ),
                  ),
          ],
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
                state.error != null
                    ? ErrorHandler.localizeErrorKey(state.error!, AppLocalizations.of(context)!)
                    : AppLocalizations.of(context)!.common_loading_error,
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
              child: ResultCard(
                result: filteredResults[index],
                showBorder: false,
              ),
            );
          },
        ),
      ),
    );
  }
}
