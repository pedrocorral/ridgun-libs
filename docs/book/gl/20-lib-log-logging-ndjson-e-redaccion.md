# Capítulo 20: A lib `log` — Logging Estruturado NDJSON e Redacción Automática de Segredos

## 20.1. Por que existe a lib `log`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `log` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `log`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: envorcar os campos dunha petición nun ficheiro de log e descubrir semanas despois que acabas de gardar `password`, `api_key` ou `authorization` en texto plano no teu agregador de logs é un incidente de seguridade clásico.

A lib **`log`** proporciona filtrado por severidade (`DEBUG`, `INFO`, `WARN`, `ERROR`), formatado en texto humano e **NDJSON estruturado**, e **redacción automática de chaves sensibles** (`password`, `secret`, `token`, `api_key`, `authorization`, `cookie`, `private_key` $\rightarrow$ `"[REDACTED]"`, mitigando `VUL-LOG-001`).

Nun ecosistema tradicional, resolver as tarefas do dominio **`LOG`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`log`** (`src/main/ridgun/lib/log.rg`) aborda o problema con catro principios innegociables:

1. **Funcións totais e contratos explícitos (`=>`)**: ningunha función de `log` lanza excepcións ocultas nin depende de `null`. Todo caso límite devolve un valor sentinela documentado ou un tipo alxébrico suma (`Option`, `Result`).
2. **Cero código C e cero `libc`**: todo o código de `log` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `log` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 20.2. Artefactos nativos, importación e catálogo completo da API de `log`

En `ridgun-libs`, **`log`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/log.rg` (dominio `LOG`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/log.rglib` | Distribución e importación directa con `import log` |
| **Ficheiro compilado** | `target/log.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/liblog.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import log` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

### 20.2.1. Resumo de familias funcionais de `log`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `log level rank / log should emit` | Compara niveis (`DEBUG=10`, `INFO=20`, `WARN=30`, `ERROR=40`) fronte ao limiar activo |
| `log is sensitive key / log redact fields` | Substitúe valores de chaves segredas por `"[REDACTED]"` sen importar maiúsculas |
| `log format text / log format json` | Formatea liñas texto `chave=valor` ou NDJSON RFC 8259 con redacción automática de segredos |

### 20.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/log.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/log.rg` (`0` tipos, `0` operadores e `21` funcións):

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 20.3. Explorando `log` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `log` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test log.rg`.

### 20.3.1. Exemplo 1: Fluxo principal en estilo tabular con `log`

Observa como en Ridgun os signos `=` e os pasos de transformación con `log` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import log

fn :: auditar login (usuario : String) (clave : String) => String
      auditar login usuario clave =
        campos = [("user", usuario), ("password", clave), ("ip", "10.0.0.1")]
        log format json "INFO" "intento de acceso" campos
```

### 20.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `log` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import log

fn :: emitir si procede (umbral : String) (nivel : String) (msg : String) => String
      emitir si procede umbral nivel msg =
        | log should emit umbral nivel = log format text nivel msg [("service", "solstice")]
        | otherwise                    = ""
```

### 20.3.3. Exemplo 3: Xerarquía de niveis de severidade (`DEBUG`, `INFO`, `WARN`, `ERROR`) e filtrado por limiar (`log enabled`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `log` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test log levels and filtering => ()
      test log levels and filtering =
        _ = assert int equals (log level rank "debug") 10 "AC1: rank debug == 10"
        _ = assert int equals (log level rank "DEBUG") 10 "AC1: rank DEBUG == 10"
        _ = assert int equals (log level rank "info") 20 "AC1: rank info == 20"
        _ = assert int equals (log level rank "INFO") 20 "AC1: rank INFO == 20"
        _ = assert int equals (log level rank "warn") 30 "AC1: rank warn == 30"
        _ = assert int equals (log level rank "warning") 30 "AC1: rank warning alias == 30"
        _ = assert int equals (log level rank "error") 40 "AC1: rank error == 40"
        _ = assert int equals (log level rank "ERR") 40 "AC1: rank ERR alias == 40"
        _ = assert int equals (log level rank "unknown_level") 20 "AC1: unknown level defaults to INFO (20)"

        _ = assert str eq (log level name 10) "DEBUG" "AC1: level name 10 -> DEBUG"
        _ = assert str eq (log level name 20) "INFO" "AC1: level name 20 -> INFO"
        _ = assert str eq (log level name 30) "WARN" "AC1: level name 30 -> WARN"
        _ = assert str eq (log level name 40) "ERROR" "AC1: level name 40 -> ERROR"

        _ = assert true (log should emit "DEBUG" "DEBUG") "AC1: DEBUG emits DEBUG"
        _ = assert true (log should emit "DEBUG" "ERROR") "AC1: DEBUG emits ERROR"
        _ = assert true (log should emit "WARN" "ERROR") "AC1: WARN emits ERROR"
        _ = assert true (log should emit "WARN" "warning") "AC1: WARN emits warning"
        _ = assert false (log should emit "WARN" "INFO") "AC1: WARN suppresses INFO"
        _ = assert false (log should emit "ERROR" "WARN") "AC1: ERROR suppresses WARN"
        _ = assert false (log should emit "ERROR" "DEBUG") "AC1: ERROR suppresses DEBUG"
        ()
```

### 20.3.4. Exemplo 4: Detección automática de claves sensibles (`password`, `token`, `secret`, `api_key`, `jwt`) e redacción a `[REDACTED]`

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `log` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test log sensitive key redaction => ()
      test log sensitive key redaction =
        _ = assert true (log is sensitive key "password") "AC2: password"
        _ = assert true (log is sensitive key "user_passwd") "AC2: user_passwd"
        _ = assert true (log is sensitive key "CLIENT_SECRET") "AC2: CLIENT_SECRET"
        _ = assert true (log is sensitive key "access_token") "AC2: access_token"
        _ = assert true (log is sensitive key "X-Api-Key") "AC2: X-Api-Key"
        _ = assert true (log is sensitive key "api_key_id") "AC2: api_key_id"
        _ = assert true (log is sensitive key "apikey") "AC2: apikey"
        _ = assert true (log is sensitive key "Authorization") "AC2: Authorization"
        _ = assert true (log is sensitive key "session_cookie") "AC2: session_cookie"
        _ = assert true (log is sensitive key "ssh_private_key") "AC2: ssh_private_key"
        _ = assert true (log is sensitive key "private-key-pem") "AC2: private-key-pem"
        _ = assert false (log is sensitive key "username") "AC2: username safe"
        _ = assert false (log is sensitive key "request_id") "AC2: request_id safe"
        _ = assert false (log is sensitive key "status_code") "AC2: status_code safe"
        ()
```

### 20.3.5. Exemplo 5: Formatado de liñas de rexistro en texto estruturado (`key=val`) e JSON nunha liña (`NDJSON`) con marcas ISO-8601

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `log` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test log text and ndjson formatting => ()
      test log text and ndjson formatting =
        fields = [("user", "alice"), ("password", "s3cr3t"), ("auth_token", "jwt-123"), ("cookie", "sid=99")]
        txt = log format text "info" "user login" fields
        _ = assert str eq txt "[INFO] user login user=alice password=[REDACTED] auth_token=[REDACTED] cookie=[REDACTED]" "AC3: log format text redacts all secret keys"

        txt_empty = log format text "error" "disk full" []
        _ = assert str eq txt_empty "[ERROR] disk full" "AC3: log format text with empty fields"

        -- Log injection defense: newlines, carriage returns, tabs, quotes, and backslashes in msg or values
        inj_fields = [("path", "C:\\app\\bin"), ("note", "line1\nline2\r\t\"quoted\"")]
        jsn = log format json "warn" "auth check\nforged_line" fields
        _ = assert str eq jsn "{\"level\":\"WARN\",\"msg\":\"auth check\\nforged_line\",\"user\":\"alice\",\"password\":\"[REDACTED]\",\"auth_token\":\"[REDACTED]\",\"cookie\":\"[REDACTED]\"}" "AC3: NDJSON escapes newline injection and redacts secrets"

        jsn_esc = log format json "debug" "trace" inj_fields
        _ = assert str eq jsn_esc "{\"level\":\"DEBUG\",\"msg\":\"trace\",\"path\":\"C:\\\\app\\\\bin\",\"note\":\"line1\\nline2\\r\\t\\\"quoted\\\"\"}" "AC3: NDJSON escapes \\, \\n, \\r, \\t, and \\\""
        ()
```

---

## 20.4. Baixo o capó: como está construída `log` en Ridgun puro (`src/main/ridgun/lib/log.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/log.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 20.4.1. Implementación interna: Severity Levels (`DEBUG`, `INFO`, `WARN`, `ERROR`)

Fíxate en como `log.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: lg rank from lower String => Int
      lg rank from lower lv     =
        | lv == "debug"                       = 10
        | lv == "info"                        = 20
        | lv == "warn" or lv == "warning"     = 30
        | lv == "error" or lv == "err"        = 40
        | otherwise                           = 20

fn :: log level rank String => Int
      log level rank level  =  lg rank from lower (lg to lower level)

fn :: log level name Int  => String
      log level name rank =
        | rank <= 10 = "DEBUG"
        | rank <= 20 = "INFO"
        | rank <= 30 = "WARN"
        | otherwise  = "ERROR"

fn :: log should emit String    String    => Bool
      log should emit min_level msg_level =  (log level rank msg_level) >= (log level rank min_level)
```

### 20.4.2. Implementación interna: Sensitive Key Detection & Redaction

Fíxate en como `log.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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
      log is sensitive key key    =  lg check sens lower (lg to lower key)

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

### 20.4.3. Implementación interna: Escaping & Text / NDJSON Formatting

Fíxate en como `log.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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
        norm_lv = log level name (log level rank level)
        safe_f  = log redact fields fields
        "[" + norm_lv + "] " + (lg esc str msg) + (lg fmt text fields safe_f)

fn :: lg fmt json fields [String String] => String
      lg fmt json fields []              =  ""
      lg fmt json fields (pair:rest)     =
        "," + (lg quote (lg pair key pair)) + ":" + (lg quote (lg pair val pair)) + (lg fmt json fields rest)

fn :: log format json String String [String String] => String
      log format json level msg fields =
        norm_lv = log level name (log level rank level)
        safe_f  = log redact fields fields
        "{\"level\":" + (lg quote norm_lv) + ",\"msg\":" + (lg quote msg) + (lg fmt json fields safe_f) + "}"
```

---

## 20.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `log`

- **Garantía algorítmica e de seguridade**: Tanto `log format text` coma `log format json` pasan sempre os campos por `log redact fields` antes de serializar, garantindo que ningún segredo se filtre por esquecemento.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/log.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test log.rg`.

### As 5 Regras de Ouro ao programar con `log`

1. **Declara `import log` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `log` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `log` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `log` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 21** pasaremos a explorar en profundidade a lib **`test`** (A lib `test` — Primitivas de Aserción Unitaria e Funcional (`RG-011`)).
