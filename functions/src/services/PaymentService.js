const { db } = require("../config/firebase");
const admin = require("firebase-admin");

class PaymentService {
    constructor() {
        this.stripe = null;
        this.publishableKey = null;
    }

    // Initialize with stripe instance and keys (Dependency Injection)
    initialize(stripeInstance, publishableKey) {
        this.stripe = stripeInstance;
        this.publishableKey = publishableKey;
    }

    async createPaymentIntent(userId, data, userEmail) {
        if (!this.stripe) {
            throw new Error("Payment service not initialized");
        }

        const { bookingId } = data;

        const bookingDoc = await db.collection("bookings").doc(bookingId).get();
        if (!bookingDoc.exists) {
            throw new Error("Booking not found.");
        }

        const booking = bookingDoc.data();
        if (booking.brandId !== userId) {
            throw new Error("Only the brand can pay for this booking.");
        }

        // Calculate amount (rate + fee)
        const amount = Math.round((booking.rate * 1.10) * 100); // 10% fee, in cents

        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) {
            throw new Error("User not found.");
        }
        const userData = userDoc.data();

        // Create Stripe Customer if not exists
        let customerId = userData.stripeCustomerId;
        if (!customerId) {
            // Use provided email or fallback
            const email = userEmail || userData.email || `user_${userId}@caztiq.com`;
            const customer = await this.stripe.customers.create({ email: email });
            customerId = customer.id;
            await db.collection("users").doc(userId).update({ stripeCustomerId: customerId });
        }

        const paymentIntent = await this.stripe.paymentIntents.create({
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
            publishableKey: this.publishableKey,
        };
    }
}

module.exports = new PaymentService();
