import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/command_provider.dart';
import '../../domain/entities/command.dart';
import '../widgets/create_command_sheet.dart';
import '../widgets/command_card.dart';
import '../widgets/expandable_search_bar.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/filter_chips_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Set<Frequency>? _selectedFrequencies; // null => "Toutes"
  Set<CommandStatusFilter> _selectedStatuses = <CommandStatusFilter>{};
  CommandSort _sort = CommandSort.alpha;

  @override
  Widget build(BuildContext context) {
    final commandProvider = context.watch<CommandProvider>();
    final commands = commandProvider.commandsFilteredSorted(
      frequencies: _selectedFrequencies,
      statuses: _selectedStatuses,
      sort: _sort,
    );

    final hasActiveFilters = _selectedFrequencies != null ||
        _selectedStatuses.isNotEmpty ||
        _sort != CommandSort.alpha;

    final listKey = commands.map((c) => c.id).join('-');

    return Scaffold(
      appBar: AppBar(
        title: const ExpandableSearchBar(collapsedTitle: 'Mes commandements'),
        actions: [
          IconButton(
            tooltip: 'Filtres',
            onPressed: () async {
              final initial = FilterSettings(
                selectedFrequencies: _selectedFrequencies,
                selectedStatuses: _selectedStatuses,
                sort: _sort,
              );

              final result = await showFilterBottomSheet(
                context: context,
                initial: initial,
              );

              if (result == null) return;

              setState(() {
                _selectedFrequencies = result.selectedFrequencies;
                _selectedStatuses = result.selectedStatuses;
                _sort = result.sort;
              });
            },
            icon: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.filter_list_rounded),
                if (hasActiveFilters)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: _ActiveDot(),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.2),
                    Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (hasActiveFilters)
                  FilterChipsBar(
                    current: FilterSettings(
                      selectedFrequencies: _selectedFrequencies,
                      selectedStatuses: _selectedStatuses,
                      sort: _sort,
                    ),
                    onFrequenciesChanged: (value) {
                      setState(() => _selectedFrequencies = value);
                    },
                    onStatusesChanged: (value) {
                      setState(() => _selectedStatuses = value);
                    },
                    onSortChanged: (value) {
                      setState(() => _sort = value);
                    },
                  ),
                if (hasActiveFilters) const SizedBox(height: 12),
                _ProgressSummaryCard(commands: commandProvider.commands),
                const SizedBox(height: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      );
                      return FadeTransition(opacity: curved, child: child);
                    },
                    child: KeyedSubtree(
                      key: ValueKey<String>(
                        'list-$listKey-${_selectedFrequencies?.length ?? "all"}-${_selectedStatuses.map((s) => s.name).join(",")}-${_sort.name}-q:${commandProvider.searchQuery}',
                      ),
                      child: commands.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    commandProvider.searchQuery.isNotEmpty
                                        ? Icons.search_off_rounded
                                        : Icons.hourglass_empty_rounded,
                                    size: 48,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Aucun commandement trouvé',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 100),
                              itemCount: commands.length,
                              separatorBuilder: (context, index) => SizedBox(
                                height: 14,
                                key: ValueKey(index),
                              ),
                              itemBuilder: (context, index) {
                                final command = commands[index];
                                return CommandCard(command: command);
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showCreateCommandSheet(
            context: context,
            initialFrequency: _selectedFrequencies != null &&
                    _selectedFrequencies!.length == 1
                ? _selectedFrequencies!.first
                : Frequency.daily,
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau commandement'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _ActiveDot extends StatelessWidget {
  const _ActiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ProgressSummaryCard extends StatelessWidget {
  final List<Command> commands;

  const _ProgressSummaryCard({required this.commands});

  @override
  Widget build(BuildContext context) {
    if (commands.isEmpty) return const SizedBox.shrink();

    final total = commands.length;
    final completed = commands.where((c) => c.isCompleted()).length;
    final ratio = total > 0 ? completed / total : 0.0;
    final percent = (ratio * 100).round();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed / $total commandement${total != 1 ? 's' : ''} complété${completed != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '$percent %',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: completed == total && total > 0
                          ? Colors.greenAccent.shade200
                          : Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            tween: Tween<double>(begin: 0, end: ratio),
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                valueColor: AlwaysStoppedAnimation<Color>(
                  completed == total && total > 0
                      ? Colors.greenAccent.shade200
                      : Theme.of(context).colorScheme.primary,
                ),
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              );
            },
          ),
        ],
      ),
    );
  }
}
