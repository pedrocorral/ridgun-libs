# Capítulo 07: A lib `codec` — Hex, Base64, Base64url, URL Percent-Encoding e JSON Lixeiro

## 07.1. Por que existe a lib `codec`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `codec` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `codec`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: nada rompe máis rápido unha integración web ca confundir Base64 estándar (`+/=`) con Base64url (`-_` sen recheo) nun token JWT, ou construír unha query string concatenando cadeas sen escapar.

A lib **`codec`** implementa os estándares **RFC 4648** (Hex, Base64 e Base64url), **RFC 3986** (codificación porcentual de URLs e dicionarios `query encode` / `query decode`) e construtores/extractores rápidos de **JSON lixeiro (RFC 8259)**.

Nun ecosistema tradicional, resolver as tarefas do dominio **`CODEC`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`codec`** (`src/main/ridgun/lib/codec.rg`) aborda o problema con catro principios innegociables:

1. **Funcións totais e contratos explícitos (`=>`)**: ningunha función de `codec` lanza excepcións ocultas nin depende de `null`. Todo caso límite devolve un valor sentinela documentado ou un tipo alxébrico suma (`Option`, `Result`).
2. **Cero código C e cero `libc`**: todo o código de `codec` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `codec` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 07.2. Artefactos nativos, importación e catálogo completo da API de `codec`

En `ridgun-libs`, **`codec`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/codec.rg` (dominio `CODEC`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/codec.rglib` | Distribución e importación directa con `import codec` |
| **Ficheiro compilado** | `target/codec.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libcodec.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import codec` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

### 07.2.1. Resumo de familias funcionais de `codec`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `hex encode / hex decode / hex is valid` | Codificación hexadecimal RFC 4648 en minúsculas e descodificación validada |
| `base64 encode / base64 decode` | Base64 estándar RFC 4648 §4 con recheo `=` |
| `base64url encode / base64url decode` | Base64url seguro para URLs RFC 4648 §5 (`-`, `_`, sen recheo) |
| `url encode / url decode / query encode / query decode` | Codificación porcentual RFC 3986 e dicionarios de query string `k=v&...` |
| `json quote / json object / json get str / json get int` | Serialización JSON rápida sen AST e extracción de chaves de primeiro nivel |

### 07.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/codec.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/codec.rg` (`0` tipos, `0` operadores e `86` funcións):

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: cd raw byte ub Int` | `String` |
| `2` | `fn :: cd raw byte Int` | `String` |
| `3` | `fn :: cd hex lut Int` | `String` |
| `4` | `fn :: cd hex up lut Int` | `String` |
| `5` | `fn :: cd b64 lut Int` | `String` |
| `6` | `fn :: cd b64url lut Int` | `String` |
| `7` | `fn :: cd index of loop String String Int Int Int` | `Int` |
| `8` | `fn :: cd index of String String` | `Int` |
| `9` | `fn :: cd split char loop String Int Int Int Int` | `[String]` |
| `10` | `fn :: cd hex val Int` | `Int` |
| `11` | `fn :: cd valid hex loop String Int Int` | `Bool` |
| `12` | `fn :: cd is valid hex len String Int` | `Bool` |
| `13` | `fn :: is valid hex String` | `Bool` |
| `14` | `fn :: cd hex enc byte Int` | `String` |
| `15` | `fn :: cd hex enc loop String Int Int` | `String` |
| `16` | `fn :: hex encode String` | `String` |
| `17` | `fn :: cd hex dec loop String Int Int` | `String` |
| `18` | `fn :: hex decode String` | `String` |
| `19` | `fn :: cd b64 char String Int` | `String` |
| `20` | `fn :: cd b64 pad suffix String Bool` | `String` |
| `21` | `fn :: cd b64 enc step String Int String Bool Int` | `String` |
| `22` | `fn :: cd b64 enc rem String Int String Bool` | `String` |
| `23` | `fn :: base64 encode String` | `String` |
| `24` | `fn :: base64url encode String` | `String` |
| `25` | `fn :: cd b64 val Int` | `Int` |
| `26` | `fn :: cd strip b64 pad String Int` | `String` |
| `27` | `fn :: cd valid b64 body String Int Int` | `Bool` |
| `28` | `fn :: cd valid b64 raw String Int` | `Bool` |
| `29` | `fn :: is valid base64 String` | `Bool` |
| `30` | `fn :: cd b64 dec step String Int Int Int` | `String` |
| `31` | `fn :: cd b64 dec loop String Int Int` | `String` |
| `32` | `fn :: base64 decode String` | `String` |
| `33` | `fn :: base64url decode String` | `String` |
| `34` | `fn :: cd is unreserved Int` | `Bool` |
| `35` | `fn :: cd pct byte Int` | `String` |
| `36` | `fn :: cd url enc char String Int Int` | `String` |
| `37` | `fn :: cd url enc loop String Int Int` | `String` |
| `38` | `fn :: url encode String` | `String` |
| `39` | `fn :: cd url dec pct String Int Int Int Int` | `String` |
| `40` | `fn :: cd url dec at String Int Int Int` | `String` |
| `41` | `fn :: cd url dec loop String Int Int` | `String` |
| `42` | `fn :: url decode String` | `String` |
| `43` | `fn :: cd pair key (String String)` | `String` |
| `44` | `fn :: cd pair val (String String)` | `String` |
| `45` | `fn :: query string encode [String String]` | `String` |
| `46` | `fn :: cd parse kv at String Int` | `String String` |
| `47` | `fn :: cd parse kv item String` | `String String` |
| `48` | `fn :: cd parse qs list [String]` | `[String String]` |
| `49` | `fn :: cd strip leading q String` | `String` |
| `50` | `fn :: cd decode clean qs String` | `[String String]` |
| `51` | `fn :: query string decode String` | `[String String]` |
| `52` | `fn :: cd json esc code String Int Int` | `String` |
| `53` | `fn :: cd json esc loop String Int Int` | `String` |
| `54` | `fn :: json escape String` | `String` |
| `55` | `fn :: cd json unesc next String Int Int Int` | `String` |
| `56` | `fn :: cd json unesc loop String Int Int` | `String` |
| `57` | `fn :: json unescape String` | `String` |
| `58` | `fn :: json quote String` | `String` |
| `59` | `fn :: json int Int` | `String` |
| `60` | `fn :: json bool Bool` | `String` |
| `61` | `fn :: json null` | `String` |
| `62` | `fn :: cd join json items [String]` | `String` |
| `63` | `fn :: json array [String]` | `String` |
| `64` | `fn :: cd join json pairs [String String]` | `String` |
| `65` | `fn :: json object [String String]` | `String` |
| `66` | `fn :: cd quote pair vals [String String]` | `[String String]` |
| `67` | `fn :: json str object [String String]` | `String` |
| `68` | `fn :: cd is json ws Int` | `Bool` |
| `69` | `fn :: cd skip key sep String Int Int` | `Int` |
| `70` | `fn :: cd scan json str end String Int Int` | `Int` |
| `71` | `fn :: cd is tok delim Int` | `Bool` |
| `72` | `fn :: cd scan json tok end String Int Int` | `Int` |
| `73` | `fn :: cd extract json str vend String Int Int` | `String` |
| `74` | `fn :: cd extract json str vstart String Int` | `String` |
| `75` | `fn :: cd extract json str kpos String String Int` | `String` |
| `76` | `fn :: json get str String String` | `String` |
| `77` | `fn :: cd is signed int loop String Int Int` | `Bool` |
| `78` | `fn :: cd is valid int len String Int` | `Bool` |
| `79` | `fn :: cd is valid int str String` | `Bool` |
| `80` | `fn :: cd raw tok vstart String Int` | `String` |
| `81` | `fn :: cd raw tok kpos String String Int` | `String` |
| `82` | `fn :: cd raw json token String String` | `String` |
| `83` | `fn :: cd parse tok int String Int` | `Int` |
| `84` | `fn :: json get int String String Int` | `Int` |
| `85` | `fn :: cd parse tok bool String Bool` | `Bool` |
| `86` | `fn :: json get bool String String Bool` | `Bool` |

---

## 07.3. Explorando `codec` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `codec` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test codec.rg`.

### 07.3.1. Exemplo 1: Fluxo principal en estilo tabular con `codec`

Observa como en Ridgun os signos `=` e os pasos de transformación con `codec` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import codec

fn :: empaquetar parametros (usuario : String) (redir : String) => String
      empaquetar parametros usuario redir =
        token_b64 = base64url encode usuario
        query encode [("token", token_b64), ("next", redir)]
```

### 07.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `codec` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import codec

fn :: construir respuesta rapida (id : Int) (nombre : String) => (String, Int)
      construir respuesta rapida id nombre =
        doc = json object [("id", json int id), ("name", json quote nombre), ("ok", json bool True)]
        leido = json get int doc "id" 0
        (doc, leido)
```

### 07.3.3. Exemplo 3: Codificación e decodificación RFC 4648 Hexadecimal, Base64 estándar e Base64url seguro para URLs

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `codec` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test rfc4648 hex and base64 => ()
      test rfc4648 hex and base64 =
        -- 1. Hexadecimal RFC 4648 test vectors & negative validation
        _ = assert str eq (hex encode "") "" "hex_encode empty"
        _ = assert str eq (hex encode "foobar") "666f6f626172" "hex_encode foobar"
        _ = assert str eq (hex decode "666f6f626172") "foobar" "hex_decode lowercase"
        _ = assert str eq (hex decode "666F6F626172") "foobar" "hex_decode uppercase"
        _ = assert true (is valid hex "deadBEEF09") "is_valid_hex valid"
        _ = assert false (is valid hex "abc") "is_valid_hex odd length"
        _ = assert false (is valid hex "deadZZ") "is_valid_hex invalid chars"
        _ = assert str eq (hex decode "abc") "" "hex_decode odd -> empty"

        -- 2. Base64 & Base64url RFC 4648 test vectors
        _ = assert str eq (base64 encode "") "" "b64 empty"
        _ = assert str eq (base64 encode "f") "Zg==" "b64 f"
        _ = assert str eq (base64 encode "fo") "Zm8=" "b64 fo"
        _ = assert str eq (base64 encode "foo") "Zm9v" "b64 foo"
        _ = assert str eq (base64 encode "foob") "Zm9vYg==" "b64 foob"
        _ = assert str eq (base64 encode "fooba") "Zm9vYmE=" "b64 fooba"
        _ = assert str eq (base64 encode "foobar") "Zm9vYmFy" "b64 foobar"
        _ = assert str eq (base64 decode "Zg==") "f" "b64 dec f"
        _ = assert str eq (base64 decode "Zm8=") "fo" "b64 dec fo"
        _ = assert str eq (base64 decode "Zm9v") "foo" "b64 dec foo"
        _ = assert str eq (base64 decode "Zm9vYg==") "foob" "b64 dec foob"
        _ = assert str eq (base64 decode "Zm9vYmE=") "fooba" "b64 dec fooba"
        _ = assert str eq (base64 decode "Zm9vYmFy") "foobar" "b64 dec foobar"
        _ = assert str eq (base64url encode "foob") "Zm9vYg" "b64url nopad"
        _ = assert str eq (base64url decode "Zm9vYg") "foob" "b64url dec"
        _ = assert false (is valid base64 "A") "invalid base64 len%4==1"
        _ = assert false (is valid base64 "Zm$v") "invalid base64 char"
        _ = assert str eq (base64 decode "Zm$v") "" "invalid base64 -> empty"

        -- 3. LIB-8: Binary-safe decoding for raw octets >= 0x80 and 0x00
        raw4 = hex decode "c800ff41"
        _    = assert int equals (str len raw4) 4 "str_len (hex_decode c800ff41) == 4"
        _    = assert int equals (str char at raw4 0) 200 "raw4[0] == 0xc8"
        _    = assert int equals (str char at raw4 1) 0 "raw4[1] == 0x00"
        _    = assert int equals (str char at raw4 2) 255 "raw4[2] == 0xff"
        _    = assert int equals (str char at raw4 3) 65 "raw4[3] == 0x41"
        _    = assert str eq (hex encode raw4) "c800ff41" "hex_encode raw4 == c800ff41"
        _    = check binary roundtrip loop 10
        ()
```

### 07.3.4. Exemplo 4: Codificación porcentual RFC 3986 (`url encode`, `url decode`) e cadeas de consulta (`query encode`, `query get`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `codec` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test rfc3986 url and query strings => ()
      test rfc3986 url and query strings =
        raw = "hello world&x=1+2%"
        enc = url encode raw
        _   = assert str eq enc "hello%20world%26x%3D1%2B2%25" "url_encode"
        _   = assert str eq (url decode enc) raw "url_decode roundtrip"
        _   = assert str eq (url decode "a+b%20c") "a b c" "url_decode plus as space"
        qs  = query string encode [("q", "ridgun libs"), ("page", "2")]
        _   = assert str eq qs "q=ridgun%20libs&page=2" "query_string_encode"
        dec = query string decode ("?" + qs)
        _   = assert eq dec [("q", "ridgun libs"), ("page", "2")]
        ()
```

### 07.3.5. Exemplo 5: Escapado e formatado JSON lixeiro RFC 8259 (`json escape`, `json unescape`, `json encode kv`, `json get str/int/bool`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `codec` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test rfc8259 lightweight json => ()
      test rfc8259 lightweight json =
        esc = json escape "line1\n\"quoted\"\\tab\t"
        _   = assert str eq esc "line1\\n\\\"quoted\\\"\\\\tab\\t" "json_escape"
        _   = assert str eq (json unescape esc) "line1\n\"quoted\"\\tab\t" "json_unescape"
        doc = json object [("service", json quote "solstice"), ("port", json int 8443), ("tls", json bool True), ("extra", json null)]
        _   = assert str eq doc "{\"service\":\"solstice\",\"port\":8443,\"tls\":true,\"extra\":null}" "json_object"
        _   = assert str eq (json get str doc "service") "solstice" "json_get_str"
        _   = assert str eq (json get str doc "missing") "" "json_get_str missing"
        _   = assert int equals (json get int doc "port" 80) 8443 "json_get_int"
        _   = assert int equals (json get int doc "missing" 80) 80 "json_get_int fallback"
        _   = assert int equals (json get int doc "service" 80) 80 "json_get_int non-int fallback"
        _   = assert true (json get bool doc "tls" False) "json_get_bool"
        _   = assert false (json get bool doc "missing" False) "json_get_bool fallback"
        arr = json array [json int 1, json int 2, json quote "three"]
        _   = assert str eq arr "[1,2,\"three\"]" "json_array"
        s_o = json str object [("k1", "v1"), ("k2", "v\"2")]
        _   = assert str eq (json get str s_o "k2") "v\"2" "json_str_object escaped roundtrip"
        ()
```

---

## 07.4. Baixo o capó: como está construída `codec` en Ridgun puro (`src/main/ridgun/lib/codec.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/codec.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 07.4.1. Implementación interna: RFC 4648 Hexadecimal Encoding & Decoding

Fíxate en como `codec.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: cd hex val Int => Int
      cd hex val c   =
        | c >= 48 and c <= 57  = c - 48
        | c >= 65 and c <= 70  = (c - 65) + 10
        | c >= 97 and c <= 102 = (c - 97) + 10
        | otherwise            = 0 - 1

fn :: cd valid hex loop String Int Int => Bool
      cd valid hex loop s idx len =
        | idx >= len                           = True
        | (cd hex val (str char at s idx)) < 0 = False
        | otherwise                            = cd valid hex loop s (idx + 1) len

fn :: cd is valid hex len String Int => Bool
      cd is valid hex len s n =
        | (n % 2) != 0 = False
        | otherwise    = cd valid hex loop s 0 n

fn :: is valid hex String => Bool
      is valid hex s      =  cd is valid hex len s (str len s)

fn :: cd hex enc byte Int => String
      cd hex enc byte b   =
        ub  = ((b % 256) + 256) % 256
        hi  = ub / 16
        lo  = ub % 16
        tbl = cd hex lut 0
        (str slice tbl hi (hi + 1)) + (str slice tbl lo (lo + 1))

fn :: cd hex enc loop String Int Int => String
      cd hex enc loop s idx len =
        | idx >= len = ""
        | otherwise  = (cd hex enc byte (str char at s idx)) + (cd hex enc loop s (idx + 1) len)

fn :: hex encode String => String
      hex encode s      =  cd hex enc loop s 0 (str len s)

fn :: cd hex dec loop String Int Int => String
      cd hex dec loop s idx len =
        | idx >= len = ""
        | otherwise =
          hi = cd hex val (str char at s idx)
          lo = cd hex val (str char at s (idx + 1))
          (cd raw byte ((hi * 16) + lo)) + (cd hex dec loop s (idx + 2) len)

fn :: hex decode String => String
      hex decode s      =
        | not (is valid hex s) = ""
        | otherwise            = cd hex dec loop s 0 (str len s)
```

### 07.4.2. Implementación interna: RFC 4648 Standard Base64 & URL-Safe Base64url

Fíxate en como `codec.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: cd b64 char String Int => String
      cd b64 char tbl    idx =
        i = idx % 64
        str slice tbl i (i + 1)

fn :: cd b64 pad suffix String Bool => String
      cd b64 pad suffix suffix True = suffix
      cd b64 pad suffix _ False = ""

fn :: cd b64 enc step String Int String Bool Int => String
      cd b64 enc step s idx tbl pad rem =
        | rem <= 0 = ""
        | rem == 1 =
          b0   = str char at s idx
          out2 = (cd b64 char tbl (b0 / 4)) + (cd b64 char tbl ((b0 % 4) * 16))
          out2 + (cd b64 pad suffix "==" pad)
        | rem == 2 =
          b0   = str char at s idx
          b1   = str char at s (idx + 1)
          n    = (b0 * 256) + b1
          out3 = (cd b64 char tbl (n / 1024)) + (cd b64 char tbl ((n / 16) % 64)) + (cd b64 char tbl ((n % 16) * 4))
          out3 + (cd b64 pad suffix "=" pad)
        | otherwise =
          b0   = str char at s idx
          b1   = str char at s (idx + 1)
          b2   = str char at s (idx + 2)
          n    = (b0 * 65536) + (b1 * 256) + b2
          out4 = (cd b64 char tbl (n / 262144)) + (cd b64 char tbl ((n / 4096) % 64)) + (cd b64 char tbl ((n / 64) % 64)) + (cd b64 char tbl (n % 64))
          out4 + (cd b64 enc rem s (idx + 3) tbl pad)

fn :: cd b64 enc rem String Int String Bool => String
      cd b64 enc rem s idx tbl pad = cd b64 enc step s idx tbl pad ((str len s) - idx)

fn :: base64 encode String => String
      base64 encode s      =  cd b64 enc rem s 0 (cd b64 lut 0) True

fn :: base64url encode String => String
      base64url encode s      =  cd b64 enc rem s 0 (cd b64url lut 0) False

fn :: cd b64 val Int => Int
      cd b64 val c   =
        | c >= 65 and c <= 90  = c - 65
        | c >= 97 and c <= 122 = (c - 97) + 26
        | c >= 48 and c <= 57  = (c - 48) + 52
        | c == 43 or c == 45   = 62
        | c == 47 or c == 95   = 63
        | otherwise            = 0 - 1
```

### 07.4.3. Implementación interna: RFC 3986 URL Percent-Encoding & Query Strings

Fíxate en como `codec.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: cd is unreserved Int => Bool
      cd is unreserved c   =
        | c >= 65 and c <= 90                        = True
        | c >= 97 and c <= 122                       = True
        | c >= 48 and c <= 57                        = True
        | c == 45 or c == 95 or c == 46 or c == 126  = True
        | otherwise                                  = False

fn :: cd pct byte Int => String
      cd pct byte b   =
        ub  = ((b % 256) + 256) % 256
        hi  = ub / 16
        lo  = ub % 16
        tbl = cd hex up lut 0
        "%" + (str slice tbl hi (hi + 1)) + (str slice tbl lo (lo + 1))

fn :: cd url enc char String Int Int => String
      cd url enc char s idx c =
        | cd is unreserved c = str slice s idx (idx + 1)
        | otherwise          = cd pct byte c

fn :: cd url enc loop String Int Int => String
      cd url enc loop s idx len =
        | idx >= len = ""
        | otherwise  = (cd url enc char s idx (str char at s idx)) + (cd url enc loop s (idx + 1) len)

fn :: url encode String => String
      url encode s      =  cd url enc loop s 0 (str len s)

fn :: cd url dec pct String Int Int Int Int => String
      cd url dec pct s idx len hi lo =
        | hi >= 0 and lo >= 0 = (cd raw byte ((hi * 16) + lo)) + (cd url dec loop s (idx + 3) len)
        | otherwise           = "%" + (cd url dec loop s (idx + 1) len)

fn :: cd url dec at String Int Int Int => String
      cd url dec at s idx len c =
        | c == 43                     = " " + (cd url dec loop s (idx + 1) len)
        | c == 37 and (idx + 2) < len = cd url dec pct s idx len (cd hex val (str char at s (idx + 1))) (cd hex val (str char at s (idx + 2)))
        | otherwise                   = (str slice s idx (idx + 1)) + (cd url dec loop s (idx + 1) len)

fn :: cd url dec loop String Int Int => String
      cd url dec loop s idx len =
        | idx >= len = ""
        | otherwise  = cd url dec at s idx len (str char at s idx)

fn :: url decode String => String
      url decode s      =  cd url dec loop s 0 (str len s)

fn :: cd pair key (String String) => String
      cd pair key (k, _)          =  k
```

### 07.4.4. Implementación interna: RFC 8259 Lightweight JSON Formatting & Field Extraction

Fíxate en como `codec.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: cd json esc code String Int Int => String
      cd json esc code s idx c =
        | c == 34   = "\\\""
        | c == 92   = "\\\\"
        | c == 10   = "\\n"
        | c == 13   = "\\r"
        | c == 9    = "\\t"
        | otherwise = str slice s idx (idx + 1)

fn :: cd json esc loop String Int Int => String
      cd json esc loop s idx len =
        | idx >= len = ""
        | otherwise  = (cd json esc code s idx (str char at s idx)) + (cd json esc loop s (idx + 1) len)

fn :: json escape String => String
      json escape s      =  cd json esc loop s 0 (str len s)

fn :: cd json unesc next String Int Int Int => String
      cd json unesc next s idx len nc =
        | nc == 34  = "\"" + (cd json unesc loop s (idx + 2) len)
        | nc == 92  = "\\" + (cd json unesc loop s (idx + 2) len)
        | nc == 110 = "\n" + (cd json unesc loop s (idx + 2) len)
        | nc == 114 = "\r" + (cd json unesc loop s (idx + 2) len)
        | nc == 116 = "\t" + (cd json unesc loop s (idx + 2) len)
        | otherwise = (str slice s (idx + 1) (idx + 2)) + (cd json unesc loop s (idx + 2) len)

fn :: cd json unesc loop String Int Int => String
      cd json unesc loop s idx len =
        | idx >= len                                    = ""
        | (str char at s idx) == 92 and (idx + 1) < len = cd json unesc next s idx len (str char at s (idx + 1))
        | otherwise                                     = (str slice s idx (idx + 1)) + (cd json unesc loop s (idx + 1) len)

fn :: json unescape String => String
      json unescape s      =  cd json unesc loop s 0 (str len s)

fn :: json quote String => String
      json quote s      =  "\"" + (json escape s) + "\""

fn :: json int Int => String
      json int n   =  int to str n

fn :: json bool Bool  => String
      json bool True  =  "true"
      json bool False =  "false"

fn :: json null => String
      json null =  "null"
```

---

## 07.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `codec`

- **Garantía algorítmica e de seguridade**: Rexeitamento determinista de entradas hexadecimais ou Base64 mal formadas (devolvendo `""` sen lecturas fóra de límites) e reversibilidade exacta $decode(encode(x)) == x$.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/codec.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test codec.rg`.

### As 5 Regras de Ouro ao programar con `codec`

1. **Declara `import codec` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `codec` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `codec` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `codec` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 08** pasaremos a explorar en profundidade a lib **`json`** (A lib `json` — Árbore AST Recursiva RFC 8259, Pretty-Printer e Consultas por Ruta).
