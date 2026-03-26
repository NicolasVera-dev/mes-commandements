import 'command.dart';

class AutoResetReport {
  final int total;
  final Map<Frequency, int> byFrequency;

  const AutoResetReport({
    required this.total,
    required this.byFrequency,
  });

  const AutoResetReport.empty()
      : total = 0,
        byFrequency = const <Frequency, int>{};

  bool get hasResets => total > 0;
}
