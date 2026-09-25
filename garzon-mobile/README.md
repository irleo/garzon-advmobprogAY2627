# Garzon Advanced Mobile Programming

Flutter Product Explorer

## Run

```shell
flutter pub get
flutter run
```

The API host is configured in `assets/.env` and defaults to DummyJSON.

## Firebase configuration

The Android app (`com.example.garzon_advmobprog`) is registered with Firebase
project `advmobprogay2627`. Firebase Core initializes before the app starts, and
Firebase Authentication and Cloud Firestore support the Lab Activity 5 flows.
Choose DummyJSON or Firebase on the sign-in screen. Firebase uses email/password;
DummyJSON retains its username/password demo accounts.

Email/Password and Cloud Firestore have been enabled by the project owner.
Publish the included `firestore.rules` before using signup or profiles. They allow
only the signed-in owner to read/write `users/{uid}` and validate profile fields.
These rules deny access to other document paths; review before publishing to a
project shared with another app.

```shell
firebase deploy --only firestore:rules --project=advmobprogay2627
```

Firebase account controls are in Profile; logout is at the bottom of Settings.
Logout and account changes require confirmation. Successful signup ends the
temporary Firebase session and returns to login with a success message and the
email prefilled. Password fields have individual visibility icons.
If account creation succeeds but profile saving fails, retry the same
form, or sign in and choose Complete your profile. Passwords and Firebase tokens
are never written to profile documents or SharedPreferences. Usernames are display
labels, not unique login identifiers. Firebase carts are local to the current
home session and are cleared on logout; they never use DummyJSON user IDs.

To regenerate configuration, run from this directory:

```shell
flutterfire configure --project=advmobprogay2627 --platforms=android
```

Only Android is configured. Before running on web or iOS, rerun FlutterFire
configuration with those platforms selected.
