import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';
import 'package:ironman_mobile/shared/widgets/upcoming_race_card.dart';
import 'package:ironman_mobile/shared/widgets/add_upcoming_race_bottom_sheet.dart';
import '../application/upcoming_races_notifier.dart';
import '../application/upcoming_races_state.dart';
import '../../auth/application/auth_notifier.dart';

class MyRacesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const MyRacesScreen({super.key, this.onBack});

  @override
  ConsumerState<MyRacesScreen> createState() => _MyRacesScreenState();
}

class _MyRacesScreenState extends ConsumerState<MyRacesScreen> {
  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    // Загружаем все гонки (будущие и прошедшие) после построения виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMyRaces();
      }
    });
  }

  void _loadMyRaces() {
    final authState = ref.read(authProvider);
    final user = authState.user;
    int? userProfileId;
    if (user?.profile is Map<String, dynamic>) {
      final profile = user!.profile as Map<String, dynamic>;
      userProfileId = profile['id'] as int?;
    }

    // Если профиль не найден — очищаем список и выходим
    if (userProfileId == null) {
      ref.read(myRacesProvider.notifier).setEmpty();
      return;
    }

    // Используем отдельный провайдер для "Мои гонки"
    ref
        .read(myRacesProvider.notifier)
        .loadUpcomingRaces(
          userProfileId: userProfileId,
          onlyFuture: false, // Все гонки, включая прошедшие
        );
  }

  Future<void> _refreshMyRaces() async {
    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      int? userProfileId;
      if (user?.profile is Map<String, dynamic>) {
        final profile = user!.profile as Map<String, dynamic>;
        userProfileId = profile['id'] as int?;
      }

      if (userProfileId == null) {
        ref.read(myRacesProvider.notifier).setEmpty();
        return;
      }

      await ref
          .read(myRacesProvider.notifier)
          .refreshUpcomingRaces(
            userProfileId: userProfileId,
            onlyFuture: false, // Все гонки, включая прошедшие
          );
    } catch (e) {
      // Ошибка уже обработана в провайдере, алерт покажется через listener
    }
  }

  void _showErrorSafely(dynamic error, BuildContext context) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!context.mounted) return;
      ErrorHandler.showError(context, error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myRacesProvider);
    final localizations = AppLocalizations.of(context)!;

    // Слушаем ошибки
    ref.listen<UpcomingRacesState>(myRacesProvider, (previous, next) {
      if (!mounted) return;
      if (next.hasError && next.error != null) {
        final error = next.error!;
        if (previous?.error != error && _lastShownError != error) {
          _lastShownError = error;
          _showErrorSafely(error, context);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Theme.of(context).colorScheme.onSurface,
            size: 24,
          ),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          localizations.my_races_title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddUpcomingRaceBottomSheet(context);
          // Обновление списка произойдет автоматически через провайдер в BottomSheet
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(context, state, localizations),
    );
  }

  Widget _buildBody(
    BuildContext context,
    UpcomingRacesState state,
    AppLocalizations localizations,
  ) {
    if (state.isLoading && state.races.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.races.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.error ?? localizations.common_loading_error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMyRaces,
                child: Text(localizations.common_retry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Text(
          localizations.my_races_no_races,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMyRaces,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
        itemCount: state.races.length,
        itemBuilder: (context, index) {
          final race = state.races[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: UpcomingRaceCard(race: race, showAthleteName: false),
          );
        },
      ),
    );
  }
}
