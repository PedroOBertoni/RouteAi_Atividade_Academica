import 'package:contratos/contratos.dart';

import '../dominio/comanda.dart';
import '../portas.dart';

final class ServicoCozinha {
  ServicoCozinha({required RepositorioComandas repositorio, required Publicador publicador})
      : _repositorio = repositorio,
        _publicador = publicador;

  static const consumidor = 'cozinha';

  final RepositorioComandas _repositorio;
  final Publicador _publicador;

  void assinarEventos(Assinador a) {
    a.assinar<PedidoCriado>(
      consumidor: consumidor,
      tipo: PedidoCriado.nome,
      tratar: (e) => _atualizar(
        e.pedidoId,
        (c) => c.registrarItens([for (final i in e.itens) '${i.quantidade}x ${i.nome}']),
      ),
    );
    a.assinar<PagamentoAprovado>(
      consumidor: consumidor,
      tipo: PagamentoAprovado.nome,
      tratar: (e) => _atualizar(e.pedidoId, (c) => c.registrarPagamento()),
    );
  }

  Future<void> concluir(String pedidoId) async {
    final c = await _obrigatoria(pedidoId);
    c.concluir();
    await _repositorio.salvar(c);
    await _publicador.publicar(PedidoPronto(pedidoId: pedidoId));
  }

  Future<void> recusar(String pedidoId, String motivo) async {
    final c = await _obrigatoria(pedidoId);
    c.recusar();
    await _repositorio.salvar(c);
    await _publicador.publicar(PedidoRecusado(pedidoId: pedidoId, motivo: motivo));
  }

  Future<List<Comanda>> listar() => _repositorio.listar();

  Future<void> _atualizar(String pedidoId, void Function(Comanda) mudar) async {
    final c = await _repositorio.buscar(pedidoId) ?? Comanda(pedidoId);
    mudar(c);
    final iniciou = c.iniciarSePossivel();
    await _repositorio.salvar(c);
    if (iniciou) await _publicador.publicar(PreparoIniciado(pedidoId: pedidoId));
  }

  Future<Comanda> _obrigatoria(String pedidoId) async =>
      await _repositorio.buscar(pedidoId) ??
      (throw OperacaoInvalida('Comanda inexistente: $pedidoId'));
}
