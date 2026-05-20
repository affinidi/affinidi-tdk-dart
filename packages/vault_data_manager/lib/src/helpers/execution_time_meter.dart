// ignore_for_file: avoid_print

/// Utility class for measuring execution time of code blocks,
/// with a label for identification.
class ExecutionTimeMeter {
  /// Creates an instance of [ExecutionTimeMeter] with the given label.
  ExecutionTimeMeter(this._label);

  final String _label;
  final _stopwatch = Stopwatch();

  /// Starts the stopwatch to begin measuring execution time.
  void start() => _stopwatch.start();

  /// Stops the stopwatch and prints the elapsed time with the associated label.
  void stop() {
    _stopwatch.stop();
    print('[MEASURE] - $_label took ${_stopwatch.elapsedMilliseconds}ms');
  }
}
