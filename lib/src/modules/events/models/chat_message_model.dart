import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.userId,
    required this.userName,
    required this.createdAt,
    this.mentionedUserIds = const [],
    this.quotedMessageId,
    this.quotedMessageText,
    this.quotedMessageUserName,
  });

  final String id;
  final String text;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final List<String> mentionedUserIds;
  final String? quotedMessageId;
  final String? quotedMessageText;
  final String? quotedMessageUserName;

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      text: data['text']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      mentionedUserIds: (data['mentionedUserIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      quotedMessageId: data['quotedMessageId']?.toString(),
      quotedMessageText: data['quotedMessageText']?.toString(),
      quotedMessageUserName: data['quotedMessageUserName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'userId': userId,
    'userName': userName,
    'createdAt': FieldValue.serverTimestamp(),
    if (mentionedUserIds.isNotEmpty) 'mentionedUserIds': mentionedUserIds,
    if (quotedMessageId != null) 'quotedMessageId': quotedMessageId,
    if (quotedMessageText != null) 'quotedMessageText': quotedMessageText,
    if (quotedMessageUserName != null) 'quotedMessageUserName': quotedMessageUserName,
  };
}
