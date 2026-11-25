import 'dart:convert';
import 'dart:io';

import 'package:entregas/entregas.dart';
import 'package:plataforma/plataforma.dart';

/// Uso: dart run plataforma:servidor   (na raiz do repositório)
Future<void> main() async {
  final raiz = File.fromUri(Platform.script).parent.parent;
  final candidatos = [
    File('apps/plataforma/web/painel.html'),
    File('${raiz.path}/web/painel.html'),
    File('web/painel.html'),
  ];
  final html = candidatos.firstWhere((f) => f.existsSync()).readAsStringSync();
  final porta = int.parse(Platform.environment['PORTA'] ?? '8080');

  // Com a chave no ambiente, troca o mapa simulado pelo Google. Nada mais muda.
  final chave = Platform.environment['GOOGLE_MAPS_API_KEY'] ?? '';
  final plataforma = chave.isEmpty ? Plataforma() : _comGoogle(chave);

  await Servidor(plataforma, painelHtml: html).iniciar(porta: porta);
  stdout.writeln('Painel: http://localhost:$porta '
      '(mapa: ${chave.isEmpty ? 'simulado' : 'Google'})');
}

Plataforma _comGoogle(String chave) {
  final cliente = HttpClient();
  final google = GoogleMaps(
    chave: chave,
    buscar: (url) async {
      final resposta = await (await cliente.getUrl(url)).close();
      if (resposta.statusCode != 200) {
        throw HttpException('Google respondeu ${resposta.statusCode}');
      }
      return utf8.decoder.bind(resposta).join();
    },
  );
  return Plataforma(geocodificador: google, estimador: google);
}
