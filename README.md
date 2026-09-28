# NU Exchange

NU Exchange is a Flutter mobile application for the NU community to browse
products, manage a cart, personalize a profile, and chat with other members.
It is developed as part of Advanced Mobile Programming coursework.

## Features

- **Shop:** Browse product listings, search by title, brand, or category, and view
  product details.
- **Cart:** Manage the current user's cart from the app bar.
- **Authentication:** Use Firebase email/password accounts or DummyJSON demo
  accounts, with session restoration and logout.
- **Chat:** Search members by name or email, exchange real-time messages, and see
  recent-message previews, timestamps, unread counts, and read receipts.
- **Profile:** View account details and choose preset avatars or gallery photos.
  Local avatars persist per account on the device; Firebase users can optionally
  sync a photo through Firebase Storage.
- **Settings:** Switch between light and dark themes, update a Firebase username,
  change a password, or delete an account with verification and confirmation.

The interface uses a shared cream-and-burgundy theme. Notification and email-offer
switches are preview controls, and NU email linking is a placeholder.

## Technology

| Component | Technology |
| --- | --- |
| Mobile application | Flutter and Dart |
| State management | Provider |
| Authentication | Firebase Authentication; DummyJSON for demo accounts |
| Profiles and messaging | Cloud Firestore |
| Optional cloud photos | Firebase Storage |
| Local preferences and avatars | SharedPreferences |
| Product data | DummyJSON REST API |
| Gallery selection | Image Picker |

## Project structure

```text
garzon-mobile/
  lib/
    models/       Typed application data
    providers/    Theme and cart state
    screens/      Application screens
    services/     Authentication, data access, and avatar storage
    utils/        Validation helpers and formatting
    widgets/      Reusable interface components
  assets/         App assets and API configuration
  test/           Automated tests
  firestore.rules Firestore access rules
  storage.rules   Profile-photo storage rules
  README.md       Lab Activity 6 implementation and verification guide
```

## Getting started

Install Flutter and connect an Android device or emulator, then run:

```shell
cd garzon-mobile
flutter pub get
flutter run
```

The API host is configured in `garzon-mobile/assets/.env` and defaults to
DummyJSON. The Android app is configured for Firebase project
`advmobprogay2627`. Firebase email/password authentication and Firestore must be
available, and the included Firestore rules must be deployed for account and chat
features. Cloud photo uploads additionally require Firebase Storage and its
included rules; local avatars do not.

Only Android currently has Firebase configuration. Configure additional platforms
before running their Firebase features.

## Account and data behavior

Firebase manages its own authentication sessions. Passwords and Firebase tokens
are not written to Firestore or SharedPreferences. Private profiles are readable
only by their owners, while the member directory exposes names and emails to
signed-in members. Conversations are restricted to their two participants.

Firebase members need a completed profile to appear in Chat. Existing accounts
join the directory when they sign in with this version. DummyJSON accounts provide
demo shopping access and do not support Firebase chat or account management.
Firebase carts last for the current home session; local avatars remain on the
device across sessions.

## Development

Run static analysis from the Flutter app directory:

```shell
flutter analyze
```

Device checks are needed to verify authentication, two-account messaging, gallery
selection, and optional cloud uploads. Static analysis alone does not verify live
Firebase behavior.

