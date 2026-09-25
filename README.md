# Advanced Mobile Programming Activity

## Lab Activity 5: Discussion

The sign-in screen supports two login types. DummyJSON sends a username and
password to `/auth/login`, validates a saved demo session with `/auth/me`, and
refreshes expired tokens through `/auth/refresh`. Its users and cart writes are
demonstration data, so Firebase account changes are not offered for DummyJSON
accounts. The earlier SharedPreferences token storage remains limited to this
demo path.

Firebase sign-in uses email and password through the Authentication SDK. Signup
creates a Firebase identity, then saves first name, last name, age, contact number,
and username in the signed-in user's `users/{uid}` Firestore document. The UID is
kept as a string and is never converted into a DummyJSON numeric ID. Email comes
from Firebase Auth; passwords and Firebase tokens are not stored in Firestore or
preferences. Firebase manages session persistence and token refresh. A restored
session reloads the Firebase user and profile before opening the home screen.

`UserService` provides the common interface used by screens: `signIn`,
`createAccount`, `getUserData`, `signOut`, `updateUsername`, `deleteAccount`, and
`resetPasswordFromCurrentPassword`. It delegates Firebase operations to
`FirebaseAccountService` and preserves the existing DummyJSON implementation.
This keeps provider selection, persistence, and error handling out of the UI.
Switching providers clears the previous provider's session.

The signup form validates every required field and password confirmation. Input
formatters reject invalid typing and pasted values. Names accept Unicode letters,
spaces, apostrophes, and hyphens; usernames accept ASCII letters, numbers, and
underscores; age accepts whole digits; phone numbers accept digits and one leading
plus. Email syntax is checked separately, and password symbols remain allowed.
Service validation repeats these checks before writes. Profile
shows details appropriate to the login type. Firebase users can change their
display username, change their password after reauthentication, or permanently
delete their account after entering their current password and typing DELETE.
Successful signup signs out the temporary registration session and returns to
login with a success message; completing an existing profile keeps its session.
Logout at the bottom of Settings clears the authentication stack and disposes the
session's cart. Firebase carts are session-local; DummyJSON cart behavior remains
unchanged. Usernames are not unique and are not used for Firebase sign-in.

Logout, username updates, password changes, and account deletion show confirmation
dialogs before proceeding. Signup password fields each have a show/hide eye icon.

Auth and Firestore do not share a transaction. If signup creates an account but
cannot save its profile, the same form can retry without creating a second
identity. A missing profile can also be completed after sign-in. Deletion removes
the profile while the user can still authorize it, then deletes the identity. If
identity deletion fails, the service attempts to restore the profile and reports
an actionable error if recovery also fails.

Firebase adds real account creation, SDK-managed sessions, reauthentication for
sensitive changes, and owner-based database access. The included Firestore rules
allow each user to access only their own profile, reject collection listing, and
validate allowed fields and timestamps. The rules must be published to the
`advmobprogay2627` project before profile operations work; creating a database by
itself does not publish these rules.

### Run and verify 

From `garzon_advmobprog`, publish the reviewed rules using
`firebase deploy --only firestore:rules --project=advmobprogay2627`, then run
`flutter run` with an Android device connected. Only Android is configured.
Choose Firebase, create an account, restart the app to check restoration, update
the username, change the password, and verify that the new password works after
logout. Use a disposable account to verify deletion. Choose DummyJSON to verify
the existing `emilys` / `emilyspass` demo login and user-specific carts.

References: [Firebase password authentication](https://firebase.google.com/docs/auth/flutter/password-auth),
[Firebase user management](https://firebase.google.com/docs/auth/flutter/manage-users),
and [Firestore access rules](https://firebase.google.com/docs/firestore/security/rules-conditions).
