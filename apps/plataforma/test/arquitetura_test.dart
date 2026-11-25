import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Funções de aptidão (fitness functions): se alguém quebrar a arquitetura,
/// o teste quebra junto.
const negocio = {'catalogo', 'pedidos', 'pagamentos', 'cozinha', 'entregas', 'notificacoes'};

final raiz = _acharRaiz();

Directory _acharRaiz() {
  var d = Directory.current;
  while (!Directory('${d.path}/packages').existsSync()) {
    d = d.parent;
  }
  return d;
}

Iterable<File> fontes(String pacote) => Directory('${raiz.path}/packages/$pacote/lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

Iterable<String> importados(File f) =>
    RegExp(r"^(?:import|export) '([^']+)'", multiLine: true)
        .allMatches(f.readAsStringSync())
        .map((m) => m.group(1)!);

Set<String> dependencias(String pacote) {
  final y = loadYaml(File('${raiz.path}/packages/$pacote/pubspec.yaml').readAsStringSync()) as YamlMap;
  return {...?(y['dependencies'] as YamlMap?)?.keys.cast<String>()};
}

void main() {
  for (final m in negocio) {
    test('$m depende apenas de contratos', () {
      expect(dependencias(m), {'contratos'});
      for (final f in fontes(m)) {
        for (final i in importados(f).where((i) => i.startsWith('package:'))) {
          expect(i, startsWith('package:contratos/'), reason: f.path);
        }
      }
    });
  }

  test('contratos não depende de ninguém', () {
    expect(dependencias('contratos'), isEmpty);
  });

  test('mensageria conhece só contratos', () {
    expect(dependencias('mensageria'), {'contratos'});
  });

  test('domínio não importa aplicação, adaptador, porta nem dart:io', () {
    for (final m in negocio) {
      for (final f in fontes(m).where((f) => f.path.contains(RegExp(r'[\\/]dominio[\\/]')))) {
        for (final i in importados(f)) {
          expect(i, isNot(matches(RegExp(r'aplicacao|adaptadores|portas|dart:io'))),
              reason: f.path);
        }
      }
    }
  });

  test('aplicação não importa adaptador', () {
    for (final m in negocio) {
      for (final f in fontes(m).where((f) => f.path.contains(RegExp(r'[\\/]aplicacao[\\/]')))) {
        for (final i in importados(f)) {
          expect(i, isNot(contains('adaptadores')), reason: f.path);
        }
      }
    }
  });
}
