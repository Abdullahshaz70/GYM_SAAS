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
















gyms (collection)
 └── {gymId} (document)
     ├── gymName: String
     ├── ownerUid: String
     ├── isSaaSActive: Boolean
     ├── registrationCode: String
     ├── location: String
     ├── createdAt: Timestamp
     ├── plan: String
     └── status: String

gyms/{gymId}/members (subcollection)
 └── {uid} (document)
     ├── status: String
     ├── membershipPlan: String
     ├── validUntil: Timestamp | null
     ├── lastPaymentDate: Timestamp | null
     ├── totalFeesPaid: Number
     └── createdAt: Timestamp
     |__ uid :String

gyms/{gymId}/attendance (subcollection)
 └── {date} (document)
     └── logs (subcollection)
         └── {uid} (document)
             ├── checkInTime: Timestamp
             └── paymentStatusAtCheckIn: String

gyms/{gymId}/payments (subcollection)
 └── {paymentId} (document)
     ├── memberId: String
     ├── amount: Number
     ├── method: String
     ├── verified: Boolean
     └── timestamp: Timestamp

users (collection)
 └── {uid} (document)
     ├── name: String
     ├── email: String
     ├── role: String
     ├── gymId: String
     ├── isVerified: Boolean
     ├── status: String
     └── createdAt: Timestamp
     |__ contactNumber: String

















