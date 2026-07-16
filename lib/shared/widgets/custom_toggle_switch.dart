import 'package:flutter/material.dart';

class CustomToggleSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<CustomToggleSwitch> createState() => _CustomToggleSwitchState();
}

class _CustomToggleSwitchState extends State<CustomToggleSwitch> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              top: 2,
              bottom: 2,
              left: widget.value ? 26 : 2,
              right: widget.value ? 2 : 26,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.value 
                      ? Colors.white 
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
