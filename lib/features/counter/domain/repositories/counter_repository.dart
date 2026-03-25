import '../entities/command.dart';

abstract class CounterRepository {
  Command get command;

  /// Returns the updated command.
  Command increment();

  /// Returns the updated command.
  Command reset();
}
