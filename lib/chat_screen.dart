import 'dart:convert';

import 'package:chatview/chatview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lostwithiel/models/activity.dart';

import 'data.dart';
import 'models/theme.dart';
import 'signalling.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    _signaling = Signaling(
      onConnectedStatusChanged: _onConnected,
      onMessageReceived: _onMessageReceived,
    );
    super.initState();
  }

  Signaling? _signaling;
  String roomId = '';
  AppTheme theme = DarkTheme();
  bool isDarkTheme = true;
  bool isConnected = false;

  final currentUser = ChatUser(
    id: '1',
    name: 'Bob',
    profilePhoto: Data.profileImage,
  );

  final _chatController = ChatController(
    initialMessageList: Data.messageList,
    scrollController: ScrollController(),
    chatUsers: [
      ChatUser(
        id: '2',
        name: 'Simform',
        profilePhoto: Data.profileImage,
      ),
      ChatUser(
        id: '3',
        name: 'Jhon',
        profilePhoto: Data.profileImage,
      ),
      ChatUser(
        id: '4',
        name: 'Alice B. Goode',
        profilePhoto: Data.profileImage,
      ),
      ChatUser(
        id: '5',
        name: 'Rich',
        profilePhoto: Data.profileImage,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChatView(
        chatController: _chatController,
        currentUser: currentUser,
        onSendTap: _onSendTap,
        chatViewStateConfig: _chatViewStateConfig(),
        chatViewState: ChatViewState.hasMessages,
        typeIndicatorConfig: _typeIndicatorConfig(),
        appBar: _chatViewAppBar(),
        chatBackgroundConfig: _chatBackgroundConfig(),
        sendMessageConfig: _sendMessageConfig(),
        chatBubbleConfig: _chatBubbleConfig(),
        replyPopupConfig: _replyPopupConfig(),
        reactionPopupConfig: _reactionPopupConfig(),
        messageConfig: _messageConfig(),
        profileCircleConfig: _profileCircleConfig(),
        repliedMessageConfig: _repliedMessageConfig(),
        swipeToReplyConfig: _swipeToReplyConfig(),
      ),
    );
  }

  TypeIndicatorConfiguration _typeIndicatorConfig() {
    return TypeIndicatorConfiguration(
      flashingCircleBrightColor: theme.flashingCircleBrightColor,
      flashingCircleDarkColor: theme.flashingCircleDarkColor,
    );
  }

  ChatViewStateConfiguration _chatViewStateConfig() {
    return ChatViewStateConfiguration(
      loadingWidgetConfig: ChatViewStateWidgetConfiguration(
        loadingIndicatorColor: theme.outgoingChatBubbleColor,
      ),
      onReloadButtonTap: () {},
    );
  }

  SwipeToReplyConfiguration _swipeToReplyConfig() {
    return SwipeToReplyConfiguration(
      replyIconColor: theme.swipeToReplyIconColor,
    );
  }

  RepliedMessageConfiguration _repliedMessageConfig() {
    return RepliedMessageConfiguration(
      backgroundColor: theme.repliedMessageColor,
      verticalBarColor: theme.verticalBarColor,
      repliedMsgAutoScrollConfig: RepliedMsgAutoScrollConfig(
        enableHighlightRepliedMsg: true,
        highlightColor: Colors.pinkAccent.shade100,
        highlightScale: 1.1,
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.25,
      ),
      replyTitleTextStyle: TextStyle(color: theme.repliedTitleTextColor),
    );
  }

  ProfileCircleConfiguration _profileCircleConfig() {
    return const ProfileCircleConfiguration(
      profileImageUrl: Data.profileImage,
    );
  }

  MessageConfiguration _messageConfig() {
    return MessageConfiguration(
      messageReactionConfig: MessageReactionConfiguration(
        backgroundColor: theme.messageReactionBackGroundColor,
        borderColor: theme.messageReactionBackGroundColor,
        reactedUserCountTextStyle:
            TextStyle(color: theme.inComingChatBubbleTextColor),
        reactionCountTextStyle:
            TextStyle(color: theme.inComingChatBubbleTextColor),
        reactionsBottomSheetConfig: ReactionsBottomSheetConfiguration(
          backgroundColor: theme.backgroundColor,
          reactedUserTextStyle: TextStyle(
            color: theme.inComingChatBubbleTextColor,
          ),
          reactionWidgetDecoration: BoxDecoration(
            color: theme.inComingChatBubbleColor,
            boxShadow: [
              BoxShadow(
                color: isDarkTheme ? Colors.black12 : Colors.grey.shade200,
                offset: const Offset(0, 20),
                blurRadius: 40,
              )
            ],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      imageMessageConfig: ImageMessageConfiguration(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        shareIconConfig: ShareIconConfiguration(
          defaultIconBackgroundColor: theme.shareIconBackgroundColor,
          defaultIconColor: theme.shareIconColor,
        ),
      ),
    );
  }

  ReactionPopupConfiguration _reactionPopupConfig() {
    return ReactionPopupConfiguration(
      shadow: BoxShadow(
        color: isDarkTheme ? Colors.black54 : Colors.grey.shade400,
        blurRadius: 20,
      ),
      backgroundColor: theme.reactionPopupColor,
    );
  }

  ReplyPopupConfiguration _replyPopupConfig() {
    return ReplyPopupConfiguration(
      backgroundColor: theme.replyPopupColor,
      buttonTextStyle: TextStyle(color: theme.replyPopupButtonColor),
      topBorderColor: theme.replyPopupTopBorderColor,
    );
  }

  ChatBubbleConfiguration _chatBubbleConfig() {
    return ChatBubbleConfiguration(
      outgoingChatBubbleConfig: ChatBubble(
        linkPreviewConfig: LinkPreviewConfiguration(
          backgroundColor: theme.linkPreviewOutgoingChatColor,
          bodyStyle: theme.outgoingChatLinkBodyStyle,
          titleStyle: theme.outgoingChatLinkTitleStyle,
        ),
        color: theme.outgoingChatBubbleColor,
      ),
      inComingChatBubbleConfig: ChatBubble(
        linkPreviewConfig: LinkPreviewConfiguration(
          linkStyle: TextStyle(
            color: theme.inComingChatBubbleTextColor,
            decoration: TextDecoration.underline,
          ),
          backgroundColor: theme.linkPreviewIncomingChatColor,
          bodyStyle: theme.incomingChatLinkBodyStyle,
          titleStyle: theme.incomingChatLinkTitleStyle,
        ),
        textStyle: TextStyle(color: theme.inComingChatBubbleTextColor),
        senderNameTextStyle:
            TextStyle(color: theme.inComingChatBubbleTextColor),
        color: theme.inComingChatBubbleColor,
      ),
    );
  }

  SendMessageConfiguration _sendMessageConfig() {
    return SendMessageConfiguration(
      imagePickerIconsConfig: ImagePickerIconsConfiguration(
        cameraIconColor: theme.cameraIconColor,
        galleryIconColor: theme.galleryIconColor,
      ),
      replyMessageColor: theme.replyMessageColor,
      defaultSendButtonColor: theme.sendButtonColor,
      replyDialogColor: theme.replyDialogColor,
      replyTitleColor: theme.replyTitleColor,
      textFieldBackgroundColor: theme.textFieldBackgroundColor,
      closeIconColor: theme.closeIconColor,
      textFieldConfig: TextFieldConfiguration(
        onMessageTyping: (status) {
          /// Do with status
          //debugPrint(status.toString());
        },
        compositionThresholdTime: const Duration(seconds: 1),
        textStyle: TextStyle(color: theme.textFieldTextColor),
      ),
      micIconColor: theme.replyMicIconColor,
      voiceRecordingConfiguration: VoiceRecordingConfiguration(
        backgroundColor: theme.waveformBackgroundColor,
        recorderIconColor: theme.recordIconColor,
        waveStyle: WaveStyle(
          showMiddleLine: false,
          waveColor: theme.waveColor ?? Colors.white,
          extendWaveform: true,
        ),
      ),
    );
  }

  ChatBackgroundConfiguration _chatBackgroundConfig() {
    return ChatBackgroundConfiguration(
      messageTimeIconColor: theme.messageTimeIconColor,
      messageTimeTextStyle: TextStyle(color: theme.messageTimeTextColor),
      defaultGroupSeparatorConfig: DefaultGroupSeparatorConfiguration(
        textStyle: TextStyle(
          color: theme.chatHeaderColor,
          fontSize: 17,
        ),
      ),
      backgroundColor: theme.backgroundColor,
    );
  }

  ChatViewAppBar _chatViewAppBar() {
    return ChatViewAppBar(
      elevation: theme.elevation,
      backGroundColor: theme.appBarColor,
      profilePicture: Data.profileImage,
      backArrowColor: theme.backArrowColor,
      chatTitle: "Serverless & Homeless",
      chatTitleTextStyle: TextStyle(
        color: theme.appBarTitleTextStyle,
        fontWeight: FontWeight.bold,
        fontSize: 18,
        letterSpacing: 0.25,
      ),
      userStatus: "online",
      userStatusTextStyle: const TextStyle(color: Colors.grey),
      actions: [
        IconButton(
          onPressed: _onThemeIconTap,
          icon: Icon(
            isDarkTheme
                ? Icons.brightness_4_outlined
                : Icons.dark_mode_outlined,
            color: theme.themeIconColor,
          ),
        ),
        IconButton(
          tooltip: 'Toggle TypingIndicator',
          onPressed: _showHideTypingIndicator,
          icon: Icon(
            Icons.keyboard,
            color: theme.themeIconColor,
          ),
        ),
        IconButton(
          tooltip: 'Connect to network',
          onPressed: _makeOffer,
          icon: Icon(
            Icons.power,
            color: theme.themeIconColor,
          ),
        ),
      ],
    );
  }

  void _onSendTap(
    String message,
    ReplyMessage replyMessage,
    MessageType messageType,
  ) {
    if (message.split('@').length > 1) _makeAnwer(message);
    if (isConnected) {
      final id = int.parse(Data.messageList.last.id) + 1;
      final msg = Message(
        id: id.toString(),
        createdAt: DateTime.now(),
        message: message,
        sendBy: currentUser.id,
        replyMessage: replyMessage,
        messageType: messageType,
      );
      _chatController.addMessage(msg);
      //TODO: refactor this smell
      final payload = Payload(
        message: message,
        sendBy: _chatController.chatUsers[2].id,
      );
      final jsonPayload = jsonEncode(payload);
      _signaling?.sendMessage(jsonPayload);
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      _chatController.initialMessageList.last.setStatus =
          MessageStatus.undelivered;
    });
    Future.delayed(const Duration(seconds: 1), () {
      _chatController.initialMessageList.last.setStatus = MessageStatus.read;
    });
  }

  void _showHideTypingIndicator() {
    _chatController.setTypingIndicator = !_chatController.showTypingIndicator;
  }

  void _onThemeIconTap() {
    setState(() {
      if (isDarkTheme) {
        theme = LightTheme();
        isDarkTheme = false;
      } else {
        theme = DarkTheme();
        isDarkTheme = true;
      }
    });
  }

  void _makeOffer() async {
    final id = await _signaling?.createRoom();
    setState(() {
      roomId = id!;
    });

    Clipboard.setData(
      ClipboardData(text: 'answer@$roomId'),
    ).then(
      (value) => {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Presence ID Copied'),
          ),
        )
      },
    );
  }

  void _makeAnwer(String id) async {
    final String peer = id.split('@')[1];
    _signaling?.joinRoom(peer);
  }

  void _onConnected() {
    setState(() {
      isConnected = true;
    });
  }

  void _onMessageReceived(Payload payload) {
    final id = int.parse(Data.messageList.last.id) + 1;
    final msg = Message(
      id: id.toString(),
      createdAt: DateTime.now(),
      message: payload.message,
      sendBy: payload.sendBy,
    );
    _chatController.addMessage(msg);
  }
}
