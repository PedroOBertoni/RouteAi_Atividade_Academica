import 'package:contratos/contratos.dart';

import 'canal.dart';

final class ServicoNotificacoes {
  ServicoNotificacoes(this._canal);

  static const consumidor = 'notificacoes';

  final CanalNotificacao _canal;
  final _jaAvisados = <String>{};

  void assinarEventos(Assinador a) {
    _avisar<PedidoCriado>(a, PedidoCriado.nome, (e) => 'Pedido recebido: ${e.total}.');
    _avisar<PagamentoAprovado>(a, PagamentoAprovado.nome, (e) => 'Pagamento aprovado.');
    _avisar<PagamentoRecusado>(a, PagamentoRecusado.nome, (e) => 'Pagamento recusado: ${e.motivo}.');
    _avisar<PreparoIniciado>(a, PreparoIniciado.nome, (e) => 'Seu pedido está sendo preparado.');
    _avisar<PedidoRecusado>(a, PedidoRecusado.nome, (e) => 'Pedido recusado: ${e.motivo}.');
    _avisar<PagamentoEstornado>(a, PagamentoEstornado.nome, (e) => 'Estorno de ${e.valor} realizado.');
    _avisar<SaiuParaEntrega>(a, SaiuParaEntrega.nome, (e) => 'Saiu para entrega.');
    _avisar<EntregaConcluida>(a, EntregaConcluida.nome, (e) => 'Pedido entregue. Bom apetite!');
  }

  void _avisar<E extends Evento>(Assinador a, String tipo, String Function(E) texto) {
    a.assinar<E>(
      consumidor: consumidor,
      tipo: tipo,
      tratar: (e) async {
        if (_jaAvisados.contains(e.id)) return;
        await _canal.enviar(e.pedidoId, texto(e));
        _jaAvisados.add(e.id);
      },
    );
  }
}
