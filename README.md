# NU Exchange — Lab Activity 6

## Firebase Part II: Real-time chat

Lab Activity 6 builds on the previous Firebase authentication activity with
real-time messaging between registered members.

### Features

- **Chat tab:** Lists members with completed Firebase profiles, excludes the
  signed-in user, and filters by name or email.
- **Conversation previews:** Shows the latest message, timestamp, unread dot and
  count (`99+` maximum label), with bold unread rows and recent conversations first.
- **Messaging:** Streams messages, animates sender/receiver bubbles, shows
  Sending/Sent/Seen states, and supports loading older messages. Failed sends keep
  the draft for retry.
- **Profile avatars:** Offers 12 preset icons and gallery photos saved per account
  on the device, plus optional Firebase Storage photo syncing.
- **Consistent design:** Uses cream and burgundy throughout the app, with dark mode
  and matching Product/Chat search bars.
- **Settings:** Houses username editing, password changes, account deletion, and
  logout. Notification/email toggles and NU email linking are preview features.
- **Shopping:** Preserves the product catalog and cart; Cart is in the app bar.

### Firestore structure and access

| Path | Purpose | Access |
| --- | --- | --- |
| `users/{uid}` | Private account details | Profile owner |
| `chatUsers/{uid}` | Member name and email | Signed-in members; owner writes |
| `chatRooms/{roomId}` | Two conversation participants | Participants |
| `chatRooms/{roomId}/messages/{messageId}` | Messages and read receipts | Participants; recipient updates receipts |

Room IDs are derived from sorted Firebase UIDs so both participants open the same
conversation. The directory is synchronized during registration and profile
loading. Existing accounts must sign in with this version to appear; accounts
without completed profiles are not listed. DummyJSON accounts retain shopping
features but cannot use Firebase chat.

The implementation uses participant-based access instead of the lab handout's
unrestricted read/write rule. Publish the updated rules before using chat previews.
Local avatars require no cloud setup; account-synced photos require Firebase
Storage and its included rules.

See [the Flutter app README](garzon-mobile/README.md) for setup, storage details,
limitations, and manual verification steps.

## Authentication retained from Lab Activity 5

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
shows details appropriate to the login type. In Settings, Firebase users can change their
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
allow each user to access only their own profile, reject private profile collection listing, and
validate allowed fields and timestamps. The rules must be published to the
`advmobprogay2627` project before profile operations work; creating a database by
itself does not publish these rules.

## Run and verify

From `garzon-mobile`, publish the reviewed rules using
`firebase deploy --only firestore:rules --project=advmobprogay2627`, then run
`flutter run` with an Android device connected. Only Android is configured.
For chat, sign in with two Firebase accounts on separate devices, confirm that
search excludes the current user, and exchange messages. Check previews, unread
counts, ordering, and Seen updates when opening the conversation. Choose a local
avatar and restart the app to check that it persists.

storation, update
the username, change the password, and verify that the new password works after
logout. Use a disposable account to verify deletion. Choose DummyJSON to verify
the existing `emilys` / `emilyspass` demo login and user-specific carts.

References: [Firebase password authentication](https://firebase.google.com/docs/auth/flutter/password-auth),
[Firebase user management](https://firebase.google.com/docs/auth/flutter/manage-users),
and [Firestore access rules](https://firebase.google.com/docs/firestore/security/rules-conditions).
