import 'package:contratos/contratos.dart';

import '../dominio/pagamento.dart';
import '../portas.dart';

final class ServicoPagamentos {
  ServicoPagamentos({
    required RepositorioPagamentos repositorio,
    required GatewayPagamento gateway,
    required Publicador publicador,
  })  : _repositorio = repositorio,
        _gateway = gateway,
        _publicador = publicador;

  static const consumidor = 'pagamentos';

  final RepositorioPagamentos _repositorio;
  final GatewayPagamento _gateway;
  final Publicador _publicador;

  void assinarEventos(Assinador a) {
    a.assinar<PedidoCriado>(consumidor: consumidor, tipo: PedidoCriado.nome, tratar: cobrar);
    a.assinar<PedidoRecusado>(consumidor: consumidor, tipo: PedidoRecusado.nome, tratar: estornar);
  }

  /// Idempotente: se o pedido já foi cobrado, apenas republica o resultado.
  Future<void> cobrar(PedidoCriado e) async {
    var pagamento = await _repositorio.buscar(e.pedidoId);
    if (pagamento == null) {
      final r = await _gateway.cobrar(chave: e.pedidoId, valor: e.total);
      pagamento = Pagamento(
        e.pedidoId,
        e.total,
        r.aprovado ? SituacaoPagamento.aprovado : SituacaoPagamento.recusado,
        motivo: r.motivo,
      );
      await _repositorio.salvar(pagamento);
    }
    switch (pagamento.situacao) {
      case SituacaoPagamento.aprovado:
        await _publicador
            .publicar(PagamentoAprovado(pedidoId: e.pedidoId, valor: pagamento.valor));
      case SituacaoPagamento.recusado:
        await _publicador
            .publicar(PagamentoRecusado(pedidoId: e.pedidoId, motivo: pagamento.motivo));
      case SituacaoPagamento.estornado:
        break;
    }
  }

  /// Compensação da saga.
  Future<void> estornar(PedidoRecusado e) async {
    final pagamento = await _repositorio.buscar(e.pedidoId);
    if (pagamento == null || !pagamento.podeEstornar) return;
    await _gateway.estornar(chave: e.pedidoId, valor: pagamento.valor);
    await _repositorio.salvar(pagamento.estornado());
    await _publicador.publicar(PagamentoEstornado(pedidoId: e.pedidoId, valor: pagamento.valor));
  }
}
