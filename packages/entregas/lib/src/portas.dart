import 'dominio/coordenada.dart';
import 'dominio/entrega.dart';

abstract interface class RepositorioEntregas {
  Future<void> salvar(Entrega entrega);
  Future<Entrega?> buscar(String pedidoId);
  Future<List<Entrega>> listar();
}

abstract interface class Geocodificador {
  /// `null` quando o endereço não é localizado na área atendida.
  Future<Coordenada?> localizar(String endereco);
}

abstract interface class EstimadorDeTrechos {
  /// Duração de cada trecho: origem→p[0], p[0]→p[1], ...
  Future<List<Duration>> estimar(Coordenada origem, List<Coordenada> paradas);
}
