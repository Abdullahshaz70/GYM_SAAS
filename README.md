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



gyms/{gymId}/payments/{paymentId}
- memberId: String
- amount: Number
- method: String
- verified: Boolean
- timestamp: Timestamp



users/{uid}
- name: String
- email: String
- role: String              // superAdmin | owner | member
- gymId: String | null
- isVerified: Boolean
- status: String            // active | pending | blocked
- createdAt: Timestamp
- contactNumber: String




gyms/{gymId}/attendance/{attendanceId}
- memberId: String
- date: String              // "2026-01-04" (YYYY-MM-DD)




member(sub collection)

- uid: String                 // same as documentId (users/{uid})
- name: String
- contactNumber: String

- status: String              // active | inactive | blocked
- joinedAt: Timestamp

- currentFee: Number          // editable (default from gym OR custom)

- feeStatus: String           // paid | unpaid | overdue
- validUntil: Timestamp | null

- createdBy: String           // ownerUid
- createdAt: Timestamp











