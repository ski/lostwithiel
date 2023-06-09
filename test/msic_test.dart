import 'dart:convert';

import 'package:lostwithiel/models/activity.dart';
import 'package:test/test.dart';

void main() {
  test('Encode p', () async {
    final Payload payload = Payload(
      sendBy: '2',
      message: 'This is a message',
    );
    final encoded = jsonEncode(payload);
  });
}
