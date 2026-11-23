import 'package:flutter/material.dart';

import '../../domain/usecases/build_cycle_summary_usecase.dart';
import '../../../../app/localization/localization.dart';

class SummaryCard extends StatelessWidget {
  final CycleSummary summary;

  const SummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(child: Text(context.l10n.cyclesReussis(summary.success))),
            Expanded(child: Text(context.l10n.cyclesEchoues(summary.failed))),
            Expanded(
              child: Text(
                context.l10n.completion(summary.completionRate),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
