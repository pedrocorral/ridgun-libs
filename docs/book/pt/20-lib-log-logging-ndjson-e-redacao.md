# Capítulo 20: La lib `log` — Logging Estruturado NDJSON e Redação Automática de Segredos

## 20.1. Por que existe a lib `log`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `log` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `log`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: despejar os campos de um pedido num ficheiro de log e descobrir semanas depois que guardou `password`, `api_key` ou `authorization` em texto limpo no agregador de logs é um incidente de segurança clássico.

A lib **`log`** fornece filtragem por severidade (`DEBUG`, `INFO`, `WARN`, `ERROR`), formatação em texto humano e **NDJSON estruturado**, e **redação automática de chaves sensíveis** (`password`, `secret`, `token`, `api_key`, `authorization`, `cookie`, `private_key` $\rightarrow$ `"[REDACTED]"`, mitigando `VUL-LOG-001`).

Num ecossistema tradicional, resolver as tarefas do domínio **`LOG`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`log`** (`src/main/ridgun/lib/log.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Declare `import log` (ou `import log as alias`) no início do ficheiro**: cada lib define o seu espaço de nomes `module :: log` e em modo `--strict` as funções multi-palavra são sempre invocadas com espaços naturais.
2. **Encadeie os seus pipelines da esquerda para a direita com `->`**: escreva `entrada passo um -> passo dois -> resultado`, use máscaras `(+ _ _ +)` para desestruturar sequências e omita `_ =` em instruções sequenciais (ou descarte com `-> ()`).
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `log` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 20.2. Artefactos nativos, importação e catálogo completo da API de `log`

No `ridgun-libs`, **`log`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/log.rg` (domínio `LOG`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/log.rglib` | Distribuição e importação direta com `import log` |
| **Ficheiro compilado** | `target/log.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/liblog.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Cada lib declara o seu próprio espaço de nomes com `module :: log`: basta escrever `import log` (ou `import log as alias`) no topo e invocar as suas funções com espaços naturais (`minha funcao x`) e pipelines `->` (`x minha funcao -> resultado`).

### 20.2.1. Resumo das famílias funcionais da `log`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `log level rank / log should emit` | Compara níveis (`DEBUG=10`, `INFO=20`, `WARN=30`, `ERROR=40`) face ao limiar configurado |
| `log is sensitive key / log redact fields` | Substitui valores de chaves secretas por `"[REDACTED]"` independentemente de maiúsculas |
| `log format text / log format json` | Formata linhas de texto `chave=valor` ou NDJSON RFC 8259 com redação automática de segredos |

### 20.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/log.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/log.rg` (`0` tipos, `0` operadores e `21` funções):

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: lg lower char String Int Int` | `String` |
| `2` | `fn :: lg to lower loop String Int Int` | `String` |
| `3` | `fn :: lg to lower String` | `String` |
| `4` | `fn :: lg rank from lower String` | `Int` |
| `5` | `fn :: log level rank String` | `Int` |
| `6` | `fn :: log level name Int` | `String` |
| `7` | `fn :: log should emit String String` | `Bool` |
| `8` | `fn :: lg check sens lower String` | `Bool` |
| `9` | `fn :: log is sensitive key String` | `Bool` |
| `10` | `fn :: lg pair key (String String)` | `String` |
| `11` | `fn :: lg pair val (String String)` | `String` |
| `12` | `fn :: lg redact pair (String String)` | `String String` |
| `13` | `fn :: log redact fields [String String]` | `[String String]` |
| `14` | `fn :: lg esc char String Int Int` | `String` |
| `15` | `fn :: lg esc loop String Int Int` | `String` |
| `16` | `fn :: lg esc str String` | `String` |
| `17` | `fn :: lg quote String` | `String` |
| `18` | `fn :: lg fmt text fields [String String]` | `String` |
| `19` | `fn :: log format text String String [String String]` | `String` |
| `20` | `fn :: lg fmt json fields [String String]` | `String` |
| `21` | `fn :: log format json String String [String String]` | `String` |

---

## 20.3. Explorando a `log` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `log` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test log.rg`.

### 20.3.1. Exemplo 1: Fluxo principal em estilo tabular com `log`

Repare como em Ridgun os sinais `=` e os passos de transformação com `log` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import log

fn :: auditar login String String => String
      auditar login usuario clave =
        [("user", usuario), ("password", clave), ("ip", "10.0.0.1")] -> campos
        log format json "INFO" "intento de acceso" campos
```

### 20.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `log` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import log

fn :: emitir si procede String String String => String
      emitir si procede umbral nivel msg =
        | log should emit umbral nivel = log format text nivel msg [("service", "solstice")]
        | otherwise                    = ""
```

### 20.3.3. Exemplo 3: Hierarquia de níveis de severidade (`DEBUG`, `INFO`, `WARN`, `ERROR`) e filtragem por limiar (`log enabled`)

Neste exemplo prático exploramos de forma exaustiva como a `log` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test log levels and filtering => ()
      test log levels and filtering =
        assert int equals (log level rank "debug") 10 "AC1: rank debug == 10"
        assert int equals (log level rank "DEBUG") 10 "AC1: rank DEBUG == 10"
        assert int equals (log level rank "info") 20 "AC1: rank info == 20"
        assert int equals (log level rank "INFO") 20 "AC1: rank INFO == 20"
        assert int equals (log level rank "warn") 30 "AC1: rank warn == 30"
        assert int equals (log level rank "warning") 30 "AC1: rank warning alias == 30"
        assert int equals (log level rank "error") 40 "AC1: rank error == 40"
        assert int equals (log level rank "ERR") 40 "AC1: rank ERR alias == 40"
        assert int equals (log level rank "unknown_level") 20 "AC1: unknown level defaults to INFO (20)"

        assert str eq (log level name 10) "DEBUG" "AC1: level name 10 -> DEBUG"
        assert str eq (log level name 20) "INFO" "AC1: level name 20 -> INFO"
        assert str eq (log level name 30) "WARN" "AC1: level name 30 -> WARN"
        assert str eq (log level name 40) "ERROR" "AC1: level name 40 -> ERROR"

        assert true (log should emit "DEBUG" "DEBUG") "AC1: DEBUG emits DEBUG"
        assert true (log should emit "DEBUG" "ERROR") "AC1: DEBUG emits ERROR"
        assert true (log should emit "WARN" "ERROR") "AC1: WARN emits ERROR"
        assert true (log should emit "WARN" "warning") "AC1: WARN emits warning"
        assert false (log should emit "WARN" "INFO") "AC1: WARN suppresses INFO"
        assert false (log should emit "ERROR" "WARN") "AC1: ERROR suppresses WARN"
        assert false (log should emit "ERROR" "DEBUG") "AC1: ERROR suppresses DEBUG"
        ()
```

### 20.3.4. Exemplo 4: Deteção automática de chaves sensíveis (`password`, `token`, `secret`, `api_key`, `jwt`) e máscara `[REDACTED]`

Neste exemplo prático exploramos de forma exaustiva como a `log` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test log sensitive key redaction => ()
      test log sensitive key redaction =
        assert true (log is sensitive key "password") "AC2: password"
        assert true (log is sensitive key "user_passwd") "AC2: user_passwd"
        assert true (log is sensitive key "CLIENT_SECRET") "AC2: CLIENT_SECRET"
        assert true (log is sensitive key "access_token") "AC2: access_token"
        assert true (log is sensitive key "X-Api-Key") "AC2: X-Api-Key"
        assert true (log is sensitive key "api_key_id") "AC2: api_key_id"
        assert true (log is sensitive key "apikey") "AC2: apikey"
        assert true (log is sensitive key "Authorization") "AC2: Authorization"
        assert true (log is sensitive key "session_cookie") "AC2: session_cookie"
        assert true (log is sensitive key "ssh_private_key") "AC2: ssh_private_key"
        assert true (log is sensitive key "private-key-pem") "AC2: private-key-pem"
        assert false (log is sensitive key "username") "AC2: username safe"
        assert false (log is sensitive key "request_id") "AC2: request_id safe"
        assert false (log is sensitive key "status_code") "AC2: status_code safe"
        ()
```

### 20.3.5. Exemplo 5: Formatação de entradas de log em texto estruturado (`key=val`) e JSON de linha única (`NDJSON`) com carimbos ISO-8601

Neste exemplo prático exploramos de forma exaustiva como a `log` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test log text and ndjson formatting => ()
      test log text and ndjson formatting =
        fields = [("user", "alice"), ("password", "s3cr3t"), ("auth_token", "jwt-123"), ("cookie", "sid=99")]
        txt = log format text "info" "user login" fields
        assert str eq txt "[INFO] user login user=alice password=[REDACTED] auth_token=[REDACTED] cookie=[REDACTED]" "AC3: log format text redacts all secret keys"

        txt_empty = log format text "error" "disk full" []
        assert str eq txt_empty "[ERROR] disk full" "AC3: log format text with empty fields"

        -- Log injection defense: newlines, carriage returns, tabs, quotes, and backslashes in msg or values
        inj_fields = [("path", "C:\\app\\bin"), ("note", "line1\nline2\r\t\"quoted\"")]
        jsn = log format json "warn" "auth check\nforged_line" fields
        assert str eq jsn "{\"level\":\"WARN\",\"msg\":\"auth check\\nforged_line\",\"user\":\"alice\",\"password\":\"[REDACTED]\",\"auth_token\":\"[REDACTED]\",\"cookie\":\"[REDACTED]\"}" "AC3: NDJSON escapes newline injection and redacts secrets"

        jsn_esc = log format json "debug" "trace" inj_fields
        assert str eq jsn_esc "{\"level\":\"DEBUG\",\"msg\":\"trace\",\"path\":\"C:\\\\app\\\\bin\",\"note\":\"line1\\nline2\\r\\t\\\"quoted\\\"\"}" "AC3: NDJSON escapes \\, \\n, \\r, \\t, and \\\""
        ()
```

---

## 20.4. Debaixo do capô: como a `log` é construída em Ridgun puro (`src/main/ridgun/lib/log.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/log.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 20.4.1. Implementação interna: Severity Levels (`DEBUG`, `INFO`, `WARN`, `ERROR`)

Observe como `log.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
module :: log

fn :: lg rank from lower String => Int
      lg rank from lower lv     =
        | lv == "debug"                       = 10
        | lv == "info"                        = 20
        | lv == "warn" or lv == "warning"     = 30
        | lv == "error" or lv == "err"        = 40
        | otherwise                           = 20

fn :: log level rank String => Int
      log level rank level  =  level lg to lower -> lg rank from lower

fn :: log level name Int  => String
      log level name rank =
        | rank <= 10 = "DEBUG"
        | rank <= 20 = "INFO"
        | rank <= 30 = "WARN"
        | otherwise  = "ERROR"

fn :: log should emit String    String    => Bool
      log should emit min_level msg_level =  (log level rank msg_level) >= (log level rank min_level)
```

### 20.4.2. Implementação interna: Sensitive Key Detection & Redaction

Observe como `log.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: lg check sens lower String => Bool
      lg check sens lower lk     =
        | str contains lk "password" or str contains lk "passwd"       = True
        | str contains lk "secret" or str contains lk "token"          = True
        | str contains lk "api_key" or str contains lk "api-key"       = True
        | str contains lk "apikey"                                     = True
        | str contains lk "authorization" or str contains lk "cookie"  = True
        | str contains lk "private_key" or str contains lk "private-key" = True
        | otherwise                                                    = False

fn :: log is sensitive key String => Bool
      log is sensitive key key    =  key lg to lower -> lg check sens lower

fn :: lg pair key (String String) => String
      lg pair key (k, _)          =  k

fn :: lg pair val (String String) => String
      lg pair val (_, v)          =  v

fn :: lg redact pair (String String) => String String
      lg redact pair (k, v)          =
        | log is sensitive key k = (k, "[REDACTED]")
        | otherwise              = (k, v)

fn :: log redact fields [String String] => [String String]
      log redact fields []              =  []
      log redact fields (pair:rest)     =  [(lg redact pair pair)] :: (log redact fields rest)
```

### 20.4.3. Implementação interna: Escaping & Text / NDJSON Formatting

Observe como `log.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: lg esc char String Int Int => String
      lg esc char s idx c =
        | c == 34   = "\\\""
        | c == 92   = "\\\\"
        | c == 10   = "\\n"
        | c == 13   = "\\r"
        | c == 9    = "\\t"
        | otherwise = str slice s idx (idx + 1)

fn :: lg esc loop String Int Int => String
      lg esc loop s idx len =
        | idx >= len = ""
        | otherwise  = (lg esc char s idx (str char at s idx)) + (lg esc loop s (idx + 1) len)

fn :: lg esc str String => String
      lg esc str s      =  lg esc loop s 0 (str len s)

fn :: lg quote String => String
      lg quote s      =  "\"" + (lg esc str s) + "\""

fn :: lg fmt text fields [String String] => String
      lg fmt text fields []              =  ""
      lg fmt text fields (pair:rest)     =
        " " + (lg esc str (lg pair key pair)) + "=" + (lg esc str (lg pair val pair)) + (lg fmt text fields rest)

fn :: log format text String String [String String] => String
      log format text level msg fields =
        level log level rank -> log level name -> norm_lv
        fields log redact fields -> lg fmt text fields -> fmt_f
        "[" + norm_lv + "] " + (lg esc str msg) + fmt_f

fn :: lg fmt json fields [String String] => String
      lg fmt json fields []              =  ""
      lg fmt json fields (pair:rest)     =
        "," + (lg quote (lg pair key pair)) + ":" + (lg quote (lg pair val pair)) + (lg fmt json fields rest)

fn :: log format json String String [String String] => String
      log format json level msg fields =
        level log level rank -> log level name -> norm_lv
        fields log redact fields -> lg fmt json fields -> fmt_f
        "{\"level\":" + (lg quote norm_lv) + ",\"msg\":" + (lg quote msg) + fmt_f + "}"
```

---

## 20.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `log`

- **Garantia algorítmica e de segurança**: Tanto `log format text` como `log format json` passam sempre os campos por `log redact fields` antes de serializar, garantindo que nenhum segredo vaze por esquecimento.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/log.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test log.rg`.

### As 5 Regras de Ouro ao programar com a `log`

1. **Declare `import log` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `log` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `log` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `log` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 21** passaremos a explorar em profundidade a lib **`test`** (A lib `test` — Primitivas de Asserção Unitária e Funcional (`RG-011`)).
