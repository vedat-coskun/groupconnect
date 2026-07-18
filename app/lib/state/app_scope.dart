import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Dependency-free state injection.
///
/// Wraps [AppState] (a [ChangeNotifier]) in an [InheritedNotifier] so any
/// widget can read it and rebuild on change without external packages. The
/// call sites (`AppScope.of(context)`) mirror what a `provider`/`Riverpod`
/// migration would look like, keeping this prototype UI reusable.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  /// Returns the shared [AppState].
  ///
  /// Pass [listen] = false inside callbacks / event handlers where you only
  /// want to invoke methods and not subscribe the calling widget to rebuilds.
  static AppState of(BuildContext context, {bool listen = true}) {
    final AppScope? scope =
        listen
            ? context.dependOnInheritedWidgetOfExactType<AppScope>()
            : context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
