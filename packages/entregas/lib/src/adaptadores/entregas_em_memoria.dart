import '../dominio/entrega.dart';
import '../portas.dart';

final class EntregasEmMemoria implements RepositorioEntregas {
  final _dados = <String, Entrega>{};
  @override
  Future<void> salvar(Entrega e) async => _dados[e.pedidoId] = e;
  @override
  Future<Entrega?> buscar(String pedidoId) async => _dados[pedidoId];
  @override
  Future<List<Entrega>> listar() async => _dados.values.toList();
}
