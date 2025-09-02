const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

exports.resetCrashStatus = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async (context) => {
    const db = admin.firestore();
    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);

    const usersRef = db.collection("users");
    const snapshot = await usersRef.get();

    const batch = db.batch();
    snapshot.forEach((userDoc) => {
      const data = userDoc.data();
      if (data.status === "alert" && data.crashAt) {
        const crashAt = data.crashAt.toDate();
        if (crashAt <= twoHoursAgo) {
          batch.update(userDoc.ref, {
            status: "online",
            crashAt: null,
          });
        }
      }
    });

    await batch.commit();
    console.log("✅ Crash statuses reset where needed");
    return null;
  });
