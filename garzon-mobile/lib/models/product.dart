class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.tags,
    required this.brand,
    required this.sku,
    required this.weight,
    required this.dimensions,
    required this.warrantyInformation,
    required this.shippingInformation,
    required this.availabilityStatus,
    required this.reviews,
    required this.returnPolicy,
    required this.minimumOrderQuantity,
    required this.meta,
    required this.images,
    required this.thumbnail,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final List<String> tags;
  final String brand;
  final String sku;
  final double weight;
  final ProductDimensions dimensions;
  final String warrantyInformation;
  final String shippingInformation;
  final String availabilityStatus;
  final List<ProductReview> reviews;
  final String returnPolicy;
  final int minimumOrderQuantity;
  final ProductMeta meta;
  final List<String> images;
  final String thumbnail;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      description: _asString(json['description']),
      category: _asString(json['category']),
      price: _asDouble(json['price']),
      discountPercentage: _asDouble(json['discountPercentage']),
      rating: _asDouble(json['rating']),
      stock: _asInt(json['stock']),
      tags: _asList(json['tags']).map(_asString).toList(growable: false),
      brand: _asString(json['brand']),
      sku: _asString(json['sku']),
      weight: _asDouble(json['weight']),
      dimensions: ProductDimensions.fromJson(_asMap(json['dimensions'])),
      warrantyInformation: _asString(json['warrantyInformation']),
      shippingInformation: _asString(json['shippingInformation']),
      availabilityStatus: _asString(json['availabilityStatus']),
      reviews: _asList(json['reviews'])
          .map((value) => ProductReview.fromJson(_asMap(value)))
          .toList(growable: false),
      returnPolicy: _asString(json['returnPolicy']),
      minimumOrderQuantity: _asInt(json['minimumOrderQuantity']),
      meta: ProductMeta.fromJson(_asMap(json['meta'])),
      images: _asList(json['images']).map(_asString).toList(growable: false),
      thumbnail: _asString(json['thumbnail']),
    );
  }
}

class ProductDimensions {
  const ProductDimensions({
    required this.width,
    required this.height,
    required this.depth,
  });

  final double width;
  final double height;
  final double depth;

  factory ProductDimensions.fromJson(Map<String, dynamic> json) {
    return ProductDimensions(
      width: _asDouble(json['width']),
      height: _asDouble(json['height']),
      depth: _asDouble(json['depth']),
    );
  }
}

class ProductReview {
  const ProductReview({
    required this.rating,
    required this.comment,
    required this.date,
    required this.reviewerName,
    required this.reviewerEmail,
  });

  final int rating;
  final String comment;
  final String date;
  final String reviewerName;
  final String reviewerEmail;

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      rating: _asInt(json['rating']),
      comment: _asString(json['comment']),
      date: _asString(json['date']),
      reviewerName: _asString(json['reviewerName']),
      reviewerEmail: _asString(json['reviewerEmail']),
    );
  }
}

class ProductMeta {
  const ProductMeta({
    required this.createdAt,
    required this.updatedAt,
    required this.barcode,
    required this.qrCode,
  });

  final String createdAt;
  final String updatedAt;
  final String barcode;
  final String qrCode;

  factory ProductMeta.fromJson(Map<String, dynamic> json) {
    return ProductMeta(
      createdAt: _asString(json['createdAt']),
      updatedAt: _asString(json['updatedAt']),
      barcode: _asString(json['barcode']),
      qrCode: _asString(json['qrCode']),
    );
  }
}

String _asString(Object? value) => value?.toString() ?? '';

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

List<dynamic> _asList(Object? value) =>
    value is List<dynamic> ? value : const <dynamic>[];

Map<String, dynamic> _asMap(Object? value) {
  return value is Map<String, dynamic> ? value : const <String, dynamic>{};
}
