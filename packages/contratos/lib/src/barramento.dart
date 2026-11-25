import 'evento.dart';

typedef Tratador<E extends Evento> = Future<void> Function(E evento);

/// Porta de saída: quem só publica não enxerga quem consome.
abstract interface class Publicador {
  Future<void> publicar(Evento evento);
}

/// Porta de entrada: cada [consumidor] tem a própria fila.
abstract interface class Assinador {
  void assinar<E extends Evento>({
    required String consumidor,
    required String tipo,
    required Tratador<E> tratar,
  });
}

abstract interface class Barramento implements Publicador, Assinador {}
