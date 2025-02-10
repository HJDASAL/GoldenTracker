import 'package:flutter/material.dart';

class SideFieldIcon extends StatelessWidget {
  const SideFieldIcon({super.key, required this.icon, this.onHover, this.onTap});

  final Widget icon;
  final void Function()? onTap;
  final void Function(bool)? onHover;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.horizontal(
        right: Radius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        onHover: onHover,
        child: icon,
      ),
    );
  }
}
