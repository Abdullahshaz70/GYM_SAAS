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

















gyms/{gymId}
- gymName: String
- ownerUid: String
- location: String
- defaultFee: Number
- registrationCode: String
- plan: String              // free | basic | pro
- status: String            // active | suspended | blocked
- isSaaSActive: Boolean
- createdAt: Timestamp
- attendanceQrExpiresAt: TimeStamp
- attendanceQrLastGeneratedAt: TimeStamp
- currentAttendanceQrToken: String


gyms/{gymId}/payments/{paymentId}
- memberId: String
- amount: Number
- method: String
- verified: Boolean
- timestamp: Timestamp
- transactionId: String             // unique ID from Easypaisa/JazzCash
- plan: String                      // the plan this payment is for
- validUntil: Timestamp             // member’s subscription validity after this payment
- createdAt: Timestamp              // when the payment was created in DB
- status: String                    // pending | completed | failed

    


users/{uid}
- name: String
- email: String
- role: String              // superAdmin | owner | member
- gymId: String | null
- isVerified: Boolean
- createdAt: Timestamp
- contactNumber: String




gyms/{gymId}/attendance/{attendanceId}
- memberId: String
- date: String              // "2026-01-04" (YYYY-MM-DD)
- markedBy: admin | user
- status : present | absent
- timeStamp : TimeStamp



member(sub collection)

- uid: String                 // same as documentId (users/{uid})
- name: String
- contactNumber: String
- plan: String                 // member-specific plan: free | basic | pro
- joinedAt: Timestamp
- currentFee: Number          // editable (default from gym OR custom)
- feeStatus: String           // paid | unpaid | overdue
- validUntil: Timestamp | null
- createdBy: String           // ownerUid
- createdAt: Timestamp











