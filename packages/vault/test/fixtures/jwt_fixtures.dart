/// Placeholder JWT tokens used in share flow service tests.
///
/// The actual content of these tokens does not matter because
/// [CryptographyServiceInterface] is mocked in all tests —
/// `decodeJwtToken` is stubbed to return a controlled payload.
const validJwt = 'eyJhbGciOiJFZERTQSJ9.eyJ2YWxpZCI6dHJ1ZX0.fake_sig';
const validJwtWithPurpose =
    'eyJhbGciOiJFZERTQSJ9.eyJwdXJwb3NlIjoidGVzdCJ9.fake_sig';
const jwtWithWrongClientIdScheme =
    'eyJhbGciOiJFZERTQSJ9.eyJ3cm9uZ19zY2hlbWUiOnRydWV9.fake_sig';
const jwtWithEmptyClientId =
    'eyJhbGciOiJFZERTQSJ9.eyJlbXB0eV9jbGllbnRfaWQiOnRydWV9.fake_sig';
const jwtWithWrongResponseMode =
    'eyJhbGciOiJFZERTQSJ9.eyJ3cm9uZ19tb2RlIjoidHJ1ZX0.fake_sig';
