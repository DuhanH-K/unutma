import 'package:flutter/material.dart';

import 'shared.dart';

/// Visual timing is independent of ads/network/platform initialization.
/// After 1.8s the application (including its bounded error/retry UI) is visible.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key, required this.child, this.onComplete});
  final Widget child;
  final VoidCallback? onComplete;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {});
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onComplete?.call();
          });
        }
      });
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isCompleted) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(child: IgnorePointer(child: widget.child)),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final logo = Curves.easeOutCubic.transform((t / .23).clamp(0, 1));
            final settle = Curves.easeOutCubic.transform(
              ((t - .23) / .38).clamp(0, 1),
            );
            final text = Curves.easeOut.transform(
              ((t - .61) / .28).clamp(0, 1),
            );
            final exit = Curves.easeInOut.transform(
              ((t - .89) / .11).clamp(0, 1),
            );
            return Opacity(
              opacity: 1 - exit,
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: logo,
                        child: Transform.scale(
                          scale: .88 + .16 * logo - .04 * settle,
                          child: const BrandMark(size: 88),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Opacity(
                        opacity: text,
                        child: Transform.translate(
                          offset: Offset(0, 8 * (1 - text)),
                          child: Text(
                            'UNUTMA',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 4,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
