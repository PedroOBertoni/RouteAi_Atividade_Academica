# RouteAI Delivery

Plataforma de delivery de alimentos com **comunicação assíncrona**. Trabalho de Arquitetura de Software (Uni-FACEF, 6º semestre), evolução do [RouteAI](https://github.com/t4Facef/mobile-2).

Documento arquitetural: [docs/documento-arquitetural.pdf](docs/documento-arquitetural.pdf)

## Rodar

Precisa do Dart 3.6 ou mais novo (já vem com o Flutter).

```
dart pub get
dart run plataforma:servidor
```

Abra http://localhost:8080. Para outra porta, defina a variável de ambiente `PORTA`.

## Testes e métricas

```
dart test apps/plataforma/test
dart run tool/metricas.dart
```

## Estrutura

```
packages/
  contratos/      eventos, valores e portas (única dependência dos módulos)
  mensageria/     barramento: filas, novas tentativas, fila de mortas
  catalogo/  pedidos/  pagamentos/  cozinha/  entregas/  notificacoes/
apps/plataforma/  composição, API HTTP, painel e testes
tool/metricas.dart
```

## Roteiro de demonstração (5 minutos)

1. **Assíncrono.** Faça um pedido e mostre no painel: ele é aceito na hora e as mensagens chegam depois.
2. **Baixo acoplamento.** Pause a fila `cozinha` e faça outro pedido. Ele é aceito e pago, e a mensagem espera. Retome: o preparo começa.
3. **Falha.** Operadora "Fora do ar", novo pedido: três tentativas e fila de mortas. Volte para "Aprova" e clique em "Reprocessar mortas".
4. **Saga.** Recuse um pedido em preparo: ele é cancelado e o estorno aparece nos avisos.
5. **Rota.** Marque dois pedidos como prontos (pizza e refrigerante) e despache: a pizza vai primeiro.
6. **Prova.** Acrescente `import 'package:pedidos/pedidos.dart';` em um arquivo da cozinha e rode os testes: a arquitetura reprova.
