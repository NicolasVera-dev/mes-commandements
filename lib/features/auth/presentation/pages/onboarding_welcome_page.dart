import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/localization.dart';
import '../widgets/onboarding/onboarding_brand_header.dart';

/// Accueil hors-ligne pour utilisateurs non connectés (aucune persistance « déjà vu »).
class OnboardingWelcomePage extends StatefulWidget {
  final VoidCallback onCommencer;
  final bool isActive;

  const OnboardingWelcomePage({
    super.key,
    required this.onCommencer,
    this.isActive = true,
  });

  @override
  State<OnboardingWelcomePage> createState() => _OnboardingWelcomePageState();
}

class _OnboardingWelcomePageState extends State<OnboardingWelcomePage>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  int _pageIndex = 0;
  static const _slideDelay = Duration(seconds: 8);
  Timer? _timer;
  bool _foreground = true;
  bool _manualAccessibility = false;
  bool _transitioning = false;
  bool _interacting = false;

  int get _slideCount => _slides.length + 1;
  bool get _canAdvance =>
      widget.isActive &&
      _foreground &&
      !_manualAccessibility &&
      !_transitioning &&
      !_interacting;

  List<_SlideData> _localizedSlides(AppLocalizations strings) => [
    for (final data in _slides)
      _SlideData(
        icon: data.icon,
        title: strings.systemMessage(data.title),
        body: strings.systemMessage(data.body),
        quote: data.quote == null ? null : strings.systemMessage(data.quote!),
      ),
    _SlideData(
      icon: Icons.menu_book_rounded,
      title: strings.onboardingJournalTitle,
      body: strings.onboardingJournalBody,
      quote: strings.onboardingJournalQuote,
    ),
  ];

  static const _slides = <_SlideData>[
    _SlideData(
      icon: Icons.waving_hand_rounded,
      title: 'Bienvenue dans Rituel',
      body: 'Construis des routines qui te ressemblent et défais celles qui te freinent. Un seul endroit pour avancer à ton rythme.',
      quote: 'Nous sommes le reflet de nos habitudes',
    ),
    _SlideData(
      icon: Icons.track_changes_rounded,
      title: 'Suis ta progression',
      body: 'Fixe des objectifs par jour, semaine, mois ou année. Visualise ta régularité, célèbre tes séries et identifie où tu peux faire mieux.',
      quote: "Ce n'est pas l'intensité qui compte, c'est la constance.",
    ),
    _SlideData(
      icon: Icons.shield_rounded,
      title: 'Face aux addictions',
      body: "Alcool, tabac, écrans ou jeux… Pose un nom sur ce qui te tient, note tes jours de liberté, et reprends le fil si tu trébuches.",
      quote: "La chute n'est pas un échec. L'échec, c'est de rester là où on est tombé.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _manualAccessibility =
        MediaQuery.accessibleNavigationOf(context) ||
        MediaQuery.disableAnimationsOf(context);
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant OnboardingWelcomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncTimer(reset: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _foreground = state == AppLifecycleState.resumed;
    });
    _syncTimer();
  }

  void _syncTimer({bool reset = false}) {
    if (reset || !_canAdvance) {
      _timer?.cancel();
      _timer = null;
    }
    if (!_canAdvance || (_timer?.isActive ?? false)) return;
    _timer = Timer(_slideDelay, () {
      _timer = null;
      unawaited(_advance());
    });
  }

  Future<void> _advance() async {
    if (!_canAdvance || !_pageController.hasClients) return;
    _transitioning = true;
    _syncTimer();
    try {
      await _pageController.animateToPage(
        (_pageController.page?.round() ?? 0) + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } finally {
      if (mounted) {
        _transitioning = false;
        _syncTimer(reset: true);
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() => _pageIndex = index % _slideCount);
    _syncTimer(reset: true);
  }

  void _setInteracting(bool value) {
    _interacting = value;
    _syncTimer(reset: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  String _semanticLabelForSlide(
    _SlideData data, {
    required int page,
    required int total,
  }) {
    final base = context.l10n.pageSur2(page, total, data.title, data.body);
    if (data.quote == null || data.quote!.isEmpty) return base;
    return '$base. ${data.quote!}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final slides = _localizedSlides(context.l10n);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (kIsWeb) return;
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                scheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const OnboardingBrandHeader(),
                Expanded(
                  child: Listener(
                    onPointerDown: (_) => _setInteracting(true),
                    onPointerUp: (_) => _setInteracting(false),
                    onPointerCancel: (_) => _setInteracting(false),
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (_, index) {
                        final page = index % slides.length;
                        return _OnboardingSlide(
                          data: slides[page],
                          semanticPageLabel: _semanticLabelForSlide(
                            slides[page],
                            page: page + 1,
                            total: slides.length,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _PageDots(
                  count: slides.length,
                  index: _pageIndex,
                  scheme: scheme,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Semantics(
                    button: true,
                    label: context.l10n.commencerDesMaintenant,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        disabledBackgroundColor: scheme.onSurface.withValues(
                          alpha: 0.12,
                        ),
                        disabledForegroundColor: scheme.onSurface.withValues(
                          alpha: 0.38,
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                      ),
                      onPressed: () {
                        _timer?.cancel();
                        widget.onCommencer();
                      },
                      child: Text(
                        context.l10n.commencerDesMaintenant,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.15,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String body;
  final String? quote;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.body,
    this.quote,
  });
}

class _OnboardingSlide extends StatelessWidget {
  final _SlideData data;
  final String semanticPageLabel;

  const _OnboardingSlide({required this.data, required this.semanticPageLabel});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: semanticPageLabel,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 32).clamp(0, double.infinity),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: Icon(data.icon, size: 88, color: scheme.primary),
                ),
                const SizedBox(height: 32),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data.body,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (data.quote != null && data.quote!.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    '« ${data.quote!} »',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int index;
  final ColorScheme scheme;

  const _PageDots({
    required this.count,
    required this.index,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.pageSur(index + 1, count),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final selected = i == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: selected ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: selected
                    ? scheme.primary
                    : scheme.outlineVariant.withValues(alpha: 0.8),
              ),
            ),
          );
        }),
      ),
    );
  }
}
