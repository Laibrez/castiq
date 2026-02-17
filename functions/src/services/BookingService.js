const { db } = require("../config/firebase");
const admin = require("firebase-admin");

class BookingService {
    async createBooking(userId, data) {
        const { modelId, jobId, rate, details } = data;
        const brandId = userId;

        // Validation could be expanded here (e.g., check if users exist)

        const bookingRef = db.collection("bookings").doc();
        const bookingId = bookingRef.id;

        const bookingData = {
            id: bookingId,
            brandId: brandId,
            modelId: modelId,
            jobId: jobId,
            rate: rate,
            status: "offer_sent",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            details: details || {},
            history: [{
                status: "offer_sent",
                timestamp: admin.firestore.Timestamp.now(),
                by: brandId
            }]
        };

        await bookingRef.set(bookingData);
        return { bookingId: bookingId, status: "offer_sent" };
    }

    async acceptBooking(userId, bookingId) {
        const bookingRef = db.collection("bookings").doc(bookingId);
        const bookingDoc = await bookingRef.get();

        if (!bookingDoc.exists) {
            throw new Error("Booking not found."); // Service throws generic errors, Controller handles HTTP mapping
        }

        const booking = bookingDoc.data();

        if (booking.modelId !== userId) {
            throw new Error("Only the model can accept this offer.");
        }

        if (booking.status !== "offer_sent") {
            throw new Error("Booking is not in a valid state to be accepted.");
        }

        // Create Chat
        const chatRef = db.collection("chats").doc();
        const chatId = chatRef.id;

        await chatRef.set({
            id: chatId,
            bookingId: bookingId,
            participants: [booking.brandId, booking.modelId],
            chatEnabled: true,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Add System Message
        await chatRef.collection("messages").add({
            text: "Caztiq Notice: For your safety, all payments and contracts must remain within Caztiq. We protect both parties by managing contracts and payments securely.",
            senderId: "system",
            type: "system",
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update Chat Metadata
        await chatRef.update({
            lastMessage: "Caztiq Notice: For your safety...",
            lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
            lastMessageSenderId: "system",
            unreadCount: 1,
        });

        // Update Booking
        await bookingRef.update({
            status: "offer_accepted",
            chatId: chatId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            history: admin.firestore.FieldValue.arrayUnion({
                status: "offer_accepted",
                timestamp: admin.firestore.Timestamp.now(),
                by: userId
            })
        });

        return { success: true, status: "offer_accepted", chatId: chatId };
    }
}

module.exports = new BookingService();
