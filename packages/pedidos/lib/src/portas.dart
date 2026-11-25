import 'package:contratos/contratos.dart' show Conservacao, Dinheiro;

import 'dominio/pedido.dart';

abstract interface class RepositorioPedidos {
  Future<void> salvar(Pedido pedido);
  Future<Pedido?> buscar(String id);
  Future<List<Pedido>> listar();
}

/// O que Pedidos precisa saber de um produto. A interface pertence a quem
/// consome; Pedidos não conhece o módulo Catálogo.
abstract interface class ConsultaProduto {
  Future<ProdutoOfertado?> buscar(String produtoId);
}

final class ProdutoOfertado {
  const ProdutoOfertado({required this.nome, required this.preco, required this.conservacao});
  final String nome;
  final Dinheiro preco;
  final Conservacao conservacao;
}
