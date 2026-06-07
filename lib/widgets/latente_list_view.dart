import 'package:flutter/material.dart';

class LatenteListView extends StatelessWidget {
  const LatenteListView({
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 28),
    this.topSafeArea = false,
    super.key,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool topSafeArea;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: topSafeArea,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: padding,
        children: children,
      ),
    );
  }
}
