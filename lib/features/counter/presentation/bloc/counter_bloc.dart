import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/increment_counter.dart';
import '../../domain/usecases/reset_counter.dart';
import '../../domain/entities/command.dart';
import 'counter_event.dart';
import 'counter_state.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  final IncrementCounterUseCase incrementCounterUseCase;
  final ResetCounterUseCase resetCounterUseCase;

  CounterBloc({
    required this.incrementCounterUseCase,
    required this.resetCounterUseCase,
    required Command initialCommand,
  }) : super(CounterState(command: initialCommand)) {
    on<IncrementPressed>((event, emit) {
      final newValue = incrementCounterUseCase();
      emit(state.copyWith(command: newValue));
    });

    on<ResetPressed>((event, emit) {
      final newValue = resetCounterUseCase();
      emit(state.copyWith(command: newValue));
    });
  }
}
