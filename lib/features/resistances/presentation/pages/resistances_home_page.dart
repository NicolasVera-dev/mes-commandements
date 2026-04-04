import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/pages/account_settings_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../commands/presentation/widgets/expandable_search_bar.dart';
import '../../domain/usecases/filter_and_sort_resistances_usecase.dart';
import '../state/resistance_provider.dart';
import '../widgets/create_resistance_sheet.dart';
import '../widgets/resistance_card.dart';
import '../widgets/resistance_filter_bottom_sheet.dart';
import '../widgets/resistance_filter_chips_bar.dart';
import '../../../../app/command_card_display_mode.dart';
import '../../../../app/command_card_layout_service.dart';

class ResistancesHomePage extends StatefulWidget {
  const ResistancesHomePage({super.key});

  @override
  State<ResistancesHomePage> createState() => _ResistancesHomePageState();
}

class _ResistancesHomePageState extends State<ResistancesHomePage> {
  bool _isDragging = false;
  Set<String> _selectedTags = <String>{};
  ResistanceSort _sort = ResistanceSort.alpha;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResistanceProvider>();
    final auth = context.watch<AuthProvider>();
    final cardListGap = context.select<CommandCardLayoutService, double>(
      (s) => s.displayMode == CommandCardDisplayMode.compact ? 8 : 14,
    );
    final list = provider.resistancesFilteredSorted(
      tags: _selectedTags,
      sort: _sort,
    );

    final hasActiveFilters =
        _selectedTags.isNotEmpty || _sort != ResistanceSort.alpha;
    final canReorder = _sort == ResistanceSort.alpha &&
        _selectedTags.isEmpty &&
        provider.searchQuery.isEmpty;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 8,
        title: ExpandableSearchBar(
          collapsedTitle: 'Mes résistances',
          searchQuery: provider.searchQuery,
          onSearchQueryChanged: provider.setSearchQuery,
          hintText: 'Rechercher une résistance…',
        ),
        actions: [
          IconButton(
            tooltip: 'Filtres',
            onPressed: () async {
              final initial = ResistanceFilterSettings(
                selectedTags: _selectedTags,
                sort: _sort,
              );
              final result = await showResistanceFilterBottomSheet(
                context: context,
                initial: initial,
                availableTags: provider.availableTags,
              );
              if (result == null) return;
              setState(() {
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
          if (!auth.isInitialLoading)
            IconButton(
              tooltip: auth.isConnected
                  ? 'Paramètres du compte'
                  : 'Connexion',
              icon: Icon(
                auth.isConnected
                    ? Icons.settings_outlined
                    : Icons.login_rounded,
              ),
              onPressed: () {
                if (auth.isConnected) {
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
                  ResistanceFilterChipsBar(
                    current: ResistanceFilterSettings(
                      selectedTags: _selectedTags,
                      sort: _sort,
                    ),
                    onTagsChanged: (tags) =>
                        setState(() => _selectedTags = tags),
                    onSortChanged: (s) => setState(() => _sort = s),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                        'rlist-${list.length}-${_selectedTags.join(",")}-${_sort.name}-q:${provider.searchQuery}-l:${provider.isInitialLoading}-e:${provider.syncErrorMessage ?? ""}',
                      ),
                      child: provider.isInitialLoading
                          ? const Center(child: CircularProgressIndicator())
                          : provider.syncErrorMessage != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        size: 48,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        provider.syncErrorMessage!,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton.tonal(
                                        onPressed: () => provider.retrySync(),
                                        child: const Text('Réessayer'),
                                      ),
                                    ],
                                  ),
                                )
                              : provider.resistances.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.shield_outlined,
                                            size: 48,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Aucune résistance pour le moment.\nAjoutez ce que vous voulez arrêter !',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    )
                                  : list.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                provider.searchQuery.isNotEmpty
                                                    ? Icons.search_off_rounded
                                                    : Icons.filter_alt_off_rounded,
                                                size: 48,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Aucune résistance trouvée',
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
                                              padding: const EdgeInsets.only(
                                                bottom: 100,
                                              ),
                                              itemCount: list.length,
                                              buildDefaultDragHandles: false,
                                              onReorderStart: (_) => setState(
                                                () => _isDragging = true,
                                              ),
                                              onReorderEnd: (_) => setState(
                                                () => _isDragging = false,
                                              ),
                                              proxyDecorator:
                                                  (child, index, animation) {
                                                final proxyRadius =
                                                    cardListGap <= 8 ? 12.0 : 16.0;
                                                return AnimatedBuilder(
                                                  animation: animation,
                                                  builder: (context, _) {
                                                    final t =
                                                        Curves.easeOut.transform(
                                                      animation.value,
                                                    );
                                                    return Transform.scale(
                                                      scale: 1 + (0.03 * t),
                                                      child: Material(
                                                        elevation: 12,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          proxyRadius,
                                                        ),
                                                        color: Colors.transparent,
                                                        child: child,
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              onReorder: (oldIndex, newIndex) {
                                                provider.reorderResistances(
                                                  oldIndex: oldIndex,
                                                  newIndex: newIndex,
                                                  visible: list,
                                                );
                                              },
                                              itemBuilder: (context, index) {
                                                final r = list[index];
                                                return Padding(
                                                  key: ValueKey(r.id),
                                                  padding: EdgeInsets.only(
                                                    bottom: cardListGap,
                                                  ),
                                                  child: AnimatedOpacity(
                                                    duration: const Duration(
                                                      milliseconds: 160,
                                                    ),
                                                    opacity:
                                                        _isDragging ? 0.85 : 1,
                                                    child:
                                                        ReorderableDelayedDragStartListener(
                                                      index: index,
                                                      child: ResistanceCard(
                                                        resistance: r,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : ListView.separated(
                                              padding: const EdgeInsets.only(
                                                bottom: 100,
                                              ),
                                              itemCount: list.length,
                                              separatorBuilder:
                                                  (context, index) => SizedBox(
                                                height: cardListGap,
                                                key: ValueKey(index),
                                              ),
                                              itemBuilder: (context, index) {
                                                return ResistanceCard(
                                                  resistance: list[index],
                                                );
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
        onPressed: auth.isConnected
            ? () => showCreateResistanceSheet(context: context)
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LoginPage(),
                  ),
                );
              },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle résistance'),
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
