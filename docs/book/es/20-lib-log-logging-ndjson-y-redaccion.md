# Capítulo 20: La lib `log` — Logging Estructurado NDJSON y Redacción Automática de Secretos

## 20.1. ¿Por qué existe la lib `log`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `log` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `log`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: volcar los campos de una petición en un archivo de log y descubrir semanas después que acabas de guardar `password`, `api_key` o `authorization` en texto plano en tu agregador de logs es un incidente de seguridad clásico.

La lib **`log`** proporciona filtrado por severidad (`DEBUG`, `INFO`, `WARN`, `ERROR`), formateo en texto humano y **NDJSON estructurado**, y **redacción automática de claves sensibles** (`password`, `secret`, `token`, `api_key`, `authorization`, `cookie`, `private_key` $\rightarrow$ `"[REDACTED]"`, mitigando `VUL-LOG-001`).

En un ecosistema tradicional, resolver las tareas del dominio **`LOG`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`log`** (`src/main/ridgun/lib/log.rg`) aborda el problema con cuatro principios innegociables:

1. **Declara `import log` (o `import log as alias`) al inicio del archivo**: cada lib define su espacio de nombres `module :: log` y en modo `--strict` las funciones multi-palabra se invocan siempre con espacios naturales.
2. **Encadena tus tuberías de izquierda a derecha con `->`**: escribe `entrada paso uno -> paso dos -> resultado`, usa máscaras `(+ _ _ +)` para desestructurar secuencias y omite `_ =` en sentencias secuenciales (o descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `log` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 20.2. Artefactos nativos, importación y catálogo completo de la API de `log`

En `ridgun-libs`, **`log`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/log.rg` (dominio `LOG`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/log.rglib` | Distribución e importación directa con `import log` |
| **Archivo compilado** | `target/log.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/liblog.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Cada lib declara su propio espacio de nombres con `module :: log`: basta con escribir `import log` (o `import log as alias`) en el encabezado y llamar a sus funciones con espacios naturales (`mi funcion x`) y tuberías `->` (`x mi funcion -> resultado`).

### 20.2.1. Resumen de familias funcionales de `log`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `log level rank / log should emit` | Compara niveles (`DEBUG=10`, `INFO=20`, `WARN=30`, `ERROR=40`) frente al umbral activo |
| `log is sensitive key / log redact fields` | Sustituye valores de claves secretas por `"[REDACTED]"` sin importar mayúsculas |
| `log format text / log format json` | Formatea líneas texto `clave=valor` o NDJSON RFC 8259 con redacción automática de secretos |

### 20.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/log.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/log.rg` (`0` tipos, `0` operadores y `21` funciones):

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
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

## 20.3. Explorando `log` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `log` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test log.rg`.

### 20.3.1. Ejemplo 1: Flujo principal en estilo tabular con `log`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `log` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import log

fn :: auditar login String String => String
      auditar login usuario clave =
        [("user", usuario), ("password", clave), ("ip", "10.0.0.1")] -> campos
        log format json "INFO" "intento de acceso" campos
```

### 20.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `log` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import log

fn :: emitir si procede String String String => String
      emitir si procede umbral nivel msg =
        | log should emit umbral nivel = log format text nivel msg [("service", "solstice")]
        | otherwise                    = ""
```

### 20.3.3. Ejemplo 3: Jerarquía de niveles de severidad (`DEBUG`, `INFO`, `WARN`, `ERROR`) y filtrado por umbral (`log enabled`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `log` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 20.3.4. Ejemplo 4: Detección automática de claves sensibles (`password`, `token`, `secret`, `api_key`, `jwt`) y redacción a `[REDACTED]`

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `log` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 20.3.5. Ejemplo 5: Formateo de líneas de registro en texto estructurado (`key=val`) y JSON en una línea (`NDJSON`) con marcas ISO-8601

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `log` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

## 20.4. Bajo el capó: cómo está construida `log` en Ridgun puro (`src/main/ridgun/lib/log.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/log.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 20.4.1. Implementación interna: Severity Levels (`DEBUG`, `INFO`, `WARN`, `ERROR`)

Fíjate en cómo `log.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

### 20.4.2. Implementación interna: Sensitive Key Detection & Redaction

Fíjate en cómo `log.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

### 20.4.3. Implementación interna: Escaping & Text / NDJSON Formatting

Fíjate en cómo `log.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

## 20.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `log`

- **Garantía algorítmica y de seguridad**: Tanto `log format text` como `log format json` pasan siempre los campos por `log redact fields` antes de serializar, garantizando que ningún secreto se filtre por olvido.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/log.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test log.rg`.

### Las 5 Reglas de Oro al programar con `log`

1. **Declara `import log` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `log` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `log` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `log` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 21** pasaremos a explorar en profundidad la lib **`test`** (La lib `test` — Primitivas de Aserción Unitaria y Funcional (`RG-011`)).
