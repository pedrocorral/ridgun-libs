# Capítulo 29: A lib `ws` — Handshake WebSocket RFC 6455, Framing de 16/64 bits e Mascaramento XOR

## 1. Por que existe a lib `ws`?

Sejamos sinceros: o protocolo WebSocket (RFC 6455) combina um handshake SHA-1 + Base64 com tramas binárias de comprimento variável (7, 16 ou 64 bits) e mascaramento XOR obrigatório do cliente para o servidor.

A lib **`ws`** implementa a **RFC 6455** completa em Ridgun puro: cálculo de `Sec-WebSocket-Accept` (com SHA-1 RFC 3174 integrado para o GUID do handshake), cabeçalhos HTTP `101 Switching Protocols`, codificação e descodificação de tramas (`WsFrame`) de 7, 16 (`126`) e 64 bits (`127`), mascaramento XOR simétrico e construtores de tramas de texto, ping, pong e fecho.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`ws`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/ws.rg` (domínio `WS`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/ws.rglib` | Distribuição e importação direta com `import ws` |
| **Ficheiro compilado** | `target/ws.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libws.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import ws` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `ws`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `ws accept key : String -> String` | Calcula `Sec-WebSocket-Accept` (RFC 6455 §1.3) a partir de `Sec-WebSocket-Key` |
| `ws build upgrade request / ws build upgrade response` | Formata as mensagens HTTP/1.1 de negociação (upgrade handshake) WebSocket |
| `ws encode frame / ws decode frame` | Codifica e descodifica tramas `WsFrame` (`fin`, `opcode`, `masked`, `mask_key`, `payload`) |
| `ws text frame / ws ping frame / ws pong frame / ws close frame` | Construtores de tramas de alto nível e extratores de código de fecho (`1000` normal) |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `ws`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import ws

fn :: negociar y enviar (client_key : String) => (String, String)
      negociar y enviar client_key =
        resp  = ws build upgrade response client_key
        trama = ws encode frame (ws text frame "hola-tiempo-real" False "")
        (resp, trama)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `ws` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import ws

fn :: decodificar trama cliente (clave4 : String) (msg : String) => String
      decodificar trama cliente clave4 msg =
        wire = ws encode frame (ws text frame msg True clave4)
        res  = ws decode frame wire
        ws frame payload res
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Correspondência exata com o vetor oficial RFC 6455 (`"dGhlIHNhbXBsZSBub25jZQ=="` $\rightarrow$ `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="`) e desmascaramento automático em `ws decode frame`.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_ws.rg`.
