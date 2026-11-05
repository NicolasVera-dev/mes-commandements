import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/resistance.dart';
import '../../domain/entities/resistance_relapse.dart';
import '../../domain/repositories/resistance_relapse_repository.dart';
import '../../domain/usecases/compute_resistance_streak_usecase.dart';
import '../state/resistance_provider.dart';
import '../utils/resistance_streak_color.dart';
import '../widgets/resistance_relapse_dialog.dart';
import 'edit_resistance_page.dart';

class ResistanceDetailPage extends StatelessWidget {
  final String resistanceId;

  const ResistanceDetailPage({
    super.key,
    required this.resistanceId,
  });

  static const _streakUseCase = ComputeResistanceStreakUseCase();

  @override
  Widget build(BuildContext context) {
    final resistance = context.watch<ResistanceProvider>().getById(resistanceId);
    final nowUtc = DateTime.now().toUtc();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          resistance?.title ?? 'Résistance',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (resistance != null)
            IconButton(
              tooltip: 'Modifier',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditResistancePage(
                      resistanceId: resistance.id,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: resistance == null
          ? Center(
              child: Text(
                'Résistance introuvable.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : _ResistanceDetailBody(
              resistance: resistance,
              nowUtc: nowUtc,
              streakUseCase: _streakUseCase,
            ),
    );
  }
}

class _ResistanceDetailBody extends StatefulWidget {
  final Resistance resistance;
  final DateTime nowUtc;
  final ComputeResistanceStreakUseCase streakUseCase;

  const _ResistanceDetailBody({
    required this.resistance,
    required this.nowUtc,
    required this.streakUseCase,
  });

  @override
  State<_ResistanceDetailBody> createState() => _ResistanceDetailBodyState();
}

class _ResistanceDetailBodyState extends State<_ResistanceDetailBody> {
  Future<void> _onRelapse(BuildContext context, Resistance r) async {
    final streak = widget.streakUseCase.execute(
      resistance: r,
      nowUtc: DateTime.now().toUtc(),
    );
    final note = await showResistanceRelapseDialog(
      context: context,
      resistanceTitle: r.title,
      currentStreakDays: streak,
    );
    if (!context.mounted || note == null) return;
    await context.read<ResistanceProvider>().recordRelapse(
          resistanceId: r.id,
          note: note.isEmpty ? null : note,
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = widget.resistance;
    final streak = widget.streakUseCase.execute(
      resistance: r,
      nowUtc: widget.nowUtc,
    );
    final streakColor = resistanceStreakColor(streakDays: streak, context: context);
    final relapseRepo = context.read<ResistanceRelapseRepository>();

    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Hero(
                    tag: 'resistance-emoji-${r.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        r.emoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (r.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      r.description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    '$streak',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: streakColor,
                        ),
                  ),
                  Text(
                    streak == 1
                        ? 'jour sans craquer'
                        : 'jours sans craquer',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Record : ${r.bestStreakDays} jour${r.bestStreakDays > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                        elevation: 2,
                        shadowColor: scheme.error.withValues(alpha: 0.45),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
                      ),
                      onPressed: () => _onRelapse(context, r),
                      child: const Text(
                        'J’ai craqué 😔',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Historique des rechutes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<ResistanceRelapse>>(
            stream: relapseRepo.watchRelapses(r.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Impossible de charger l’historique.',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              final list = snapshot.data ?? const <ResistanceRelapse>[];
              if (list.isEmpty) {
                return Text(
                  'Aucune rechute enregistrée. Continuez comme ça !',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              return Column(
                children: list.map((rel) {
                  final dateStr =
                      '${rel.relapsedAtUtc.toLocal().day}/${rel.relapsedAtUtc.toLocal().month}/${rel.relapsedAtUtc.year}';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(dateStr),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Série perdue : ${rel.previousStreakDays} jour${rel.previousStreakDays > 1 ? 's' : ''}',
                          ),
                          if (rel.note != null && rel.note!.isNotEmpty)
                            Text(rel.note!),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      );
  }
}
