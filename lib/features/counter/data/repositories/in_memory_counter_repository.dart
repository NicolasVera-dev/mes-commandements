import '../../domain/repositories/counter_repository.dart';
import '../../domain/entities/command.dart';

class InMemoryCounterRepository implements CounterRepository {
  Command _command;

  InMemoryCounterRepository({
    required Command initialCommand,
  }) : _command = initialCommand;

  @override
  Command get command => _command;

  @override
  Command increment() {
    _command = _command.incrementProgress();
    return _command;
  }

  @override
  Command reset() {
    _command = _command.resetProgress();
    return _command;
  }
}
