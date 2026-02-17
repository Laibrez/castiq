const admin = require("firebase-admin");

if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();
const auth = admin.auth();

module.exports = { admin, db, auth };
