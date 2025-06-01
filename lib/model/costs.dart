class Costs {
  final String id;
  final DateTime data;
  final double preco;
  final String descricaoDaDespesa;
  final String tipoDespesa;
  final bool recorrente; // Campo adicionado
  final bool pago; // Campo adicionado
  final String?
      category; // Campo adicionado para compatibilidade com notificações

  const Costs({
    required this.id,
    required this.data,
    required this.preco,
    required this.descricaoDaDespesa,
    required this.tipoDespesa,
    this.recorrente = false,
    this.pago = false,
    this.category, // Pode ser nulo, usará tipoDespesa se necessário
  });

  factory Costs.fromMap(Map<String, dynamic> map) {
    return Costs(
      id: map['id'] as String,
      data: DateTime.parse(map['data']),
      preco: (map['preco'] as num).toDouble(),
      descricaoDaDespesa: map['descricaoDaDespesa'] as String,
      tipoDespesa: map['tipoDespesa'] as String,
      recorrente: (map['recorrente'] as int? ?? 0) == 1,
      pago: (map['pago'] as int? ?? 0) == 1,
      category: map['category'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data.toIso8601String(),
      'preco': preco,
      'descricaoDaDespesa': descricaoDaDespesa,
      'tipoDespesa': tipoDespesa,
      'recorrente': recorrente ? 1 : 0,
      'pago': pago ? 1 : 0,
      'category': category ?? tipoDespesa,
    };
  }

  Costs copyWith({
    String? id,
    DateTime? data,
    double? preco,
    String? descricaoDaDespesa,
    String? tipoDespesa,
    bool? recorrente,
    bool? pago,
    String? category,
  }) {
    return Costs(
      id: id ?? this.id,
      data: data ?? this.data,
      preco: preco ?? this.preco,
      descricaoDaDespesa: descricaoDaDespesa ?? this.descricaoDaDespesa,
      tipoDespesa: tipoDespesa ?? this.tipoDespesa,
      recorrente: recorrente ?? this.recorrente,
      pago: pago ?? this.pago,
      category: category ?? this.category,
    );
  }

  // Getter para compatibilidade com o sistema de notificações
  String get name => descricaoDaDespesa;
  String get categoryValue => category ?? tipoDespesa;
  DateTime? get dueDate =>
      data; // Para compatibilidade com o serviço de notificações

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Costs &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          data == other.data &&
          preco == other.preco &&
          descricaoDaDespesa == other.descricaoDaDespesa &&
          tipoDespesa == other.tipoDespesa &&
          recorrente == other.recorrente &&
          pago == other.pago;

  @override
  int get hashCode =>
      id.hashCode ^
      data.hashCode ^
      preco.hashCode ^
      descricaoDaDespesa.hashCode ^
      tipoDespesa.hashCode ^
      recorrente.hashCode ^
      pago.hashCode;

  @override
  String toString() =>
      'Costs(id: $id, data: $data, preco: $preco, descricao: $descricaoDaDespesa, tipo: $tipoDespesa, recorrente: $recorrente, pago: $pago)';
}
