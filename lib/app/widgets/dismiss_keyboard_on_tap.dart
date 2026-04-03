import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Enveloppe [child] et retire le focus (ferme le clavier) lorsque
/// l'utilisateur appuie en dehors d'un champ de saisie.
///
/// Un [GestureDetector] avec simple [onTap] reçoit souvent mal les taps au-dessus
/// d'un [ScrollView]. On utilise [Listener] + hit test : si le point d'appui
/// ne touche pas un [RenderEditable], on retire le focus — sinon on laisse le
/// champ gérer l'événement (prise de focus, sélection, etc.).
class DismissKeyboardOnTap extends StatelessWidget {
  const DismissKeyboardOnTap({
    super.key,
    required this.child,
  });

  final Widget child;

  void _onPointerDown(PointerDownEvent event) {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(
      result,
      event.position,
      event.viewId,
    );
    final bool hitEditable = result.path.any(
      (HitTestEntry e) => e.target is RenderEditable,
    );
    if (hitEditable) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      child: child,
    );
  }
}
