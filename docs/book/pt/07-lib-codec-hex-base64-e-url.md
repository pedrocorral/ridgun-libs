# Capítulo 07: A lib `codec` — Hex, Base64, Base64url, URL Percent-Encoding e JSON Leve

## 1. Por que existe a lib `codec`?

Sejamos sinceros: nada quebra mais depressa uma integração web do que confundir Base64 padrão (`+/=`) com Base64url (`-_` sem preenchimento) num token JWT, ou construir uma query string sem escapar caracteres.

A lib **`codec`** implementa as normas **RFC 4648** (Hex, Base64 e Base64url), **RFC 3986** (codificação percentual de URLs e `query encode` / `query decode`) e construtores/extratores rápidos de **JSON leve (RFC 8259)**.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`codec`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/codec.rg` (domínio `CODEC`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/codec.rglib` | Distribuição e importação direta com `import codec` |
| **Ficheiro compilado** | `target/codec.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libcodec.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import codec` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `codec`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `hex encode / hex decode / hex is valid` | Codificação hexadecimal RFC 4648 em minúsculas e descodificação validada |
| `base64 encode / base64 decode` | Base64 padrão RFC 4648 §4 com preenchimento `=` |
| `base64url encode / base64url decode` | Base64url seguro para URLs RFC 4648 §5 (`-`, `_`, sem preenchimento) |
| `url encode / url decode / query encode / query decode` | Codificação percentual RFC 3986 e dicionários de query string `k=v&...` |
| `json quote / json object / json get str / json get int` | Serialização JSON rápida sem AST e extração de chaves de primeiro nível |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `codec`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import codec

fn :: empaquetar parametros (usuario : String) (redir : String) => String
      empaquetar parametros usuario redir =
        token_b64 = base64url encode usuario
        query encode [("token", token_b64), ("next", redir)]
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `codec` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import codec

fn :: construir respuesta rapida (id : Int) (nombre : String) => (String, Int)
      construir respuesta rapida id nombre =
        doc = json object [("id", json int id), ("name", json quote nombre), ("ok", json bool True)]
        leido = json get int doc "id" 0
        (doc, leido)
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Rejeição determinística de entradas hexadecimais ou Base64 malformadas (devolvendo `""` sem leituras fora de limites) e reversibilidade exata $decode(encode(x)) == x$.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_codec.rg`.
