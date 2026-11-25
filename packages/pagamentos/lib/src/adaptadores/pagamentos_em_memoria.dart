import '../dominio/pagamento.dart';
import '../portas.dart';

final class PagamentosEmMemoria implements RepositorioPagamentos {
  final _dados = <String, Pagamento>{};
  @override
  Future<void> salvar(Pagamento p) async => _dados[p.pedidoId] = p;
  @override
  Future<Pagamento?> buscar(String pedidoId) async => _dados[pedidoId];
}
