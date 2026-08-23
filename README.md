# Advanced Mobile Programming Activity

## Lab Activity 3: Discussion

The cart feature follows the project's model-service-screen design pattern. `Cart` and
`CartProduct` convert DummyJSON responses into typed Dart objects. `CartService` owns
the HTTP work for retrieving a cart by user ID and posting product values to the add
cart endpoint. `CartScreen` requests one user's cart from the service, renders its
products and totals, and handles loading, empty, and error states.

When a cart item is tapped, `CartScreen` uses `ProductService.getProductById` with the
cart product's ID. The returned `Product` is passed to the existing
`ProductDetailsScreen`, so both the product list and cart reuse the same details widget.

The updated structure separates API response models in `lib/models`, remote requests
in `lib/services`, shared state in `lib/providers`, reusable UI in `lib/widgets`, and
pages in `lib/screens`. This keeps JSON parsing and HTTP error handling outside the UI
while allowing screens to focus on rendering and navigation.

DummyJSON's get-by-user endpoint uses `GET /carts/user/{userId}`. The response still
contains a `carts` array, so the service validates the array and returns its first cart
to render only one user's cart. Adding a product uses `POST /carts/add` with a `userId`
and a `products` array containing the product `id` and `quantity`. DummyJSON simulates
the add operation and returns the created cart, but it does not permanently save it.

