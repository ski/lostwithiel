import 'dart:convert';

class Payload {
  /// Provides actual message it will be text or image/audio file path.
  final String message;

  /// Provides id of sender of message.
  final String sendBy;

  Payload({
    required this.message,
    required this.sendBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'sendBy': sendBy,
    };
  }

  factory Payload.fromMap(Map<String, dynamic> map) {
    return Payload(
      message: map['message'] ?? '',
      sendBy: map['sendBy'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Payload.fromJson(String source) =>
      Payload.fromMap(json.decode(source));
}
