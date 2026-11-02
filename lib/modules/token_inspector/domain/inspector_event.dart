import 'dart:convert';

enum InspectorEventKind { info, success, warning, error }

/// حدثٌ واحد بالسجلّ — **بلا توكن**: التفاصيل بصماتٌ وأعمار وحالات.
///
/// [details] أسطرٌ بشكل `Label: value` تُعرض بعمودين؛ وما لا `: ` فيه سطرٌ كامل.
class InspectorEvent {
  const InspectorEvent({
    required this.at,
    required this.kind,
    required this.title,
    this.details = const [],
  });

  final DateTime at;
  final InspectorEventKind kind;
  final String title;
  final List<String> details;

  String encode() => jsonEncode({
    'at': at.toIso8601String(),
    'kind': kind.name,
    'title': title,
    'details': details,
  });

  /// `null` لسطرٍ تالف — يُسقط وحده ولا يُسقط السجلّ.
  static InspectorEvent? tryDecode(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return InspectorEvent(
        at: DateTime.parse(json['at'] as String),
        kind: InspectorEventKind.values.byName(json['kind'] as String),
        title: json['title'] as String,
        details: (json['details'] as List).cast<String>(),
      );
    } on Object {
      return null;
    }
  }
}
