import 'valores.dart';

/// Fato de negócio já ocorrido. Imutável e serializável.
///
/// O [id] é determinístico (`tipo/pedidoId`): cada tipo de evento acontece no
/// máximo uma vez por pedido, então reentregas e republicações têm o mesmo id
/// e podem ser descartadas pelo consumidor.
abstract base class Evento {
  Evento({required this.pedidoId, DateTime? ocorridoEm})
      : ocorridoEm = ocorridoEm ?? DateTime.now();

  final String pedidoId;
  final DateTime ocorridoEm;

  String get tipo;
  String get id => '$tipo/$pedidoId';

  Json dados();
}
