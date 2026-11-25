/// Módulo Catálogo: o que está à venda e por quanto.
library;

import 'package:contratos/contratos.dart' show Conservacao, Dinheiro;

final class Produto {
  const Produto(this.id, this.nome, this.preco, this.conservacao);
  final String id;
  final String nome;
  final Dinheiro preco;
  final Conservacao conservacao;
}

final class Cardapio {
  Cardapio(Iterable<Produto> produtos) : _produtos = {for (final p in produtos) p.id: p};
  final Map<String, Produto> _produtos;

  List<Produto> listar() => _produtos.values.toList();
  Produto? buscar(String id) => _produtos[id];
}
