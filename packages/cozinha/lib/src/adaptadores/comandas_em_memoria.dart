import '../dominio/comanda.dart';
import '../portas.dart';

final class ComandasEmMemoria implements RepositorioComandas {
  final _dados = <String, Comanda>{};
  @override
  Future<void> salvar(Comanda c) async => _dados[c.pedidoId] = c;
  @override
  Future<Comanda?> buscar(String pedidoId) async => _dados[pedidoId];
  @override
  Future<List<Comanda>> listar() async => _dados.values.toList();
}
