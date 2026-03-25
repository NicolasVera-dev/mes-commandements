import '../repositories/counter_repository.dart';
import '../entities/command.dart';

class ResetCounterUseCase {
  final CounterRepository repository;

  ResetCounterUseCase({required this.repository});

  Command call() => repository.reset();
}
