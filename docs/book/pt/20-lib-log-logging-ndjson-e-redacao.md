# Capítulo 20: La lib `log` — Logging Estruturado NDJSON e Redação Automática de Segredos

## 1. Por que existe a lib `log`?

Sejamos sinceros: despejar os campos de um pedido num ficheiro de log e descobrir semanas depois que guardou `password`, `api_key` ou `authorization` em texto limpo no agregador de logs é um incidente de segurança clássico.

A lib **`log`** fornece filtragem por severidade (`DEBUG`, `INFO`, `WARN`, `ERROR`), formatação em texto humano e **NDJSON estruturado**, e **redação automática de chaves sensíveis** (`password`, `secret`, `token`, `api_key`, `authorization`, `cookie`, `private_key` $\rightarrow$ `"[REDACTED]"`, mitigando `VUL-LOG-001`).

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`log`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/log.rg` (domínio `LOG`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/log.rglib` | Distribuição e importação direta com `import log` |
| **Ficheiro compilado** | `target/log.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/liblog.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import log` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `log`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `log level rank / log should emit` | Compara níveis (`DEBUG=10`, `INFO=20`, `WARN=30`, `ERROR=40`) face ao limiar configurado |
| `log is sensitive key / log redact fields` | Substitui valores de chaves secretas por `"[REDACTED]"` independentemente de maiúsculas |
| `log format text / log format json` | Formata linhas de texto `chave=valor` ou NDJSON RFC 8259 com redação automática de segredos |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `log`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import log

fn :: auditar login (usuario : String) (clave : String) => String
      auditar login usuario clave =
        campos = [("user", usuario), ("password", clave), ("ip", "10.0.0.1")]
        log format json "INFO" "intento de acceso" campos
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `log` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import log

fn :: emitir si procede (umbral : String) (nivel : String) (msg : String) => String
      emitir si procede umbral nivel msg =
        | log should emit umbral nivel = log format text nivel msg [("service", "solstice")]
        | otherwise                    = ""
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Tanto `log format text` como `log format json` passam sempre os campos por `log redact fields` antes de serializar, garantindo que nenhum segredo vaze por esquecimento.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_log.rg`.
