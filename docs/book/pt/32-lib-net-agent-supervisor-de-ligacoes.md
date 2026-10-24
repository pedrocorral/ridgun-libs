# Capítulo 32: A lib `net_agent` — Supervisor de Ligações de Rede e Ponte de Eventos Não Bloqueante

## 1. Por que existe a lib `net_agent`?

Sejamos sinceros: num servidor real como o **Solstice**, aceitar ligações TCP é a parte fácil; o difícil é limitar o máximo de clientes simultâneos, desconectar clientes zombies inativos (*idle timeout*) e ligar o ciclo `ppoll` aos seus atores sem fugas de descritores.

A lib **`net_agent`** fecha o círculo do `ridgun-libs` unindo **`posix`**, **`socket`** e **`agent`**: gere tabelas de ligações supervisionadas (`NetSupervisor`), aplica limites de concorrência (`max_conns`), purga ligações inativas (`net evict idle`) e converte eventos de descritores do kernel em eventos tipados (`NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout`, `NetEvError`), além de fornecer um passo de eco TCP completo (`net tcp echo step`).

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`net_agent`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/net_agent.rg` (domínio `AGENT`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/net_agent.rglib` | Distribuição e importação direta com `import net_agent` |
| **Ficheiro compilado** | `target/net_agent.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libnet_agent.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import net_agent` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `net_agent`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `net supervisor new : Int -> Int -> NetSupervisor` | Cria um supervisor de ligações com limite `max_conns` e inatividade `idle_timeout_ms` |
| `net register conn / net record rx / net record tx / net close conn` | Regista sockets aceites, atualiza contadores de bytes/atividade e fecha pares |
| `net evict idle : NetSupervisor -> Int -> (NetSupervisor, [Int])` | Fecha e expulsa ligações inativas além de `idle_timeout_ms`, devolvendo os respetivos FDs |
| `net poll fd : Int -> Bool -> Int -> NetEvent` | Ponte `wait fd` não bloqueante que emite `NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout` ou `NetEvError` |
| `net tcp echo step : String -> Int -> (Int, String)` | Passo completo de ponta a ponta TCP loopback (`listen/connect/accept/supervise/echo`) |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `net_agent`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import net_agent

fn :: supervisar clientes () => (Int, [Int])
      supervisar clientes =
        s0        = net supervisor new 100 5000
        (s1, _)   = net register conn s0 10 "10.0.0.1" 51000 1000
        (s2, _)   = net register conn s1 11 "10.0.0.2" 51001 6500
        (s3, exp) = net evict idle s2 7000
        (net active count s3, exp)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `net_agent` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import net_agent

fn :: probar puente tcp supervisado () => (Int, String)
      probar puente tcp supervisado =
        net tcp echo step "ping-supervisado" 1000
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Proteção automática contra esgotamento de descritores (`max_conns`), expulsão determinística de ligações inativas e fecho garantido de sockets em `net tcp echo step`.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_net_agent.rg`.
