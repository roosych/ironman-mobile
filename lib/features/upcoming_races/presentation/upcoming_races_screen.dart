import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ironman_mobile/l10n/app_localizations.dart';
import 'package:ironman_mobile/shared/utils/error_handler.dart';
import 'package:ironman_mobile/shared/widgets/upcoming_race_card.dart';
import 'package:ironman_mobile/shared/widgets/add_upcoming_race_bottom_sheet.dart';
import '../application/upcoming_races_notifier.dart';
import '../application/upcoming_races_state.dart';

class UpcomingRacesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const UpcomingRacesScreen({super.key, this.onBack});

  @override
  ConsumerState<UpcomingRacesScreen> createState() =>
      _UpcomingRacesScreenState();
}

class _UpcomingRacesScreenState extends ConsumerState<UpcomingRacesScreen> {
  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    // Загружаем гонки после построения виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUpcomingRaces();
      }
    });
  }

  void _loadUpcomingRaces() {
    ref.read(globalUpcomingRacesProvider.notifier).loadUpcomingRaces(
      onlyFuture: true, // Только будущие гонки
    );
  }

  Future<void> _refreshUpcomingRaces() async {
    try {
      await ref.read(globalUpcomingRacesProvider.notifier).refreshUpcomingRaces();
    } catch (e) {
      // Ошибка уже обработана в провайдере, алерт покажется через listener
    }
  }

  void _showErrorSafely(dynamic error) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ErrorHandler.showError(context, error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(globalUpcomingRacesProvider);
    final localizations = AppLocalizations.of(context)!;

    // Слушаем ошибки
    ref.listen<UpcomingRacesState>(globalUpcomingRacesProvider, (previous, next) {
      if (!mounted) return;
      if (next.hasError && next.error != null) {
        final error = next.error!;
        if (previous?.error != error && _lastShownError != error) {
          _lastShownError = error;
          _showErrorSafely(error);
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
          localizations.home_upcoming_races,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
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
      body: _buildBody(state, localizations),
    );
  }

  Widget _buildBody(UpcomingRacesState state, AppLocalizations localizations) {
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
                onPressed: _loadUpcomingRaces,
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
          localizations.home_no_upcoming_races,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshUpcomingRaces,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
        itemCount: state.races.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: UpcomingRaceCard(race: state.races[index]),
          );
        },
      ),
    );
  }
}

