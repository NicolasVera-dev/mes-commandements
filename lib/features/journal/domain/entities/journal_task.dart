import 'journal_day.dart';

/// An interval of daily commitments. An open interval carries automatically.
/// Closing an interval preserves past scores when the task is replanned.
class JournalPlan {
  final JournalDay start;
  final JournalDay? end;
  final bool carryForward;

  JournalPlan({required this.start, this.end, this.carryForward = true}) {
    if (end != null && end!.isBefore(start)) {
      throw ArgumentError('Invalid plan');
    }
  }

  bool contains(JournalDay day) =>
      !day.isBefore(start) &&
      (end == null || !day.isAfter(end!)) &&
      (carryForward || day == start);
}

class JournalTask {
  final String id;
  final String title;
  final bool priority;
  final double order;
  final List<JournalPlan> plans;
  final JournalDay originalDay;
  final JournalDay? completedDay;
  final JournalDay? removedDay;

  JournalTask({
    required this.id,
    required String title,
    required List<JournalPlan> plans,
    this.priority = false,
    this.order = 0,
    JournalDay? originalDay,
    this.completedDay,
    this.removedDay,
  }) : title = title.trim(),
       plans = List.unmodifiable(plans),
       originalDay =
           originalDay ??
           (plans.isNotEmpty
               ? plans.first.start
               : throw ArgumentError('Empty plan')) {
    if (id.isEmpty ||
        !order.isFinite ||
        this.title.isEmpty ||
        this.title.length > 200 ||
        plans.isEmpty ||
        plans.length > 500) {
      throw ArgumentError('Invalid task');
    }
    for (var i = 1; i < plans.length; i++) {
      final previous = plans[i - 1];
      if (previous.end == null || !previous.end!.isBefore(plans[i].start)) {
        throw ArgumentError('Overlapping plans');
      }
    }
    if (completedDay != null && !plans.any((p) => p.contains(completedDay!))) {
      throw ArgumentError('Completion outside plan');
    }
  }

  bool get carryForward => plans.last.carryForward;
  bool isNonReportableOn(JournalDay day) =>
      plans.any((p) => p.contains(day) && !p.carryForward);

  JournalDay get scheduledDay => plans.last.start;

  bool appearsOn(JournalDay day) =>
      (removedDay == null || day.isBefore(removedDay!)) &&
      (completedDay == null || !day.isAfter(completedDay!)) &&
      plans.any((p) => p.contains(day));

  bool completedOn(JournalDay day) => completedDay == day;

  int lateDaysOn(JournalDay day) {
    final plan = plans.where((p) => p.contains(day)).firstOrNull;
    return plan == null ? 0 : day.daysSince(plan.start);
  }

  JournalTask edit({String? title, bool? priority, double? order}) =>
      JournalTask(
        id: id,
        title: title ?? this.title,
        priority: priority ?? this.priority,
        order: order ?? this.order,
        plans: plans,
        originalDay: originalDay,
        completedDay: completedDay,
        removedDay: removedDay,
      );

  JournalTask complete(JournalDay today, {required bool done}) {
    if (removedDay != null ||
        !appearsOn(today) ||
        (completedDay != null && completedDay != today)) {
      throw StateError('Only today can be completed or reopened');
    }
    return JournalTask(
      id: id,
      title: title,
      priority: priority,
      order: order,
      plans: plans,
      originalDay: originalDay,
      completedDay: done ? today : null,
    );
  }

  JournalTask remove(JournalDay today) => JournalTask(
    id: id,
    title: title,
    priority: priority,
    order: order,
    plans: plans,
    originalDay: originalDay,
    completedDay: completedDay,
    removedDay: today,
  );

  JournalTask restore() => JournalTask(
    id: id,
    title: title,
    priority: priority,
    order: order,
    plans: plans,
    originalDay: originalDay,
    completedDay: completedDay,
  );

  JournalTask withCarryForward(bool value, JournalDay today) {
    if (value == carryForward) return this;
    if (completedDay != null || removedDay != null) {
      throw StateError('Task is closed');
    }
    final target = scheduledDay.isAfter(today) ? scheduledDay : today;
    final replanned = reschedule(target, today);
    return JournalTask(
      id: id,
      title: title,
      priority: priority,
      order: order,
      originalDay: originalDay,
      plans: [
        ...replanned.plans.take(replanned.plans.length - 1),
        JournalPlan(start: target, carryForward: value),
      ],
    );
  }

  JournalTask reschedule(JournalDay target, JournalDay today) {
    if (target.isBefore(today) || completedDay != null || removedDay != null) {
      throw StateError('Invalid reschedule');
    }
    final history = <JournalPlan>[];
    for (final plan in plans) {
      if (!plan.start.isBefore(today)) continue;
      history.add(
        JournalPlan(
          start: plan.start,
          carryForward: plan.carryForward,
          end: plan.end != null && plan.end!.isBefore(today)
              ? plan.end
              : today.add(-1),
        ),
      );
    }
    return JournalTask(
      id: id,
      title: title,
      priority: priority,
      order: order,
      originalDay: originalDay,
      plans: [
        ...history,
        JournalPlan(start: target, carryForward: carryForward),
      ],
    );
  }
}
