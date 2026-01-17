import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message_model.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get or create chat ID between two users
  Future<String> getOrCreateChatId(String userId1, String userId2) async {
    try {
      // Sort IDs to ensure consistent chat ID regardless of who initiates
      final sortedIds = [userId1, userId2]..sort();
      final chatId = 'chat_${sortedIds[0]}_${sortedIds[1]}';

      // Check if chat exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!chatDoc.exists) {
        // Create chat document
        await _firestore.collection('chats').doc(chatId).set({
          'participants': sortedIds,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }

      return chatId;
    } catch (e) {
      throw Exception('Failed to get/create chat: $e');
    }
  }

  // Send a message
  Future<String> sendMessage({
    required String chatId,
    required String receiverId,
    required String receiverName,
    required String message,
    MessageType messageType = MessageType.text,
    String? attachmentUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get sender name
      final senderDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!senderDoc.exists) throw Exception('User data not found');
      final senderName = senderDoc.data()!['name'] ?? 'Unknown';

      final messageData = {
        'chatId': chatId,
        'senderId': user.uid,
        'senderName': senderName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'message': message,
        'messageType': messageType.toString().split('.').last,
        'attachmentUrl': attachmentUrl,
        'isRead': false,
        'readAt': null,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      final docRef = await _firestore.collection('messages').add(messageData);

      // Update chat's last message and timestamp
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Create notification for receiver if they're not the current user
      if (receiverId != user.uid) {
        try {
          final notificationService = NotificationService();
          await notificationService.notifyNewMessage(
            receiverId: receiverId,
            senderName: senderName,
            message: message.length > 50 ? '${message.substring(0, 50)}...' : message,
            chatId: chatId,
          );
        } catch (e) {
          // Don't fail message send if notification fails
          debugPrint('Error creating notification: $e');
        }
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for a chat
  Stream<List<ChatMessageModel>> getChatMessages(String chatId) {
    try {
      return _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ChatMessageModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String senderId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final messagesSnapshot = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Get chat list for current user
  Stream<List<Map<String, dynamic>>> getUserChats() {
    try {
      final user = _auth.currentUser;
      if (user == null) return Stream.value([]);

      return _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        final chats = <Map<String, dynamic>>[];

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final participants = List<String>.from(data['participants'] ?? []);
          
          // Get the other participant
          final otherParticipantId = participants.firstWhere(
            (id) => id != user.uid,
            orElse: () => '',
          );

          if (otherParticipantId.isEmpty) continue;

          // Get other participant's info
          final otherUserDoc = await _firestore
              .collection('users')
              .doc(otherParticipantId)
              .get();

          if (!otherUserDoc.exists) continue;

          final otherUserData = otherUserDoc.data()!;
          final otherUserName = otherUserData['name'] ?? 'Unknown';
          final otherUserRole = otherUserData['role'] ?? '';

          chats.add({
            'chatId': doc.id,
            'participantId': otherParticipantId,
            'participantName': otherUserName,
            'participantRole': otherUserRole,
            'lastMessage': data['lastMessage'] ?? '',
            'lastMessageTime': data['lastMessageTime'],
            'updatedAt': data['updatedAt'],
          });
        }

        return chats;
      });
    } catch (e) {
      throw Exception('Failed to fetch chats: $e');
    }
  }

  // Get unread message count for a chat
  Future<int> getUnreadCount(String chatId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('receiverId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
