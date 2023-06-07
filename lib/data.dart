import 'package:chatview/chatview.dart';

class Data {
  static const profileImage = "assets/images/2.jpg";
  static final List<Message> messageList = [
    Message(
      id: '1',
      message: "Hi!",
      createdAt: DateTime.now(),
      sendBy: '1', // userId of who sends the message
    )
  ];
}
