# Advanced Mobile Programming Activity

## Lab Activity 3: Discussion

The cart feature follows the project's model-service-screen design pattern. `Cart` and
`CartProduct` convert DummyJSON responses into typed Dart objects. `CartService` owns
the HTTP work for retrieving cart 1 and posting product values to the add cart
endpoint. `CartProvider` keeps the cart synchronized across the main, detail, and cart
screens. `CartScreen` renders the products and totals and handles loading, empty, and
error states.

When a cart item is tapped, `CartScreen` uses `ProductService.getProductById` with the
cart product's ID. The returned `Product` is passed to the existing
`ProductDetailsScreen`, so both the product list and cart reuse the same details widget.

The updated structure separates API response models in `lib/models`, remote requests
in `lib/services`, shared state in `lib/providers`, reusable UI in `lib/widgets`, and
pages in `lib/screens`. This keeps JSON parsing and HTTP error handling outside the UI
while allowing screens to focus on rendering and navigation.

The application loads one cart through `GET /carts/1`. Adding a product uses
`POST /carts/add` with a `userId` and a `products` array containing the product `id`
and `quantity`. Quantity changes send the current product list to `PATCH /carts/1`.
Because DummyJSON simulates writes without permanently saving them, `CartProvider`
retains the returned changes for the current application session.

## Lab Activity 4: Discussion

Lab Activity 4 extends the existing model-service-provider-screen structure with
persistent authentication. `User` in `lib/models/user.dart` converts the login
response into typed fields: ID, username, name, email, gender, avatar, and session
tokens. `UserService` owns requests to `POST /auth/login`, `GET /auth/me`, and
`POST /auth/refresh`, along with saving and reading the user through
`shared_preferences`. The password is sent only to the login endpoint and is never
saved. The service wraps network timeouts, invalid responses, and storage failures
in errors that the screens can display.

Enhancement 1 is implemented in `SplashScreen`. The NU splash checks the saved
session and validates it with `/auth/me`. A valid session opens the home screen;
no session opens sign-in. An expired access token is refreshed when possible.
Rejected sessions are removed, while connection failures show a retry action
without erasing the saved session.

Enhancement 2 is implemented in `SignInScreen`. The custom form validates username
and password, supports password visibility, disables duplicate submissions, and
shows loading and error states. A successful login is saved by `UserService`
before replacing the navigation stack with the home screen. Both authentication
screens use the supplied NU image.

Enhancement 3 connects the saved `User` to `ProfileScreen` and `CartProvider`.
The profile displays the user's avatar, full name, username, email, gender, and ID.
Logging out removes only the application's session preference and clears the
authenticated navigation stack. The home screen owns a separate cart provider
for that user, which is disposed on logout; pending requests cannot notify a
disposed provider or overwrite another account's cart.

The cart now loads `GET /carts/user/{user.id}?limit=1` using the authenticated user's
ID, replacing the previous fixed `/carts/1` request. The first returned cart is the
active cart for this single-cart interface, and its owner is checked before it is
displayed. A user without a server cart starts with an empty local cart. Adding
products sends the saved user ID to `/carts/add`; updates to an existing cart use
the returned cart ID. Newly created carts remain local after the simulated POST,
because DummyJSON does not persist them for later PATCH requests. Refresh reloads
the server's original data, so simulated changes last only for the current session.
The checkout summary stays pinned above bottom navigation while items scroll.

The lab follows the handout's SharedPreferences session example with DummyJSON
demo accounts. SharedPreferences is not encrypted credential storage; a production
app should use platform-protected storage for tokens. Profile UI never renders
tokens, and logging out preserves unrelated preferences.

### Running the activity

From `garzon_advmobprog`, run `flutter pub get`, then `flutter run`.
Use the public DummyJSON sample account `emilys` / `emilyspass` to sign in.
Restart the app to check persistent sign-in, open Profile to inspect the saved
user, then open Cart to see that user's products. Log out and sign in with another
DummyJSON account to check user-specific cart loading.

API references: [DummyJSON authentication](https://dummyjson.com/docs/auth),
[DummyJSON carts](https://dummyjson.com/docs/carts), and
[SharedPreferences](https://pub.dev/packages/shared_preferences).
