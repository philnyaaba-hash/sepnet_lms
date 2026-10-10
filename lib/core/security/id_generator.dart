import 'dart:math';

/// Generates client-side identifiers.
///
/// Submissions use a client-generated UUID as their primary key *and* as the
/// idempotency key sent to the LMS. The server must treat a repeated POST with
/// the same id as the same logical submission so that retries never double
/// award SkillCoins. See `docs/LMS_INTEGRATION.md`.
class IdGenerator {
  IdGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  static const String _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

  /// RFC-4122 v4 UUID derived from a cryptographically secure RNG.
  String newUuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    // Set version (4) and variant (10xx) bits.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }

  /// Short, URL-safe id, useful for local-only records.
  String newShortId([int length = 12]) {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(_alphabet[_random.nextInt(_alphabet.length)]);
    }
    return buffer.toString();
  }
}
