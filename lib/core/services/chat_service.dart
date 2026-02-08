import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_application_1/core/models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new chat when offer is accepted
  Future<String?> createChat({
    required String modelId,
    required String modelName,
    String? modelImage,
    required String brandId,
    required String brandName,
    String? brandImage,
    String? jobId,
    String? jobTitle,
    String initialMessage = 'Hello! Thank you for accepting the offer.',
  }) async {
    try {
      // Check if chat already exists between these participants for this job
      final existingChat = await _firestore
          .collection('chats')
          .where('modelId', isEqualTo: modelId)
          .where('brandId', isEqualTo: brandId)
          .where('jobId', isEqualTo: jobId)
          .limit(1)
          .get();

      if (existingChat.docs.isNotEmpty) {
        return existingChat.docs.first.id;
      }

      // Create new chat
      final chatRef = await _firestore.collection('chats').add({
        'modelId': modelId,
        'modelName': modelName,
        'modelImage': modelImage,
        'brandId': brandId,
        'brandName': brandName,
        'brandImage': brandImage,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'lastMessage': initialMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': brandId,
        'unreadCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add initial message to messages subcollection
      await chatRef.collection('messages').add({
        'senderId': brandId,
        'senderName': brandName,
        'senderRole': 'brand',
        'content': initialMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      return chatRef.id;
    } catch (e) {
      print('Error creating chat: $e');
      return null;
    }
  }

  // Get all chats for a user (model or brand)
  Stream<List<ChatModel>> getUserChats(String userId, String role) {
    final field = role == 'model' ? 'modelId' : 'brandId';
    return _firestore
        .collection('chats')
        .where(field, isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get messages stream for a specific chat
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Send a message via Cloud Function
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
  }) async {
    try {
      await FirebaseFunctions.instance.httpsCallable('sendMessage').call({
        'chatId': chatId,
        'text': content,
        'type': 'text', 
      });
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String readerId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final data = chatDoc.data()!;
        if (data['lastMessageSenderId'] != readerId) {
          await _firestore.collection('chats').doc(chatId).update({
            'unreadCount': 0,
          });
        }
      }

      // Mark individual messages as read
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: readerId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
    } catch (e) {
      // Error
    }
  }

  // Get unread message count for a user
  Stream<int> getUnreadCount(String userId, String role) {
    final field = role == 'model' ? 'modelId' : 'brandId';
    return _firestore
        .collection('chats')
        .where(field, isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            if (data['lastMessageSenderId'] != userId) {
              total += (data['unreadCount'] as int? ?? 0);
            }
          }
          return total;
        });
  }

  // Delete a chat (optional)
  Future<bool> deleteChat(String chatId) async {
    try {
      // Delete all messages first
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();
      
      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      // Delete chat document
      await _firestore.collection('chats').doc(chatId).delete();
      return true;
    } catch (e) {
      print('Error deleting chat: $e');
      return false;
    }
  }
}
