// Fixtures generated with OpenSSL secp256k1 key + dart_jsonwebtoken ES256K
// signing. Test-only — do NOT use these keys in production.
const testDid = 'did:key:zQ3shmBVsvSAHDWX3zhAk9h4ikFh8BFz9PhtSmyy5Sp5ZRejB';

// Valid JWT (exp: 9999999999 — year 2286)
const validJwt =
    'eyJhbGciOiJFUzI1NksiLCJ0eXAiOiJKV1QifQ'
    '.eyJzdWIiOiJ0ZXN0IiwiaWF0IjoxNzc3OTcwNTg4LCJleHAiOjk5OTk5OTk5OTl9'
    '.CBvlgV06vsuIOPRaaDfx_KAYHpTsZj3PrGLlHfuU1pEYY'
    'P5xwK1KTIhvCaQxxQzVeeeZCslnKGUnJI2X2h8IrQ';

// Expired JWT (exp: 1000000001 — year 2001)
const expiredJwt =
    'eyJhbGciOiJFUzI1NksiLCJ0eXAiOiJKV1QifQ'
    '.eyJzdWIiOiJ0ZXN0IiwiaWF0IjoxNzc3OTcwNTg4LCJleHAiOjEwMDAwMDAwMDF9'
    '.PsEegrkCB5eWVZiBiNBB2buy8jFG18cvhVIo1TH2lxO'
    'WqQjt40qQNxIyrN55NUGC9hWBZyJOeSG7eImKbsVjzQ';
