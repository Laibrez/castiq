const { db } = require("../config/firebase");
const admin = require("firebase-admin");

class ChatService {
    async sendMessage(userId, data) {
        const { chatId, text, type = "text" } = data;

        const chatRef = db.collection("chats").doc(chatId);
        const chatDoc = await chatRef.get();

        if (!chatDoc.exists) {
            throw new Error("Chat not found.");
        }

        const chat = chatDoc.data();

        if (!chat.participants.includes(userId)) {
            throw new Error("User is not a participant in this chat.");
        }

        if (!chat.chatEnabled) {
            throw new Error("Chat is currently disabled.");
        }

        await chatRef.collection("messages").add({
            text: text,
            senderId: userId,
            type: type,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update Chat Metadata
        await chatRef.update({
            lastMessage: type === 'text' ? text : 'Sent an attachment',
            lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
            lastMessageSenderId: userId,
            unreadCount: admin.firestore.FieldValue.increment(1),
        });

        return { success: true };
    }
}

module.exports = new ChatService();
