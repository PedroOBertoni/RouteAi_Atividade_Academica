import 'dominio/comanda.dart';

abstract interface class RepositorioComandas {
  Future<void> salvar(Comanda comanda);
  Future<Comanda?> buscar(String pedidoId);
  Future<List<Comanda>> listar();
}
