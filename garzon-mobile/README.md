# NU Exchange — Lab Activity 6

Firebase Part II: real-time chat, unread indicators, and profile avatars, built on
the existing product catalog and Firebase authentication flows.

## Run

```shell
flutter pub get
flutter run
```

The API host is configured in `assets/.env` and defaults to DummyJSON.

## Firebase configuration

The Android app (`com.example.garzon_advmobprog`) is registered with Firebase
project `advmobprogay2627`. Firebase Core initializes before the app starts, and
Firebase Authentication and Cloud Firestore support the chat and existing account flows.
Choose DummyJSON or Firebase on the sign-in screen. Firebase uses email/password;
DummyJSON retains its username/password demo accounts.

Email/Password and Cloud Firestore have been enabled by the project owner.
Publish the included `firestore.rules` before using signup or profiles. They allow
only the signed-in owner to read/write `users/{uid}` and validate profile fields.
Chat directory and conversation access are covered by the Lab Activity 6 rules
below. Other document paths remain denied.

```shell
firebase deploy --only firestore:rules --project=advmobprogay2627
```

## Lab Activity 6: Firebase chat

### Profile avatars

Choose avatar on Profile opens a grid of 12 preset icons, a local gallery option,
and an optional Firebase photo upload. Icons and local photos persist per account
on the current device, including demo accounts. They are not shared with other
devices or chat participants. Gallery images have a preview before saving and are
resized to fit 256 by 256 pixels while preserving their proportions.

Cloud photos use Firebase Storage and save their URL on the Firebase Auth profile.
Enable Storage for the configured Firebase project and publish `storage.rules`
before using cloud uploads (`firebase deploy --only storage --project=advmobprogay2627`).
Local avatars require no Storage setup. No cloud configuration is deployed by
these code changes. Uploaded photos use one object per account; automatic cleanup
of that object after account deletion is not implemented.

### Chat behavior

The chat list shows the latest message, its time, and unread counts (capped at
`99+`), with bold unread rows and recent conversations first. Previews read existing
message documents, so no history migration is needed. Opening a conversation
marks received messages read in batches of 100. Publish the updated Firestore
rules to allow members to query their own conversations. This classroom approach
uses two bounded message listeners per conversation; a larger deployment should
maintain server-side inbox summaries to reduce listener count.

The second navigation tab lists other Firebase members with case-insensitive
name/email search. Cart remains available from the app bar. Conversations stream
the latest 50 messages, offer older-message loading, animate incoming/outgoing
bubbles, and show Sending, Sent (server accepted), and Seen (recipient opened the
conversation). Failed sends preserve the draft. DummyJSON sessions show a Firebase
sign-in explanation instead of accessing chat.

Publish the updated rules using the command above before running this version.
`chatUsers/{uid}` contains only the member's name and email; private age/contact
profiles remain owner-only in `users/{uid}`. Registration and successful profile
loading synchronize the chat directory. Existing accounts must sign in once with
this version to appear; Firebase Auth accounts without completed profiles are not
listed. The member directory streams all entries to support full name/email
substring search for this classroom app. A larger deployment needs paginated
directory search. Messages are restricted to the two conversation participants.
The PDF's unrestricted read/write rule is intentionally replaced with these rules.

Manual verification with two Firebase accounts:

1. Complete both profiles, sign in on two devices, and open Chat.
2. Confirm each account sees the other but not itself; search by name and email.
3. Send messages both ways and confirm alignment, timestamps, and Seen updates.
4. Background the recipient app and confirm new messages remain Sent until opened.
5. Disconnect the sender: the write stays Sending until reconnected; rejected
   writes show an error and preserve the draft.
6. Return to the chat list and verify the preview, timestamp, unread badge, and
   recent-conversation ordering; open the unread conversation and check clearing.
7. Choose an icon or local photo in Profile, restart, and confirm it persists.
8. Confirm Cart, Settings account controls, and the theme toggle remain accessible.

These are manual verification instructions, not a record of completed device tests.

Rules have been edited locally; this implementation does not deploy Firebase
changes or migrate existing accounts automatically.

## Theme, profile, and settings

The app uses a shared cream-and-burgundy theme with a matching dark mode. Product
and Chat use matching search bars. Profile displays account details and an avatar
picker; duplicate account-action buttons have been removed. Settings contains
Edit profile (username), Change password, Delete account, and logout. Profile
refreshes after returning from Settings. Notification/email toggles are local
preview controls; NU email linking is a placeholder.

## Account behavior
Logout and account changes require confirmation. Successful signup ends the
temporary Firebase session and returns to login with a success message and the
email prefilled. Password fields have individual visibility icons.
If account creation succeeds but profile saving fails, retry the same
form, or sign in and choose Complete your profile. Passwords and Firebase tokens
are never written to profile documents or SharedPreferences. Usernames are display
labels, not unique login identifiers. Firebase carts are local to the current
home session and are cleared on logout; they never use DummyJSON user IDs.

## Platform configuration

To regenerate configuration, run from this directory:

```shell
flutterfire configure --project=advmobprogay2627 --platforms=android
```

Only Android is configured. Before running on web or iOS, rerun FlutterFire
configuration with those platforms selected.
