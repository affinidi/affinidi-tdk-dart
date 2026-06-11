import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';

/// A mocktail mock for [VerifiableCredential].
///
/// Use this when you need to stub specific fields (e.g. [validUntil],
/// [validFrom]) rather than parsing a full JSON credential.
class MockVerifiableCredential extends Mock implements VerifiableCredential {}
