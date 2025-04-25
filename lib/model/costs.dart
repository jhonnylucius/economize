class Costs {
  final String id;
  final DateTime data;
  final double preco;
  final String descricaoDaDespesa;
  final String tipoDespesa;

  const Costs({
    required this.id,
    required this.data,
    required this.preco,
    required this.descricaoDaDespesa,
    required this.tipoDespesa,
  });

  factory Costs.fromMap(Map<String, dynamic> map) {
    return Costs(
      id: map['id'] as String,
      // Mudança aqui - usar parse direto
      data: DateTime.parse(map['data']),
      preco: (map['preco'] as num).toDouble(),
      descricaoDaDespesa: map['descricaoDaDespesa'] as String,
      tipoDespesa: map['tipoDespesa'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // Mudança aqui - usar toIso8601String
      'data': data.toIso8601String(),
      'preco': preco,
      'descricaoDaDespesa': descricaoDaDespesa,
      'tipoDespesa': tipoDespesa,
    };
  }

  Costs copyWith({
    String? id,
    DateTime? data,
    double? preco,
    String? descricaoDaDespesa,
    String? tipoDespesa,
  }) {
    return Costs(
      id: id ?? this.id,
      data: data ?? this.data,
      preco: preco ?? this.preco,
      descricaoDaDespesa: descricaoDaDespesa ?? this.descricaoDaDespesa,
      tipoDespesa: tipoDespesa ?? this.tipoDespesa,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Costs &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          data == other.data &&
          preco == other.preco &&
          descricaoDaDespesa == other.descricaoDaDespesa &&
          tipoDespesa == other.tipoDespesa;

  @override
  int get hashCode =>
      id.hashCode ^
      data.hashCode ^
      preco.hashCode ^
      descricaoDaDespesa.hashCode ^
      tipoDespesa.hashCode;

  @override
  String toString() =>
      'Costs(id: $id, data: $data, preco: $preco, descricao: $descricaoDaDespesa, tipo: $tipoDespesa)';
}
