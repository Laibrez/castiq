const { db } = require("../config/firebase");
const admin = require("firebase-admin");

class UserService {
    async createUserProfile(user) {
        const { uid, email } = user;
        const userRef = db.collection("users").doc(uid);
        const snapshot = await userRef.get();

        if (!snapshot.exists) {
            await userRef.set({
                email: email,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                role: "unknown", // User must select role during onboarding
                profileCompleted: false,
            });
            return { success: true, message: "User profile created" };
        }
        return { success: true, message: "User profile already exists" };
    }
}

module.exports = new UserService();
