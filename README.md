# Advanced Mobile Programming Activities

## Lab Activity 2: Product API and Layered Design Pattern

The application follows a small layered architecture. `ProductService` owns the HTTP request to the
DummyJSON `/products` endpoint and turns network or response failures into readable service errors.
The service passes decoded JSON objects into `Product.fromJson`, where the model converts loosely
typed API values into strict Dart fields. `ProductScreen` requests the models asynchronously and then
renders loading, error, empty, and populated states without knowing how the HTTP response is decoded.

This separation keeps each responsibility focused: models describe data, services acquire data,
screens render and navigate, widgets provide reusable presentation, and `ThemeProvider` manages
application-wide UI state through Provider. Compared with placing API calls and JSON parsing directly
inside a widget, the layered design is easier to test, maintain, and extend.

### Enhancements

1. A search bar filters the fetched list by title, brand, or category.
2. Selecting a product card opens a dedicated details screen with pricing, stock, shipping, warranty,
   and review information.
3. A settings screen owns the light/dark mode switch and updates the whole app through Provider.
