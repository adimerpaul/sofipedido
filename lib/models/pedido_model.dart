class Pedido {
  final String id;
  final String clienteId;
  final DateTime dataPedido;
  final double total;

  Pedido({
    required this.id,
    required this.clienteId,
    required this.dataPedido,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clienteId': clienteId,
      'dataPedido': dataPedido.toIso8601String(),
      'total': total,
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> map) {
    return Pedido(
      id: map['id'],
      clienteId: map['clienteId'],
      dataPedido: DateTime.parse(map['dataPedido']),
      total: map['total'],
    );
  }
}