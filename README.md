# RouteAI Delivery

O RouteAI Delivery é uma plataforma de delivery de alimentos desenvolvida em Dart para demonstrar como diferentes partes de um sistema podem trabalhar de forma assíncrona. O cliente registra um pedido e recebe a confirmação de que ele foi aceito; em seguida, eventos levam o pedido pelos módulos de pagamento, cozinha e entrega. Um painel web acompanha os pedidos, as filas e as mensagens em tempo real.

Este projeto é um trabalho de Arquitetura de Software do curso de Computação da Uni-FACEF, no 6º semestre, e dá continuidade ao [RouteAI](https://github.com/t4Facef/mobile-2), desenvolvido anteriormente pelo grupo.

## Equipe de desenvolvimento

- Pedro de Oliveira Bertoni
- João Pedro Lourenço Ferreira
- Rodolfo Paturalski Zuculo Filho

## Funcionalidades

- **Pedidos e cardápio:** consulta de produtos, validação dos itens e do endereço, cálculo do total e aceitação do pedido pela API HTTP.
- **Pagamento:** processamento simulado e idempotente, com novas tentativas quando a operadora fica indisponível e fila de mensagens mortas para reprocessamento.
- **Cozinha:** recebimento dos itens e da confirmação de pagamento por eventos; a fila pode ser pausada e retomada. A cozinha pode iniciar o preparo, marcar o pedido como pronto ou recusá-lo.
- **Estorno:** quando a cozinha recusa um pedido já pago, outro evento aciona a compensação simulada do pagamento.
- **Entrega:** organização e despacho das entregas, estimativa de chegada e conclusão do pedido.
- **Acompanhamento ao vivo:** painel web com estados dos pedidos, comandas, filas, avisos e eventos do sistema.
- **Notificações:** avisos ao cliente sobre o andamento do pedido e o resultado de ações, como a entrega e o estorno.

## Arquitetura e escopo

A aplicação é um **monólito modular**: os módulos têm responsabilidades próprias e se comunicam principalmente por eventos assíncronos, mas rodam em um único processo Dart. O pacote `apps/plataforma` faz a composição do sistema e oferece a API HTTP e o painel web. Os pacotes de negócio ficam em `packages/`, com contratos compartilhados e um barramento de eventos em memória.

Para manter a demonstração simples e local, o pagamento, o armazenamento e o mapa são simulados por padrão. Os dados ficam em memória e são reiniciados quando o servidor é encerrado. Se configurada a variável de ambiente `GOOGLE_MAPS_API_KEY`, o módulo de entregas pode usar o adaptador opcional do Google Maps; sem ela, usa o mapa local simulado.

O documento arquitetural está disponível em [`docs/documento-arquitetural.pdf`](docs/documento-arquitetural.pdf).

## Requisitos e execução

É necessário ter Dart 3.6 ou mais recente. O Dart também é instalado junto com o Flutter.

Na raiz do projeto, instale as dependências e inicie o servidor:

```sh
dart pub get
dart run plataforma:servidor
```

Abra [http://localhost:8080](http://localhost:8080) para usar o painel. A API e o painel são servidos localmente. Para usar outra porta, configure a variável de ambiente `PORTA` antes de iniciar o servidor.

## Testes e métricas

Execute os testes automatizados e as métricas de dependência e acoplamento com:

```sh
dart test apps/plataforma/test
dart run tool/metricas.dart
```

Os testes cobrem o fluxo do pedido, a idempotência, as novas tentativas, a fila de mensagens mortas, a cozinha pausada, a recusa com estorno, as regras de entrega e as restrições de dependência entre módulos.

## Roteiro de demonstração

1. **Pedido assíncrono:** crie um pedido e mostre que a API o aceita antes de o pagamento e o preparo terminarem. Acompanhe as mudanças de estado e os eventos no painel.
2. **Cozinha pausada:** pause a fila `cozinha` e crie outro pedido. O pagamento deve avançar enquanto a mensagem da cozinha aguarda na fila. Retome a fila e acompanhe o início do preparo.
3. **Falha de pagamento:** selecione **Fora do ar** na operadora e crie um pedido. Mostre as tentativas e a entrada na fila de mensagens mortas; depois selecione **Aprova** e use **Reprocessar mortas**.
4. **Recusa e compensação:** recuse na cozinha um pedido em preparo e mostre o cancelamento e o aviso do estorno simulado.
5. **Entrega:** marque pedidos como prontos, monte a rota e conclua uma entrega pelo painel.

## Estrutura do projeto

```text
apps/plataforma/  composição do sistema, API HTTP, painel e testes
packages/
  contratos/      eventos, valores e portas compartilhados
  mensageria/     barramento, filas, novas tentativas e mensagens mortas
  catalogo/       cardápio e produtos
  pedidos/        criação e ciclo de vida dos pedidos
  pagamentos/     cobrança e estorno
  cozinha/        comandas e preparo
  entregas/       rotas e despacho
  notificacoes/   avisos ao cliente
tool/metricas.dart  métricas de dependência entre pacotes
```
