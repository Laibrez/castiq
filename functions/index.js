const functions = require("firebase-functions");
const { admin } = require("./src/config/firebase");

// Services
const UserService = require("./src/services/UserService");
const BookingService = require("./src/services/BookingService");
const ChatService = require("./src/services/ChatService");
const PaymentService = require("./src/services/PaymentService");

// Initialize Stripe and inject into PaymentService
const stripe = require("stripe")(functions.config().stripe.secret);
PaymentService.initialize(stripe, functions.config().stripe.publishable_key);

// Auth Triggers
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
    try {
        await UserService.createUserProfile(user);
    } catch (error) {
        console.error("Error creating user profile:", error);
    }
});

// Booking System
exports.createBooking = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
    }
    try {
        return await BookingService.createBooking(context.auth.uid, data);
    } catch (error) {
        console.error("createBooking Error:", error);
        throw new functions.https.HttpsError("internal", error.message);
    }
});

exports.acceptOffer = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
    }
    try {
        return await BookingService.acceptBooking(context.auth.uid, data.bookingId);
    } catch (error) {
        console.error("acceptOffer Error:", error);
        // Map generic errors to HttpsError if needed, or just throw internal
        throw new functions.https.HttpsError("internal", error.message);
    }
});

// Chat System
exports.sendMessage = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
    }
    try {
        return await ChatService.sendMessage(context.auth.uid, data);
    } catch (error) {
        console.error("sendMessage Error:", error);
        throw new functions.https.HttpsError("internal", error.message);
    }
});

// Payment System
exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
    }
    try {
        // Pass email from context token for customer creation if needed
        return await PaymentService.createPaymentIntent(context.auth.uid, data, context.auth.token.email);
    } catch (error) {
        console.error("createPaymentIntent Error:", error);
        throw new functions.https.HttpsError("internal", error.message);
    }
});
// Escrow Trigger
exports.onBookingUpdated = functions.firestore.document('bookings/{bookingId}').onUpdate(async (change, context) => {
    const newData = change.after.data();
    const previousData = change.before.data();

    if (newData.status === 'fully_signed' && previousData.status !== 'fully_signed') {
        const bookingId = context.params.bookingId;
        console.log(`Booking ${bookingId} fully signed. Creating PaymentIntent for Escrow.`);

        try {
            // Create PaymentIntent
            // We pass null for userEmail as fallback logic in PaymentService handles it or fetches from DB
            const result = await PaymentService.createPaymentIntent(newData.brandId, { bookingId: bookingId }, null);

            // Store client secret and update status
            await change.after.ref.update({
                paymentIntentClientSecret: result.paymentIntent, // This is the client_secret
                paymentStatus: 'pending_escrow',
                stripeCustomerId: result.customer
            });
            console.log(`PaymentIntent created for booking ${bookingId}`);
        } catch (error) {
            console.error(`Error creating escrow payment intent for booking ${bookingId}:`, error);
        }
    }
});
