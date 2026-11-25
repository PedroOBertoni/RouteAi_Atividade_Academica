typedef Json = Map<String, Object?>;

/// Valor monetário em centavos inteiros (sem erro de ponto flutuante).
final class Dinheiro {
  const Dinheiro(this.centavos);
  final int centavos;

  Dinheiro operator +(Dinheiro o) => Dinheiro(centavos + o.centavos);
  Dinheiro operator *(int n) => Dinheiro(centavos * n);

  @override
  bool operator ==(Object other) => other is Dinheiro && other.centavos == centavos;
  @override
  int get hashCode => centavos.hashCode;
  @override
  String toString() =>
      'R\$ ${centavos ~/ 100},${(centavos % 100).toString().padLeft(2, '0')}';
}

/// Como o produto se comporta durante o transporte.
enum Conservacao { quente, congelado, ambiente }

final class ItemPedido {
  const ItemPedido({
    required this.produtoId,
    required this.nome,
    required this.quantidade,
    required this.precoUnitario,
    required this.conservacao,
  });

  final String produtoId;
  final String nome;
  final int quantidade;
  final Dinheiro precoUnitario;
  final Conservacao conservacao;

  Dinheiro get subtotal => precoUnitario * quantidade;

  Json toJson() => {
        'produtoId': produtoId,
        'nome': nome,
        'quantidade': quantidade,
        'precoCentavos': precoUnitario.centavos,
        'conservacao': conservacao.name,
      };

  factory ItemPedido.fromJson(Json j) => ItemPedido(
        produtoId: j['produtoId'] as String,
        nome: j['nome'] as String,
        quantidade: j['quantidade'] as int,
        precoUnitario: Dinheiro(j['precoCentavos'] as int),
        conservacao: Conservacao.values.byName(j['conservacao'] as String),
      );
}
