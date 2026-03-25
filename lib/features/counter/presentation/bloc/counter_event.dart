sealed class CounterEvent {
  const CounterEvent();
}

class IncrementPressed extends CounterEvent {
  const IncrementPressed();
}

class ResetPressed extends CounterEvent {
  const ResetPressed();
}
