const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();


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

        gymsSnapshot.forEach(doc => {
            const newToken = now.toString();
            const expiresAt = admin.firestore.Timestamp.fromMillis(
                now + 24 * 60 * 60 * 1000
            );

            batch.update(doc.ref, {
                currentAttendanceQrToken: newToken,
                attendanceQrExpiresAt: expiresAt,
                attendanceQrLastGeneratedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });

        await batch.commit();
        console.log(`Midnight rotation successful for ${gymsSnapshot.size} gyms.`);
    } catch (error) {
        console.error("Error during midnight rotation:", error);
    }
    return null;
  });