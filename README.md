# saas

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.







//Schema

users/{uid}
gyms/{gymId}
gyms/{gymId}/members/{uid}
gyms/{gymId}/payments/{paymentId}
gyms/{gymId}/attendance/{attendanceId}
wallets/{gymId}
walletTransactions/{transactionId}
payoutRequests/{requestId}





// ───────────────────────────────────────────
// users/{uid}
// ───────────────────────────────────────────
- name:            String
- email:           String
- role:            String          // superAdmin | owner | member
- gymId:           String | null
- isVerified:      Boolean
- createdAt:       Timestamp
- contactNumber:   String


// ───────────────────────────────────────────
// gyms/{gymId}
// ───────────────────────────────────────────
- gymName:                        String
- ownerUid:                       String
- location:                       String
- defaultFee:                     Number
- registrationCode:               String
- plan:                           String     // Monthly | 6 Months | Yearly
- status:                         String     // active | suspended | blocked
- isSaaSActive:                   Boolean
- createdAt:                      Timestamp
- attendanceQrExpiresAt:          Timestamp
- attendanceQrLastGeneratedAt:    Timestamp
- currentAttendanceQrToken:       String


// ───────────────────────────────────────────
// gyms/{gymId}/members/{uid}
// ───────────────────────────────────────────
- uid:             String          // same as document ID (users/{uid})
- name:            String
- contactNumber:   String
- plan:            String          // free | basic | pro
- joinedAt:        Timestamp
- currentFee:      Number          // default from gym OR custom override
- feeStatus:       String          // paid | unpaid | overdue
- validUntil:      Timestamp | null
- createdBy:       String          // ownerUid
- createdAt:       Timestamp




// ───────────────────────────────────────────
// gyms/{gymId}/payments/{paymentId}
// ───────────────────────────────────────────
- memberId:        String
- amount:          Number
- method:          String          // easypaisa | jazzcash
- verified:        Boolean
- timestamp:       Timestamp
- transactionId:   String          // unique ID from gateway
- plan:            String          // plan this payment covers
- validUntil:      Timestamp       // member validity after this payment
- createdAt:       Timestamp
- status:          String          // pending | completed | failed
- updatedAt:       Timestamp
- walletCredited:  Boolean         // NEW — safety flag, Cloud Function only


// ───────────────────────────────────────────
// gyms/{gymId}/attendance/{attendanceId}
// ───────────────────────────────────────────
- memberId:        String
- date:            String          // "2026-01-04" (YYYY-MM-DD)
- markedBy:        String          // admin | user
- status:          String          // present | absent
- timeStamp:       Timestamp



// ───────────────────────────────────────────
// wallets/{gymId}
// ───────────────────────────────────────────
// ⚠ Cloud Function writes only — no client writes ever
- gymId:           String
- ownerUid:        String
- balance:         Number          // current amount owed to owner
- totalEarned:     Number          // lifetime total from member payments
- totalPaidOut:    Number          // lifetime total sent to owner's bank
- lastUpdated:     Timestamp


// ───────────────────────────────────────────
// walletTransactions/{transactionId}
// ───────────────────────────────────────────
// ⚠ Cloud Function writes only — no client writes ever
- transactionId:   String          // same as document ID
- gymId:           String
- ownerUid:        String
- type:            String          // credit | debit
- amount:          Number
- balanceBefore:   Number          // wallet balance before this entry
- balanceAfter:    Number          // wallet balance after this entry
- referenceId:     String          // paymentId (credit) or requestId (debit)
- description:     String          // e.g. "Member fee from Ali Khan"
- createdAt:       Timestamp


// ───────────────────────────────────────────
// payoutRequests/{requestId}
// ───────────────────────────────────────────
- requestId:          String             // same as document ID
- gymId:              String
- ownerUid:           String
- amount:             Number             // amount owner is requesting
- status:             String             // pending | approved | rejected | transferred
- bankDetails:        Map
    - accountName:    String             // full name on account
    - bankName:       String             // HBL | UBL | Meezan | JazzCash | Easypaisa
    - accountNumber:  String             // bank account or wallet number
    - iban:           String | null      // optional but preferred
    - cnicLast6:      String             // last 6 digits of CNIC
- requestedAt:        Timestamp
- processedAt:        Timestamp | null   // when superAdmin acted
- processedBy:        String | null      // superAdmin uid
- transferRef:        String | null      // reference after manual transfer
- rejectionReason:    String | null      // only if status = rejected
- notes:              String | null      // superAdmin internal notes















