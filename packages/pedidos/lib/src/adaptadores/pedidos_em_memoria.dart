import '../dominio/pedido.dart';
import '../portas.dart';

final class PedidosEmMemoria implements RepositorioPedidos {
  final _dados = <String, Pedido>{};
  @override
  Future<void> salvar(Pedido p) async => _dados[p.id] = p;
  @override
  Future<Pedido?> buscar(String id) async => _dados[id];
  @override
  Future<List<Pedido>> listar() async => _dados.values.toList();
}
