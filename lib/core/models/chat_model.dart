import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // 'model' or 'brand'
  final String content;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> data, String id) {
    return MessageModel(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}

class ChatModel {
  final String id;
  final String modelId;
  final String modelName;
  final String? modelImage;
  final String brandId;
  final String brandName;
  final String? brandImage;
  final String? jobId;
  final String? jobTitle;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final int unreadCount;
  final DateTime createdAt;

  ChatModel({
    required this.id,
    required this.modelId,
    required this.modelName,
    this.modelImage,
    required this.brandId,
    required this.brandName,
    this.brandImage,
    this.jobId,
    this.jobTitle,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    this.unreadCount = 0,
    required this.createdAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> data, String id) {
    return ChatModel(
      id: id,
      modelId: data['modelId'] ?? '',
      modelName: data['modelName'] ?? '',
      modelImage: data['modelImage'],
      brandId: data['brandId'] ?? '',
      brandName: data['brandName'] ?? '',
      brandImage: data['brandImage'],
      jobId: data['jobId'],
      jobTitle: data['jobTitle'],
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unreadCount: data['unreadCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'modelId': modelId,
      'modelName': modelName,
      'modelImage': modelImage,
      'brandId': brandId,
      'brandName': brandName,
      'brandImage': brandImage,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
