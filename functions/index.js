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
// 2️⃣ Payment Verification (NEW)
// -----------------------
function calculateValidUntil(currentValidUntil, plan) {
  const now = new Date();
  const baseDate = currentValidUntil ? currentValidUntil.toDate() : now;
  let monthsToAdd = 1; // default monthly

  if (plan === "basic") monthsToAdd = 1;
  else if (plan === "pro") monthsToAdd = 3;

  const newDate = new Date(baseDate);
  newDate.setMonth(newDate.getMonth() + monthsToAdd);
  return newDate;
}

exports.verifyPayment = functions.firestore
  .document("gyms/{gymId}/payments/{paymentId}")
  .onCreate(async (snap, context) => {
    const payment = snap.data();
    const { gymId, paymentId } = context.params;

    console.log("New payment created:", paymentId, payment);

    if (!payment || payment.verified || payment.status !== "pending") {
      console.log("Payment already verified or not pending. Exiting.");
      return null;
    }

    try {
      // ---- FAKE Verification (replace later with real gateway API) ----
      console.log(`Verifying payment ${paymentId}...`);
      await new Promise((resolve) => setTimeout(resolve, 2000)); // simulate delay
      const verified = true;

      // Update payment document
      const paymentRef = admin
        .firestore()
        .doc(`gyms/${gymId}/payments/${paymentId}`);

      await paymentRef.update({
        verified,
        status: verified ? "completed" : "failed",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("Payment verified:", paymentId);

      // Update member document
      const memberRef = admin
        .firestore()
        .doc(`gyms/${gymId}/member/${payment.memberId}`);

      const memberSnap = await memberRef.get();
      if (!memberSnap.exists) {
        console.log("Member not found:", payment.memberId);
        return null;
      }

      const memberData = memberSnap.data();
      const validUntil = calculateValidUntil(memberData.validUntil, payment.plan);

      await memberRef.update({
        feeStatus: "paid",
        currentFee: payment.amount,
        validUntil: admin.firestore.Timestamp.fromDate(validUntil),
      });

      console.log("Member updated successfully:", payment.memberId);
      return null;
    } catch (error) {
      console.error("Error verifying payment:", error);
      return null;
    }
  });
