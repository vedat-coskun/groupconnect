import 'package:flutter/material.dart';

/// On-screen numeric keypad used for phone-number and OTP entry (matching the
/// flow deck's numpad-driven auth). Text keyboards are intentionally avoided
/// here.
class Numpad extends StatelessWidget {
  const Numpad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, Widget? child}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap ?? () => onDigit(label),
              child: SizedBox(
                height: 60,
                child: Center(
                  child:
                      child ??
                      Text(
                        label,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget row(List<Widget> children) => Row(children: children);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([key('1'), key('2'), key('3')]),
        row([key('4'), key('5'), key('6')]),
        row([key('7'), key('8'), key('9')]),
        row([
          const Expanded(child: SizedBox()),
          key('0'),
          key(
            '',
            onTap: onBackspace,
            child: const Icon(Icons.backspace_outlined),
          ),
        ]),
      ],
    );
  }
}
