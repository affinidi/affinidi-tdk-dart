import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';

/// A mocktail mock for [RevocationList2020Verifier].
///
/// Use this to stub [verify] without performing real network I/O.
class MockRevocationVerifier extends Mock implements RevocationList2020Verifier {}
