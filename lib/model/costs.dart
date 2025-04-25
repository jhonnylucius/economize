class Costs {
  final String id;
  final String data; // Mantido como String conforme solicitado
  final double preco;
  final String? descricaoDaDespesa;
  final String tipoDespesa;

  Costs({
    required this.id,
    required this.data,
    required this.preco,
    this.descricaoDaDespesa,
    required this.tipoDespesa,
  }) {
    // Validações básicas
    if (preco < 0) {
      throw ArgumentError('Preço não pode ser negativo');
    }
    if (data.isEmpty) {
      throw ArgumentError('Data não pode estar vazia');
    }
    if (tipoDespesa.isEmpty) {
      throw ArgumentError('Tipo de despesa não pode estar vazio');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data,
      'preco': preco,
      'descricaoDaDespesa': descricaoDaDespesa,
      'tipoDespesa': tipoDespesa,
    };
  }

  factory Costs.fromMap(Map<String, dynamic> map) {
    return Costs(
      id: map['id'] as String,
      data: map['data'] as String,
      preco:
          (map['preco'] as num)
              .toDouble(), // Corrigido para aceitar int e double
      descricaoDaDespesa: map['descricaoDaDespesa'] as String?,
      tipoDespesa: map['tipoDespesa'] as String,
    );
  }

  // Métodos úteis para comparações e formatação
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

  // Clone com modificações
  Costs copyWith({
    String? id,
    String? data,
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
}
