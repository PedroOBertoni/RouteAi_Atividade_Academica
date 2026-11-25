import 'package:contratos/contratos.dart';

import '../dominio/coordenada.dart';
import '../dominio/entrega.dart';
import '../dominio/prioridade.dart';
import '../dominio/rota.dart';
import '../portas.dart';

final class ServicoEntregas {
  ServicoEntregas({
    required RepositorioEntregas repositorio,
    required Geocodificador geocodificador,
    required EstimadorDeTrechos estimador,
    required Publicador publicador,
    DateTime Function() agora = DateTime.now,
  })  : _repositorio = repositorio,
        _geocodificador = geocodificador,
        _estimador = estimador,
        _publicador = publicador,
        _agora = agora;

  static const consumidor = 'entregas';

  final RepositorioEntregas _repositorio;
  final Geocodificador _geocodificador;
  final EstimadorDeTrechos _estimador;
  final Publicador _publicador;
  final DateTime Function() _agora;

  void assinarEventos(Assinador a) {
    a.assinar<PedidoCriado>(
      consumidor: consumidor,
      tipo: PedidoCriado.nome,
      tratar: (e) => _atualizar(
        e.pedidoId,
        (x) => x.registrarDestino((
          cliente: e.cliente,
          endereco: e.endereco,
          prometidoPara: e.prometidoPara,
          itens: [for (final i in e.itens) i.conservacao],
        )),
      ),
    );
    a.assinar<PedidoPronto>(
      consumidor: consumidor,
      tipo: PedidoPronto.nome,
      tratar: (e) => _atualizar(e.pedidoId, (x) => x.registrarPronta()),
    );
  }

  /// Monta a rota com tudo que está disponível e despacha.
  Future<Rota> despachar(Coordenada origem) async {
    final agora = _agora();
    final paradas = <Parada>[];
    final naoLocalizados = <String>[];
    final porPedido = <String, Entrega>{};

    final disponiveis = (await _repositorio.listar())
        .where((e) => e.situacao == SituacaoEntrega.disponivel);
    for (final e in disponiveis) {
      final posicao = await _geocodificador.localizar(e.destino.endereco);
      if (posicao == null) {
        naoLocalizados.add(e.pedidoId);
        continue;
      }
      porPedido[e.pedidoId] = e;
      paradas.add(Parada(
        pedidoId: e.pedidoId,
        endereco: e.destino.endereco,
        posicao: posicao,
        prometidoPara: e.destino.prometidoPara,
        prioridade: classificar(
          itens: e.destino.itens,
          prometidoPara: e.destino.prometidoPara,
          agora: agora,
        ),
      ));
    }

    final ordem = ordenar(origem, paradas);
    final trechos = await _estimador.estimar(origem, [for (final p in ordem) p.posicao]);
    final planejadas = calcularChegadas(agora, ordem, trechos);

    for (final p in planejadas) {
      final entrega = porPedido[p.parada.pedidoId]!..iniciar();
      await _repositorio.salvar(entrega);
      await _publicador.publicar(SaiuParaEntrega(
        pedidoId: entrega.pedidoId,
        chegadaEstimada: p.chegadaEstimada,
      ));
    }
    return Rota(planejadas, naoLocalizados: naoLocalizados);
  }

  Future<void> concluir(String pedidoId) async {
    final e = await _repositorio.buscar(pedidoId) ??
        (throw EntregaInvalida('Entrega inexistente: $pedidoId'));
    e.concluir();
    await _repositorio.salvar(e);
    await _publicador.publicar(EntregaConcluida(pedidoId: pedidoId));
  }

  Future<List<Entrega>> listar() => _repositorio.listar();

  Future<void> _atualizar(String pedidoId, void Function(Entrega) mudar) async {
    final e = await _repositorio.buscar(pedidoId) ?? Entrega(pedidoId);
    mudar(e);
    await _repositorio.salvar(e);
  }
}
