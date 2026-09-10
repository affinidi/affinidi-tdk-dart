import 'package:affinidi_tdk_common/affinidi_tdk_common.dart';

class FakeLogger extends Logger {
  FakeLogger() : super(Environment.getEnvironmentConfig(EnvironmentType.local));

  final List<String> warnings = [];

  @override
  void warning(Object? message, {String? component}) {
    warnings.add(message.toString());
  }
}
