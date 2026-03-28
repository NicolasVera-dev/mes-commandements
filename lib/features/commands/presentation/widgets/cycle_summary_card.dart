import 'package:flutter/material.dart';

import '../../domain/usecases/build_cycle_summary_usecase.dart';

class SummaryCard extends StatelessWidget {
  final CycleSummary summary;

  const SummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(child: Text('🟢 ${summary.success} cycles réussis')),
            Expanded(child: Text('🔴 ${summary.failed} cycles échoués')),
            Expanded(
              child: Text(
                'Complétion: ${summary.completionRate}%',
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
