class Revenues {
  final String id;
  final int? accountId; // <-- ADICIONAR ESTA LINHA
  final DateTime data;
  final double preco;
  final String descricaoDaReceita;
  final String tipoReceita;

  const Revenues({
    required this.id,
    this.accountId, // <-- ADICIONAR AQ
    required this.data,
    required this.preco,
    required this.descricaoDaReceita,
    required this.tipoReceita,
  });

  factory Revenues.fromMap(Map<String, dynamic> map) {
    return Revenues(
      id: map['id'] as String,
      accountId: map['accountId'] as int?, // <-- ADICIONAR AQ (pode ser nulo)
      data: DateTime.parse(map['data'] as String),
      preco: map['preco'] as double,
      descricaoDaReceita: map['descricaoDaReceita'] as String,
      tipoReceita: map['tipoReceita'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId, // <-- ADICIONAR AQ
      'data': data.toIso8601String(),
      'preco': preco,
      'descricaoDaReceita': descricaoDaReceita,
      'tipoReceita': tipoReceita,
    };
  }

  // Método para criar uma cópia com alterações
  Revenues copyWith({
    String? id,
    int? accountId, // <-- ADICIONAR AQ
    DateTime? data,
    double? preco,
    String? descricaoDaReceita,
    String? tipoReceita,
  }) {
    return Revenues(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId, // <-- ADICIONAR AQ
      data: data ?? this.data,
      preco: preco ?? this.preco,
      descricaoDaReceita: descricaoDaReceita ?? this.descricaoDaReceita,
      tipoReceita: tipoReceita ?? this.tipoReceita,
    );
  }
}
