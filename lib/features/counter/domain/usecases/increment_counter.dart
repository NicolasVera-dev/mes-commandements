import '../repositories/counter_repository.dart';
import '../entities/command.dart';

class IncrementCounterUseCase {
  final CounterRepository repository;

  IncrementCounterUseCase({required this.repository});

  Command call() => repository.increment();
}
