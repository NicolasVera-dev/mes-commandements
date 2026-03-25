import '../../domain/entities/command.dart';

class CounterState {
  final Command command;

  const CounterState({required this.command});

  CounterState copyWith({Command? command}) => CounterState(
        command: command ?? this.command,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CounterState && other.command == command;
  }

  @override
  int get hashCode => command.hashCode;
}
