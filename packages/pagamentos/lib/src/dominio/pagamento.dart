import 'package:contratos/contratos.dart' show Dinheiro;

enum SituacaoPagamento { aprovado, recusado, estornado }

final class Pagamento {
  const Pagamento(this.pedidoId, this.valor, this.situacao, {this.motivo = ''});
  final String pedidoId;
  final Dinheiro valor;
  final SituacaoPagamento situacao;
  final String motivo;

  bool get podeEstornar => situacao == SituacaoPagamento.aprovado;
  Pagamento estornado() => Pagamento(pedidoId, valor, SituacaoPagamento.estornado);
}
