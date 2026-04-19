const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

// -----------------------
// 1️⃣ Rotate Attendance QR Daily (existing)
// -----------------------
exports.rotateAttendanceQrDaily = functions.pubsub
  .schedule("0 0 * * *")
  .timeZone("Asia/Karachi")
  .onRun(async (context) => {
    const db = admin.firestore();
    try {
      const gymsSnapshot = await db.collection("gyms").get();
      if (gymsSnapshot.empty) {
        console.log("No gyms found to update.");
        return null;
      }

      const now = Date.now();
      const batch = db.batch();

      gymsSnapshot.forEach((doc) => {
        const newToken = now.toString();
        const expiresAt = admin.firestore.Timestamp.fromMillis(
          now + 24 * 60 * 60 * 1000
        );

        batch.update(doc.ref, {
          currentAttendanceQrToken: newToken,
          attendanceQrExpiresAt: expiresAt,
          attendanceQrLastGeneratedAt:
            admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();
      console.log(`Midnight rotation successful for ${gymsSnapshot.size} gyms.`);
    } catch (error) {
      console.error("Error during midnight rotation:", error);
    }
    return null;
  });


// -----------------------
// 2️⃣ Notify owner via FCM when a member deletes their account with unpaid fees
// -----------------------
exports.notifyOwnerOnMemberDeletion = functions.firestore
  .document("gyms/{gymId}/notifications/{notifId}")
  .onCreate(async (snap, context) => {
    const db = admin.firestore();
    const { gymId } = context.params;
    const notifData = snap.data();

    if (notifData.type !== "member_deleted_unpaid") return null;

    try {
      // Fetch the gym to get ownerUid
      const gymDoc = await db.collection("gyms").doc(gymId).get();
      if (!gymDoc.exists) {
        console.error(`Gym ${gymId} not found`);
        return null;
      }
      const ownerUid = gymDoc.data().ownerUid;
      if (!ownerUid) {
        console.error(`No ownerUid on gym ${gymId}`);
        return null;
      }

      // Fetch owner's FCM token
      const ownerDoc = await db.collection("users").doc(ownerUid).get();
      if (!ownerDoc.exists) {
        console.error(`Owner user doc ${ownerUid} not found`);
        return null;
      }
      const fcmToken = ownerDoc.data().fcmToken;
      if (!fcmToken) {
        console.warn(`Owner ${ownerUid} has no FCM token — skipping push`);
        return null;
      }

      // Send FCM push notification
      const message = {
        token: fcmToken,
        notification: {
          title: "Member Account Deleted",
          body: notifData.message || "A member deleted their account with outstanding fees.",
        },
        data: {
          type: "member_deleted_unpaid",
          memberId: notifData.memberId || "",
          gymId: gymId,
        },
        android: { priority: "high" },
        apns: { payload: { aps: { sound: "default" } } },
      };

      await admin.messaging().send(message);
      console.log(`FCM push sent to owner ${ownerUid} for gym ${gymId}`);
    } catch (error) {
      console.error("Error in notifyOwnerOnMemberDeletion:", error);
    }
    return null;
  });


