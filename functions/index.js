const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(functions.config().stripe.secret);

admin.initializeApp();

// Export all functions from separate files to keep index.js clean
// For now, we'll keep them here or import them as needed.

// Auth Triggers
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
    const { uid, email } = user;
    // Default role is 'brand' if not specified (safest bet), or handled via custom claims later
    // For now, we just ensure a user document exists
    const userRef = admin.firestore().collection("users").doc(uid);
    const snapshot = await userRef.get();

    if (!snapshot.exists) {
        await userRef.set({
            email: email,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            role: "unknown", // User must select role during onboarding
            profileCompleted: false,
        });
    }
});

// Booking System - Create Booking
exports.createBooking = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
    }

    const { modelId, jobId, rate, details } = data;
    const brandId = context.auth.uid;

    // detailed validation can go here

    const bookingRef = admin.firestore().collection("bookings").doc();
    await bookingRef.set({
        id: bookingRef.id,
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
    });

    return { bookingId: bookingRef.id, status: "offer_sent" };
});

// Booking System - Accept Offer
exports.acceptOffer = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
    }

    const { bookingId } = data;
    const userId = context.auth.uid;

    const bookingRef = admin.firestore().collection("bookings").doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Booking not found.");
    }

    const booking = bookingDoc.data();

    // Validate user is the model for this booking
    if (booking.modelId !== userId) {
        throw new functions.https.HttpsError("permission-denied", "Only the model can accept this offer.");
    }

    if (booking.status !== "offer_sent") {
        throw new functions.https.HttpsError("failed-precondition", "Booking is not in a valid state to be accepted.");
    }

    // Create Chat
    const chatRef = admin.firestore().collection("chats").doc();
    await chatRef.set({
        id: chatRef.id,
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

    // Update Chat Metadata (Initial)
    await chatRef.update({
        lastMessage: "Caztiq Notice: For your safety...",
        lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
        lastMessageSenderId: "system",
        unreadCount: 1,
    });

    // Update Booking
    await bookingRef.update({
        status: "offer_accepted",
        chatId: chatRef.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        history: admin.firestore.FieldValue.arrayUnion({
            status: "offer_accepted",
            timestamp: admin.firestore.Timestamp.now(),
            by: userId
        })
    });

    return { success: true, status: "offer_accepted", chatId: chatRef.id };
});

// Chat System - Send Message
exports.sendMessage = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
    }

    const { chatId, text, type = "text" } = data;
    const userId = context.auth.uid;

    const chatRef = admin.firestore().collection("chats").doc(chatId);
    const chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Chat not found.");
    }

    const chat = chatDoc.data();

    if (!chat.participants.includes(userId)) {
        throw new functions.https.HttpsError("permission-denied", "User is not a participant in this chat.");
    }

    if (!chat.chatEnabled) {
        throw new functions.https.HttpsError("failed-precondition", "Chat is currently disabled.");
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
});

// Payment System - Create Payment Intent
exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
    }

    const { bookingId } = data;
    const userId = context.auth.uid;

    const bookingDoc = await admin.firestore().collection("bookings").doc(bookingId).get();
    if (!bookingDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Booking not found.");
    }

    const booking = bookingDoc.data();
    if (booking.brandId !== userId) {
        throw new functions.https.HttpsError("permission-denied", "Only the brand can pay for this booking.");
    }

    // Calculate amount (rate + fee)
    const amount = Math.round((booking.rate * 1.10) * 100); // 10% fee, in cents

    // Create Stripe Customer if not exists (simplified)
    let customerId = booking.stripeCustomerId;
    if (!customerId) {
        const customer = await stripe.customers.create({ email: context.auth.token.email });
        customerId = customer.id;
        await admin.firestore().collection("users").doc(userId).update({ stripeCustomerId: customerId });
    }

    const paymentIntent = await stripe.paymentIntents.create({
        amount: amount,
        currency: "usd",
        customer: customerId,
        automatic_payment_methods: { enabled: true },
        metadata: { bookingId: bookingId },
    });

    return {
        paymentIntent: paymentIntent.client_secret,
        customer: customerId,
        ephemeralKey: "", // Ideally generate ephemeral key
        publishableKey: functions.config().stripe.publishable_key,
    };
});
