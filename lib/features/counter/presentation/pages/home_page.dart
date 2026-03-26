import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/command_provider.dart';
import '../../domain/entities/command.dart';
import '../widgets/create_command_sheet.dart';
import '../widgets/command_card.dart';
import '../widgets/expandable_search_bar.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/filter_chips_bar.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/account_settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Set<Frequency>? _selectedFrequencies; // null => "Toutes"
  Set<CommandStatusFilter> _selectedStatuses = <CommandStatusFilter>{};
  Set<String> _selectedTags = <String>{};
  CommandSort _sort = CommandSort.alpha;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final commandProvider = context.watch<CommandProvider>();
    final authProvider = context.watch<AuthProvider>();
    final commands = commandProvider.commandsFilteredSorted(
      frequencies: _selectedFrequencies,
      statuses: _selectedStatuses,
      tags: _selectedTags,
      sort: _sort,
    );

    final hasActiveFilters = _selectedFrequencies != null ||
        _selectedStatuses.isNotEmpty ||
        _selectedTags.isNotEmpty ||
        _sort != CommandSort.alpha;
    final canReorder = _sort == CommandSort.alpha &&
        _selectedFrequencies == null &&
        _selectedStatuses.isEmpty &&
        _selectedTags.isEmpty &&
        commandProvider.searchQuery.isEmpty;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 8,
        title: const ExpandableSearchBar(collapsedTitle: 'Mes commandements'),
        actions: [
          IconButton(
            tooltip: 'Filtres',
            onPressed: () async {
              final initial = FilterSettings(
                selectedFrequencies: _selectedFrequencies,
                selectedStatuses: _selectedStatuses,
                selectedTags: _selectedTags,
                sort: _sort,
              );

              final result = await showFilterBottomSheet(
                context: context,
                initial: initial,
                availableTags: commandProvider.availableTags,
              );

              if (result == null) return;

              setState(() {
                _selectedFrequencies = result.selectedFrequencies;
                _selectedStatuses = result.selectedStatuses;
                _selectedTags = result.selectedTags;
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
          if (!authProvider.isInitialLoading)
            IconButton(
              tooltip: authProvider.isConnected
                  ? 'Paramètres du compte'
                  : 'Connexion',
              icon: Icon(
                authProvider.isConnected
                    ? Icons.settings_outlined
                    : Icons.login_rounded,
              ),
              onPressed: () {
                if (authProvider.isConnected) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountSettingsPage(),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginPage(),
                    ),
                  );
                }
              },
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
                      selectedTags: _selectedTags,
                      sort: _sort,
                    ),
                    onFrequenciesChanged: (value) {
                      setState(() => _selectedFrequencies = value);
                    },
                    onStatusesChanged: (value) {
                      setState(() => _selectedStatuses = value);
                    },
                    onTagsChanged: (value) {
                      setState(() => _selectedTags = value);
                    },
                    onSortChanged: (value) {
                      setState(() => _sort = value);
                    },
                  ),
                if (hasActiveFilters) const SizedBox(height: 12),
                if (!canReorder)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Le réordonnancement est disponible uniquement en mode Manuel, sans filtre ni recherche.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                        'list-${commands.length}-${_selectedFrequencies?.length ?? "all"}-${_selectedStatuses.map((s) => s.name).join(",")}-${_selectedTags.join(",")}-${_sort.name}-q:${commandProvider.searchQuery}-l:${commandProvider.isInitialLoading}-e:${commandProvider.syncErrorMessage ?? ""}',
                      ),
                      child: commandProvider.isInitialLoading
                          ? const _InitialLoadingList()
                          : commandProvider.syncErrorMessage != null
                              ? Center(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 12),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline_rounded,
                                          size: 48,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .errorContainer,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          commandProvider.syncErrorMessage!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        FilledButton.tonal(
                                          onPressed: () {
                                            commandProvider.retrySync();
                                          },
                                          child: const Text('Réessayer'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : commands.isEmpty
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
                              : canReorder
                                  ? ReorderableListView.builder(
                                      padding: const EdgeInsets.only(bottom: 100),
                                      itemCount: commands.length,
                                      buildDefaultDragHandles: false,
                                      onReorderStart: (_) {
                                        setState(() => _isDragging = true);
                                      },
                                      onReorderEnd: (_) {
                                        setState(() => _isDragging = false);
                                      },
                                      proxyDecorator: (child, index, animation) {
                                        return AnimatedBuilder(
                                          animation: animation,
                                          builder: (context, _) {
                                            final t = Curves.easeOut.transform(
                                              animation.value,
                                            );
                                            return Transform.scale(
                                              scale: 1 + (0.03 * t),
                                              child: Material(
                                                elevation: 12,
                                                borderRadius: BorderRadius.circular(16),
                                                color: Colors.transparent,
                                                child: child,
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      onReorder: (oldIndex, newIndex) {
                                        commandProvider.reorderCommands(
                                          oldIndex: oldIndex,
                                          newIndex: newIndex,
                                          visibleCommands: commands,
                                        );
                                      },
                                      itemBuilder: (context, index) {
                                        final command = commands[index];
                                        return Padding(
                                          key: ValueKey(command.id),
                                          padding: const EdgeInsets.only(bottom: 14),
                                          child: AnimatedOpacity(
                                            duration:
                                                const Duration(milliseconds: 160),
                                            opacity: _isDragging ? 0.8 : 1,
                                            child: ReorderableDelayedDragStartListener(
                                              index: index,
                                              child: CommandCard(command: command),
                                            ),
                                          ),
                                        );
                                      },
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
        onPressed: authProvider.isConnected
            ? () {
                showCreateCommandSheet(
                  context: context,
                  initialFrequency: _selectedFrequencies != null &&
                          _selectedFrequencies!.length == 1
                      ? _selectedFrequencies!.first
                      : Frequency.daily,
                );
              }
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LoginPage(),
                  ),
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

class _InitialLoadingList extends StatelessWidget {
  const _InitialLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) => const _LoadingCommandCard(),
    );
  }
}

class _LoadingCommandCard extends StatefulWidget {
  const _LoadingCommandCard();

  @override
  State<_LoadingCommandCard> createState() => _LoadingCommandCardState();
}

class _LoadingCommandCardState extends State<_LoadingCommandCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final base = Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.05 + (0.05 * t)),
          scheme.surfaceContainerHighest,
        );
        final block = scheme.onSurface.withValues(alpha: 0.08 + (0.06 * t));

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: block,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: block,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 12,
                width: 180,
                decoration: BoxDecoration(
                  color: block,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: block,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
