# Firebase setup for FocusZone

You already have `GoogleService-Info.plist` in the FocusZone target. Complete these steps so the app can use Firebase Auth (and later Firestore sync).

## 1. Add Firebase iOS SDK (Swift Package)

1. In Xcode: **File → Add Package Dependencies...**
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Choose **Up to Next Major** with version `11.0.0` (or latest).
4. Click **Add Package**, then select:
   - **FirebaseAuth**
   - **FirebaseFirestore** (for Phase 3 sync)
   - **FirebaseCore** (if not auto-linked)
5. Add to the **FocusZone** target (not the widget). Finish.

## 2. Configure Firebase in the app

`FocusZoneApp.swift` will need to call `FirebaseApp.configure()` at launch. This is added in Phase 2 when you wire in `FirebaseAuthService`.

## 3. Firebase Console (if not done)

- Create a project (or use existing) at [Firebase Console](https://console.firebase.google.com).
- Add an iOS app with your Bundle ID (`ios.focus.jf.com.Focus`).
- Download `GoogleService-Info.plist` and add it to the FocusZone target (you already have this).
- In **Authentication → Sign-in method**, enable **Anonymous**.

After adding the package and enabling Anonymous auth, the `FirebaseAuthService` in the project will compile and can sign in anonymously for future sync.

## 4. Firestore (for Phase 3 sync)

1. In Firebase Console, go to **Firestore Database** and create a database (production mode).
2. In **Rules**, use the contents of `firestore.rules` in this repo (or paste below), then **Publish**:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. The app syncs to `users/{uid}/tasks` and `users/{uid}/quickNotes`. No other setup needed.
