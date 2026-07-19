import 'package:intl/intl.dart';

extension StringExtension on String {
  /// Returns initials from a full name — first letter of first and last word.
  /// Example: "John Doe" → "J D"
  String get initials {
    if (isEmpty) return '';
    final words = trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]} ${words[1][0]}'.toUpperCase();
    }
    return words[0][0].toUpperCase();
  }

  /// Extracts all #hashtags from the string.
  List<String> get hashtags {
    final exp = RegExp(r'#(\w+)');
    return exp.allMatches(this).map((m) => m.group(1)!).toList();
  }

  /// Returns `true` if the string starts with an RTL character.
  bool get isRtl => Bidi.startsWithRtl(this);

  /// Collapses leading/trailing blank lines into a single space.
  String get cleaned {
    final trimmed = trim();
    return trimmed.replaceAll(RegExp(r'(?<!\S)\n+|\n+(?!\S)'), ' ');
  }

  /// Extracts the last path segment of a URL as a readable title.
  /// Example: "https://example.com/my-post" → "My post"
  String get urlTitle {
    final uri = Uri.tryParse(this);
    if (uri == null) return this;
    final segment = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : uri.host;
    final readable = segment.replaceAll('-', ' ');
    return readable.isNotEmpty
        ? readable[0].toUpperCase() + readable.substring(1)
        : '';
  }

  /// Returns the root domain from a URL.
  /// Example: "https://sub.example.com/path" → "example.com"
  String get rootDomain {
    final uri = Uri.tryParse(this);
    if (uri == null) return this;
    final parts = uri.host.split('.');
    return parts.length > 2 ? parts.sublist(parts.length - 2).join('.') : uri.host;
  }

  /// Returns `true` if the string contains exactly one emoji character.
  bool get isSingleEmoji {
    final exp = RegExp(
      r'^(?:[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|'
      r'[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F1E0}-\u{1F1FF}]|'
      r'[\u{1F900}-\u{1F9FF}]|[\u{1F018}-\u{1F270}]|[\u{238C}-\u{2454}]|'
      r'[\u{20D0}-\u{20FF}]|[\u{1F250}-\u{1F251}]|[\u{1F004}-\u{1F0CF}])$',
      unicode: true,
    );
    return exp.hasMatch(this);
  }

  /// Returns `true` if the string consists entirely of emoji characters.
  bool get isOnlyEmoji {
    final exp = RegExp(
      r'^(?:[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}'
      r'\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}'
      r'\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}'
      r'\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F1E6}-\u{1F1FF}]|'
      r'[©®™\u200D\u2640\u2642])+$',
      unicode: true,
    );
    return exp.hasMatch(this);
  }
}
