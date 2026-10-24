# Capítulo 08: A lib `json` — Árvore AST Recursiva RFC 8259, Pretty-Printer e Consultas por Caminho

## 1. Por que existe a lib `json`?

Sejamos sinceros: navegar num JSON aninhado em muitas linguagens estáticas obriga a escrever páginas de código repetitivo ou encadear dez `.and_then()` antes de ler uma simples porta.

A lib **`json`** fornece um analisador descendente recursivo completo para **RFC 8259** sobre o ADT algébrico `JsonVal` (`JnNull`, `JnBool`, `JnInt`, `JnStr`, `JnArr`, `JnObj`, `JnErr`), serialização compacta e indentada (`json pretty`) e consultas diretas por caminho com pontos (`"server.http.port"`, `"users.0.name"`).

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`json`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/json.rg` (domínio `JSON`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/json.rglib` | Distribuição e importação direta com `import json` |
| **Ficheiro compilado** | `target/json.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libjson.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import json` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `json`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `type JsonVal` | `JnNull | JnBool Bool | JnInt Int | JnStr String | JnArr [JsonVal] | JnObj [String JsonVal] | JnErr String` |
| `json parse / json is ok` | Analisa texto JSON numa árvore `JsonVal` e valida a ausência de `JnErr` |
| `json stringify / json pretty` | Serializa `JsonVal` em JSON compacto ou multilinha indentado |
| `json get path / json get str / json get int / json get bool` | Percorre objetos e listas aninhados através de caminhos com pontos (`"a.b.0.c"`) |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `json`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import json

fn :: leer config servidor (raw : String) => (String, Int, Bool)
      leer config servidor raw =
        doc  = json parse raw
        host = json get str doc "server.host" "127.0.0.1"
        port = json get int doc "server.port" 8080
        tls  = json get bool doc "server.tls.enabled" False
        (host, port, tls)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `json` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import json

fn :: construir manifiesto () => String
      construir manifiesto =
        nodo = JnObj [("app", JnStr "solstice"), ("workers", JnInt 8), ("tags", JnArr [JnStr "elf64", JnStr "rmm2"])]
        json pretty nodo 2
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Rejeição estrita de lixo residual após o valor raiz (`trailing garbage`), tratamento completo de sequências de escape e retorno seguro de `JnErr` sem exceções.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_json.rg`.
