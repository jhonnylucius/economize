class PriceHistory {
  final String id;
  final String itemId;
  final String locationId;
  final double price;
  final DateTime date;
  final double variation;

  PriceHistory({
    required this.id,
    required this.itemId,
    required this.locationId,
    required this.price,
    required this.date,
    this.variation = 0,
  });

  factory PriceHistory.withCalculatedVariation({
    required String id,
    required String itemId,
    required String locationId,
    required double price,
    required DateTime date,
    double? lastPrice,
  }) {
    final variation =
        lastPrice != null ? ((price - lastPrice) / lastPrice) * 100 : 0;

    return PriceHistory(
      id: id,
      itemId: itemId,
      locationId: locationId,
      price: price,
      date: date,
      variation: variation.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'location_id': locationId,
      'price': price,
      'date': date.millisecondsSinceEpoch,
      'variation': variation,
    };
  }

  factory PriceHistory.fromMap(Map<String, dynamic> map) {
    return PriceHistory(
      id: map['id'] as String,
      itemId: map['item_id'] as String,
      locationId: map['location_id'] as String,
      price: map['price']?.toDouble() ?? 0.0,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      variation: map['variation']?.toDouble() ?? 0.0,
    );
  }

  PriceHistory copyWith({
    String? id,
    String? itemId,
    String? locationId,
    double? price,
    DateTime? date,
    double? variation,
  }) {
    return PriceHistory(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      locationId: locationId ?? this.locationId,
      price: price ?? this.price,
      date: date ?? this.date,
      variation: variation ?? this.variation,
    );
  }
}
