# Firestore Database Schema

## Visual Hierarchy

```
users/{uid}
  └── measurements/{docId}
  └── workouts/{docId}

gyms/{gymId}
  └── members/{uid}
  └── attendance/{docId}
  └── payments/{docId}
  └── payouts/{docId}
  └── expenses/{docId}
  └── notifications/{docId}
  └── pos_reports_history/{docId}
  └── conversations/{conversationId}
        └── messages/{docId}

config/company
```

---

## Root Collections

### `users/{uid}`

Document ID: Firebase Auth UID

| Field | Type | Notes |
|---|---|---|
| `name` | string | |
| `email` | string | |
| `contactNumber` | string | |
| `role` | string | `owner` / `staff` / `member` |
| `gymId` | string | |
| `photoUrl` | string? | |
| `isVerified` | boolean | |
| `isDeleted` | boolean | soft delete flag |
| `deletedAt` | timestamp? | |
| `status` | string | `pending` / `active` |
| `fcmToken` | string? | set at login for push notifications |
| `permissions` | map? | staff only — `{ canMarkAttendance: bool, canCollectFees: bool }` |
| `createdAt` | timestamp | |

> **Note:** `permissions` only exists on documents where `role == 'staff'`. It is written when a member is promoted to staff and updated by the owner via the Manage Staff screen.

#### Subcollection: `users/{uid}/measurements/{docId}`

| Field | Type | Notes |
|---|---|---|
| `date` | timestamp | |
| `weight` | number | kg |
| `height` | number | cm |
| `chest` | number? | |
| `waist` | number? | |
| `hips` | number? | |
| `notes` | string? | |

#### Subcollection: `users/{uid}/workouts/{docId}`

| Field | Type | Notes |
|---|---|---|
| `date` | timestamp | |
| `exercise` | string | |
| `sets` | number | |
| `reps` | number | |
| `weight` | number | |
| `duration` | number | minutes |
| `notes` | string? | |

---

### `gyms/{gymId}`

| Field | Type | Notes |
|---|---|---|
| `ownerUid` | string | |
| `gymName` | string | |
| `defaultFee` | number | |
| `status` | string | `active` / `suspended` / `blocked` |
| `isSaaSActive` | boolean | controls digital features independently |
| `registrationCode` | string | used by members to join via QR scan |
| `currentAttendanceQrToken` | string | rotated daily by Cloud Function |
| `attendanceQrExpiresAt` | timestamp | |
| `attendanceQrLastGeneratedAt` | timestamp | |
| `depositAccounts` | array of maps | payment account details (see below) |
| `createdAt` | timestamp | |

**`depositAccounts` map shape:**
```
{
  accountTitle:  string,
  accountNumber: string,
  bankName:      string,   // e.g. "Easypaisa", "JazzCash"
  accountType:   string    // "Wallet (EP/JC)" or "Bank Account"
}
```

> **No `gyms/{gymId}/staff` subcollection exists.** Staff are plain `users` documents with `role: 'staff'` and a `gymId` pointing to their gym. Querying staff = `users.where('gymId', ==, gymId).where('role', ==, 'staff')`.

#### Subcollection: `gyms/{gymId}/members/{uid}`

Document ID: same as the member's Firebase Auth UID

| Field | Type | Notes |
|---|---|---|
| `uid` | string | same as document ID |
| `name` | string | |
| `contactNumber` | string | |
| `plan` | string | `Monthly` / `6 Months` / `Yearly` |
| `currentFee` | number | |
| `feeStatus` | string | `paid` / `unpaid` / `pending` / `overdue` |
| `validUntil` | timestamp? | membership expiry date; `null` for new members |
| `photoUrl` | string? | |
| `isDeleted` | boolean | soft delete flag |
| `deletedAt` | timestamp? | |
| `lastPaidAt` | timestamp? | |
| `createdBy` | string | owner UID |
| `createdAt` | timestamp | |

#### Subcollection: `gyms/{gymId}/attendance/{docId}`

| Field | Type | Notes |
|---|---|---|
| `memberId` | string | member UID |
| `timestamp` | timestamp | exact check-in time (used for calendar) |
| `date` | string? | `YYYY-MM-DD` — legacy field, prefer `timestamp` |
| `status` | string | `present` |
| `markedBy` | string | `member` / `staff` / `qr` |
| `staffName` | string? | name of staff who marked, if applicable |

#### Subcollection: `gyms/{gymId}/payments/{docId}`

| Field | Type | Notes |
|---|---|---|
| `memberId` | string | |
| `amount` | number | |
| `method` | string | `cash` / `easypaisa` / `jazzcash` |
| `status` | string | `pending` / `completed` |
| `verified` | boolean | |
| `markedBy` | string | `staff` / `owner` / `online` |
| `plan` | string | membership plan paid for |
| `validUntil` | timestamp | new expiry after payment |
| `referenceCode` | string | |
| `screenshot` | string? | URL, for online payments only |
| `transactionId` | string | |
| `staffName` | string? | staff who recorded it, if applicable |
| `timestamp` | timestamp | |
| `createdAt` | timestamp | |
| `updatedAt` | timestamp | |

#### Subcollection: `gyms/{gymId}/payouts/{docId}`

| Field | Type | Notes |
|---|---|---|
| `amount` | number | |
| `status` | string | `pending` / `processed` |
| `createdAt` | timestamp | |
| `processedAt` | timestamp? | |

#### Subcollection: `gyms/{gymId}/expenses/{docId}`

| Field | Type | Notes |
|---|---|---|
| `category` | string | |
| `amount` | number | |
| `description` | string | |
| `date` | timestamp | |
| `createdBy` | string | owner UID |
| `createdAt` | timestamp | |
| `notes` | string? | |

#### Subcollection: `gyms/{gymId}/notifications/{docId}`

| Field | Type | Notes |
|---|---|---|
| `type` | string | e.g. `member_deleted_unpaid` |
| `message` | string | |
| `memberId` | string | related member UID |
| `isRead` | boolean | |
| `createdAt` | timestamp | |

#### Subcollection: `gyms/{gymId}/pos_reports_history/{docId}`

Auto-saved on every PDF export from the analytics screen.

| Field | Type | Notes |
|---|---|---|
| `gymName` | string | |
| `adminId` | string | owner UID who generated it |
| `fileName` | string | |
| `downloadUrl` | string | Firebase Storage URL to open the PDF |
| `sortKey` | string | ISO 8601 datetime string — used for orderBy without a composite index |
| `generatedAt` | timestamp | |
| `summary` | map | snapshot of analytics at export time (see below) |

**`summary` map shape:**
```
{
  totalRevenue:    number,
  cashRevenue:     number,
  onlineRevenue:   number,
  totalMembers:    number,
  activeMembers:   number,
  overdueMembers:  number,
  todayAttendance: number,
  monthAttendance: number,
  totalExpenses:   number,
  netProfit:       number,
}
```

---

#### Subcollection: `gyms/{gymId}/conversations/{conversationId}`

> `conversationId` is derived as `${uid1}_${uid2}` with UIDs sorted alphabetically, so the same document is always found regardless of who initiates.

| Field | Type | Notes |
|---|---|---|
| `participants` | string[] | exactly two UIDs |
| `lastMessage` | string | message preview |
| `lastMessageTime` | timestamp | |
| `lastSenderId` | string? | UID of last sender |
| `createdAt` | timestamp | |

#### Subcollection: `gyms/{gymId}/conversations/{conversationId}/messages/{docId}`

| Field | Type | Notes |
|---|---|---|
| `senderId` | string | |
| `senderName` | string | |
| `senderRole` | string | `owner` / `staff` / `member` |
| `message` | string | |
| `timestamp` | timestamp | |
| `isRead` | boolean | |

---

### `config/company` (singleton document)

| Field | Type | Notes |
|---|---|---|
| `platformFeePercent` | number | default `10` — used for owner balance calculation |
| `lastUpdated` | timestamp | |

---

## Key Patterns

### Staff Have No Subcollection
Staff users are `users/{uid}` documents with `role: 'staff'`. Their permissions (`canMarkAttendance`, `canCollectFees`) live directly on that document. Promoting a member to staff = update `role` + write `permissions` on the `users` doc. No separate subcollection.

### Soft Deletes
`users` and `gyms/{gymId}/members` use `isDeleted: true` + `deletedAt` instead of hard deletes. This preserves names in historical payment and attendance records.

### QR Attendance
The Cloud Function `rotateAttendanceQrDaily` runs at midnight (Asia/Karachi) and rotates `currentAttendanceQrToken` on every gym doc. Staff scan this token; stale tokens are rejected. Member self-attendance uses `markedBy: 'member'`.

### Conversation IDs
Derived deterministically: UIDs sorted alphabetically and joined with `_`. Guarantees the same document regardless of who opens the chat first.

### Timestamps
All writes use `FieldValue.serverTimestamp()`. Attendance has both a `timestamp` (Timestamp type, used for calendar lookups) and a legacy `date` string field (`YYYY-MM-DD`).

### Gym Access Levels
Two independent flags:
- `status` — `active` / `suspended` / `blocked` (controlled by super admin)
- `isSaaSActive` — boolean; when `false`, blocks new member registrations and login

### Owner Balance Calculation
`available = totalCompletedPayments - (total × platformFeePercent / 100) - totalProcessedPayouts`
All figures come from `gyms/{gymId}/payments` and `gyms/{gymId}/payouts` subcollections.
