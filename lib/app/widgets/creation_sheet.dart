import 'package:flutter/material.dart';

/// One presentation contract for all creation forms: a visible drag handle,
/// safe top inset, consistent height and no automatic keyboard focus.
Future<T?> showCreationSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  final height = MediaQuery.sizeOf(context).height * .9;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    requestFocus: false,
    constraints: BoxConstraints(
      maxWidth: 640,
      minHeight: height,
      maxHeight: height,
    ),
    builder: builder,
  );
}
