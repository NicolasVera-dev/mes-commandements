import 'package:flutter/material.dart';

class PageTitle extends StatelessWidget {
  final String title;
  const PageTitle(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    title,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.titleMedium
        ?.copyWith(height: 1.12, fontWeight: FontWeight.w700),
  );
}
