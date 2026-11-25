import 'package:contratos/contratos.dart';

/// A ordem de declaração é a ordem do fluxo.
enum SituacaoPedido { aguardandoPagamento, pago, emPreparo, pronto, emRota, entregue, cancelado }

final class PedidoInvalido implements Exception {
  PedidoInvalido(this.mensagem);
  final String mensagem;
  @override
  String toString() => mensagem;
}

final class Pedido {
  Pedido({
    required this.id,
    required this.cliente,
    required this.endereco,
    required List<ItemPedido> itens,
    required this.prometidoPara,
  }) : itens = List.unmodifiable(itens) {
    if (cliente.trim().isEmpty) throw PedidoInvalido('Informe o cliente.');
    if (endereco.trim().isEmpty) throw PedidoInvalido('Informe o endereço.');
    if (itens.isEmpty) throw PedidoInvalido('O pedido precisa de ao menos um item.');
    if (itens.any((i) => i.quantidade < 1)) {
      throw PedidoInvalido('A quantidade deve ser maior que zero.');
    }
  }

  final String id;
  final String cliente;
  final String endereco;
  final List<ItemPedido> itens;
  final DateTime prometidoPara;

  SituacaoPedido _situacao = SituacaoPedido.aguardandoPagamento;
  SituacaoPedido get situacao => _situacao;

  /// Regra única do total: só o pedido sabe somar seus itens.
  Dinheiro get total => itens.fold(const Dinheiro(0), (t, i) => t + i.subtotal);

  /// Só avança. Evento atrasado, repetido ou fora de ordem não faz o pedido
  /// retroceder, então a ordem de chegada das mensagens não importa.
  void avancarPara(SituacaoPedido nova) {
    if (_situacao == SituacaoPedido.cancelado) return;
    if (nova == SituacaoPedido.cancelado) {
      if (_situacao.index < SituacaoPedido.pronto.index) _situacao = nova;
      return;
    }
    if (nova.index > _situacao.index) _situacao = nova;
  }
}
