# Capítulo 01: A lib `str` — Manipulación de Texto, Busca e Formato Tabular

## 01.1. Por que existe a lib `str`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `str` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `str`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: en C manipular cadeas con `strtok` e `strncpy` é camiñar por un campo de minas de desbordamentos de búfer e punteiros `NULL`, e noutras linguaxes acabas importando tres paquetes só para aliñar columnas ou repetir un separador en $O(\log N)$.

A lib **`str`** proporciona todas as primitivas puras e inmutables para buscar, recortar, dividir, unir, cambiar maiúsculas/minúsculas, repetir por duplicación binaria $O(\log N)$ e encher cadeas.

Nun ecosistema tradicional, resolver as tarefas do dominio **`STR`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`str`** (`src/main/ridgun/lib/str.rg`) aborda o problema con catro principios innegociables:

1. **Declara `import str` (ou `import str as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: str` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `str` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 01.2. Artefactos nativos, importación e catálogo completo da API de `str`

En `ridgun-libs`, **`str`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/str.rg` (dominio `STR`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/str.rglib` | Distribución e importación directa con `import str` |
| **Ficheiro compilado** | `target/str.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libstr.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Cada lib declara o seu propio espazo de nomes con `module :: str`: abonda con escribir `import str` (ou `import str as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 01.2.1. Resumo de familias funcionais de `str`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `str index of : String -> String -> Int` | Primeiro índice da subcadea (`-1` se non existe / `0` se é baleira) |
| `str contains / str starts with / str ends with` | Predicados `Bool` de subcadea, prefixo e sufixo |
| `str trim / str trim left / str trim right` | Elimina espazos en branco ASCII (` `, `\t`, `\n`, `\r`) |
| `str split / str lines / str words / str join` | Divide en `[String]` e une listas cun separador |
| `str replace / str to upper / str to lower` | Substitución sen solapamento e conversión ASCII de maiúsculas/minúsculas |
| `str repeat / str pad left / str pad right` | Repetición en $O(\log N)$ e recheo de columnas a ancho fixo |

### 01.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/str.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/str.rg` (`0` tipos, `0` operadores e `42` funcións):

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: is ascii space Int` | `Bool` |
| `2` | `fn :: is ascii lower Int` | `Bool` |
| `3` | `fn :: is ascii upper Int` | `Bool` |
| `4` | `fn :: to upper code Int` | `Int` |
| `5` | `fn :: to lower code Int` | `Int` |
| `6` | `fn :: str index of from String String Int Int Int` | `Int` |
| `7` | `fn :: str index of String String` | `Int` |
| `8` | `fn :: str ends with step String String Int Int` | `Bool` |
| `9` | `fn :: str ends with String String` | `Bool` |
| `10` | `fn :: str is empty String` | `Bool` |
| `11` | `fn :: first non space idx String Int Int` | `Int` |
| `12` | `fn :: last non space end String Int` | `Int` |
| `13` | `fn :: str trim left String` | `String` |
| `14` | `fn :: str trim right String` | `String` |
| `15` | `fn :: str trim slice String Int Int` | `String` |
| `16` | `fn :: str trim String` | `String` |
| `17` | `fn :: str is blank String` | `Bool` |
| `18` | `fn :: str replace step String String String Int` | `String` |
| `19` | `fn :: str replace String String String` | `String` |
| `20` | `fn :: str split chars String Int Int [String]` | `[String]` |
| `21` | `fn :: str split onech loop String Int Int Int Int [String]` | `[String]` |
| `22` | `fn :: str split loop String String Int Int Int Int Int [String]` | `[String]` |
| `23` | `fn :: str split step String String Int Int` | `[String]` |
| `24` | `fn :: str split String String` | `[String]` |
| `25` | `fn :: str join pair step [String] String [String]` | `[String]` |
| `26` | `fn :: str join pairs [String] String` | `String` |
| `27` | `fn :: str join [String] String` | `String` |
| `28` | `fn :: upper char code String Int Int` | `String` |
| `29` | `fn :: upper char slice String Int` | `String` |
| `30` | `fn :: str to upper range String Int Int` | `String` |
| `31` | `fn :: str to upper String` | `String` |
| `32` | `fn :: lower char code String Int Int` | `String` |
| `33` | `fn :: lower char slice String Int` | `String` |
| `34` | `fn :: str to lower range String Int Int` | `String` |
| `35` | `fn :: str to lower String` | `String` |
| `36` | `fn :: str repeat loop String Int String` | `String` |
| `37` | `fn :: str repeat String Int` | `String` |
| `38` | `fn :: pad fill unit String` | `String` |
| `39` | `fn :: str pad left step String Int String Int` | `String` |
| `40` | `fn :: str pad left String Int String` | `String` |
| `41` | `fn :: str pad right step String Int String Int` | `String` |
| `42` | `fn :: str pad right String Int String` | `String` |

---

## 01.3. Explorando `str` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `str` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test str.rg`.

### 01.3.1. Exemplo 1: Fluxo principal en estilo tabular con `str`

Observa como en Ridgun os signos `=` e os pasos de transformación con `str` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import str

fn :: normalizar cabecera String => String
      normalizar cabecera raw =
        raw str trim -> str to lower -> limpia
        limpia str split " " -> partes
        str join partes "-" -> slug
        str pad right slug 24 "."
```

### 01.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `str` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import str

fn :: extraer dominio String => String
      extraer dominio correo =
        str index of correo "@" -> pos
        | pos < 0   = "sin-dominio"
        | otherwise =
          correo str to lower -> minusc
          str replace minusc "@" " en "
```

### 01.3.3. Exemplo 3: Busca de subcadeas (`str index of`), sufixos (`str ends with`) e predicados de baleiro/branco

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `str` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test str search and predicates => ()
      test str search and predicates =
        assert equals (str index of "hello world" "world") 6 "AC1: index_of world"
        assert equals (str index of "hello world" "hello") 0 "AC1: index_of hello at 0"
        assert equals (str index of "ababa" "aba") 0 "AC1: index_of returns first occurrence"
        assert equals (str index of "hello" "xyz") (0 - 1) "AC1: index_of missing"
        assert equals (str index of "short" "much_longer_needle") (0 - 1) "AC1: needle longer than haystack -> -1"
        assert equals (str index of "" "a") (0 - 1) "AC1: non-empty needle in empty haystack -> -1"
        assert equals (str index of "" "") 0 "AC1: empty needle in empty haystack -> 0"
        assert equals (str index of "abc" "") 0 "AC1: empty needle -> 0"

        assert true (str ends with "archive.rglib" ".rglib") "AC1: ends_with true"
        assert true (str ends with "exact" "exact") "AC1: ends_with full string"
        assert true (str ends with "any" "") "AC1: ends_with empty suffix true"
        assert false (str ends with "archive.rg" ".rglib") "AC1: ends_with false"
        assert false (str ends with "short" "longer_suffix") "AC1: ends_with suffix longer than string"

        assert true (str is empty "") "AC1: is_empty true"
        assert false (str is empty " ") "AC1: space is not empty"
        assert true (str is blank "") "AC1: empty is blank"
        assert true (str is blank "   \t\n\r ") "AC1: whitespace-only is blank"
        assert false (str is blank "  x ") "AC1: non-whitespace is not blank"
        ()
```

### 01.3.4. Exemplo 4: Recorte de espazos (`trim`, `trim left`, `trim right`), substitución (`str replace`), división (`str split`) e unión (`str join`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `str` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test str trim replace and split => ()
      test str trim replace and split =
        assert equals (str trim "  \thi\n\r ") "hi" "AC2: str_trim mixed ASCII whitespace"
        assert equals (str trim "   \t\r\n") "" "AC2: str_trim all whitespace -> empty"
        assert equals (str trim "") "" "AC2: str_trim empty -> empty"
        assert equals (str trim "no_ws") "no_ws" "AC2: str_trim no whitespace"
        assert equals (str trim left "  abc  ") "abc  " "AC2: str_trim_left"
        assert equals (str trim right "  abc  ") "  abc" "AC2: str_trim_right"

        assert equals (str replace "a-b-c" "-" "_") "a_b_c" "AC2: str_replace single char"
        assert equals (str replace "aaaa" "aa" "b") "bb" "AC2: str_replace non-overlapping left-to-right"
        assert equals (str replace "Hello,World" "World" "") "Hello," "AC2: str_replace deletion to empty"
        assert equals (str replace "abc" "" "x") "abc" "AC2: str_replace empty old leaves string unchanged"
        assert equals (str replace "abc" "z" "y") "abc" "AC2: str_replace absent needle"

        assert equals (str split "a,b,c" ",") ["a", "b", "c"] "AC2: str_split comma"
        assert equals (str split "a,,b," ",") ["a", "", "b", ""] "AC2: str_split consecutive and trailing delim"
        assert equals (str split ",a" ",") ["", "a"] "AC2: str_split leading delim"
        assert equals (str split "a::b::c" "::") ["a", "b", "c"] "AC2: str_split multi-char delimiter"
        assert equals (str split "ab" "") ["a", "b"] "AC2: str_split empty delim splits chars"
        assert equals (str split "" "") [] "AC2: str_split empty string with empty delim -> []"

        assert equals (str join [] "::") "" "AC2: str_join empty list"
        assert equals (str join ["only"] "::") "only" "AC2: str_join singleton"
        assert equals (str join ["alpha", "beta", "gamma"] "::") "alpha::beta::gamma" "AC2: str_join 3 items"
        ()
```

### 01.3.5. Exemplo 5: Conversión de caixa ASCII (`to upper`, `to lower`), repetición binaria $O(\log N)$ (`str repeat`) e aliñación tabular (`pad left`, `pad right`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `str` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test str case repeat and padding => ()
      test str case repeat and padding =
        assert equals (str to upper "Abc! 123 xyz") "ABC! 123 XYZ" "AC3: str_to_upper"
        assert equals (str to lower "Abc! 123 XYZ") "abc! 123 xyz" "AC3: str_to_lower"
        assert equals (str to upper "") "" "AC3: str_to_upper empty"

        assert equals (str repeat "ab" 3) "ababab" "AC3: str_repeat 3"
        assert equals (str repeat "ab" 1) "ab" "AC3: str_repeat 1"
        assert equals (str repeat "ab" 0) "" "AC3: str_repeat 0"
        assert equals (str repeat "ab" (0 - 5)) "" "AC3: str_repeat negative -> empty"
        assert equals (str repeat "" 100) "" "AC3: str_repeat empty string -> empty"

        t0 = sys monotonic ms
        r64k = str repeat "x" 65536
        r256k = str repeat "x" 262144
        t1 = sys monotonic ms
        r8m = str repeat "x" 8000000
        assert equals (str len r64k) 65536 "AC3: str_repeat 65536 length"
        assert equals (str len r256k) 262144 "AC3: str_repeat 262144 length"
        assert equals (str len r8m) 8000000 "AC3: RG-052 str_repeat 8000000 exact length without 1 MiB cap"
        assert true ((t1 - t0) < 200) "AC3: LIB-9 str_repeat 64k+256k in < 200 ms"

        assert equals (str pad left "7" 3 "0") "007" "AC3: str_pad_left"
        assert equals (str pad right "7" 3 "0") "700" "AC3: str_pad_right"
        assert equals (str pad left "7" 4 "") "   7" "AC3: str_pad_left empty pad_ch defaults to space"
        assert equals (str pad left "7" 4 "xyz") "xxx7" "AC3: str_pad_left uses first char of pad_ch"
        assert equals (str pad left "1234" 3 "0") "1234" "AC3: str_pad_left already wider than width"
        assert equals (str pad right "1234" 3 "0") "1234" "AC3: str_pad_right already wider than width"
        ()
```

---

## 01.4. Baixo o capó: como está construída `str` en Ridgun puro (`src/main/ridgun/lib/str.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/str.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 01.4.1. Implementación interna: ASCII Classification Helpers

Fíxate en como `str.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
module :: str

fn :: is ascii space Int  => Bool
      is ascii space code =
        code == 32 or code == 9 or code == 10 or code == 13

fn :: is ascii lower Int  => Bool
      is ascii lower code =  code >= 97 and code <= 122

fn :: is ascii upper Int  => Bool
      is ascii upper code =  code >= 65 and code <= 90

fn :: to upper code Int  => Int
      to upper code code =
        | is ascii lower code = code - 32
        | otherwise           = code

fn :: to lower code Int  => Int
      to lower code code =
        | is ascii upper code = code + 32
        | otherwise           = code
```

### 01.4.2. Implementación interna: Whitespace Trimming

Fíxate en como `str.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: first non space idx String Int Int => Int
      first non space idx s idx len =
        | idx >= len                         = len
        | is ascii space (str char at s idx) = first non space idx s (idx + 1) len
        | otherwise                          = idx

fn :: last non space end String Int => Int
      last non space end s end =
        | end <= 0                                 = 0
        | is ascii space (str char at s (end - 1)) = last non space end s (end - 1)
        | otherwise                                = end

fn :: str trim left String => String
      str trim left s      =
        s str len -> len
        first non space idx s 0 len -> start
        str slice s start len

fn :: str trim right String => String
      str trim right s      =
        s str len -> len
        last non space end s len -> end
        str slice s 0 end

fn :: str trim slice String Int Int => String
      str trim slice s start end =
        | start >= end = ""
        | otherwise    = str slice s start end

fn :: str trim String => String
      str trim s      =
        s str len -> len
        first non space idx s 0 len -> start
        last non space end s len -> end
        str trim slice s start end

fn :: str is blank String => Bool
      str is blank s      =  s str trim -> str is empty
```

### 01.4.3. Implementación interna: String Splitting & Joining

Fíxate en como `str.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: str split chars String Int Int [String] => [String]
      str split chars s idx slen acc =
        | idx >= slen = acc
        | otherwise   = str split chars s (idx + 1) slen (acc :: [str slice s idx (idx + 1)])

fn :: str split onech loop String Int Int Int Int [String] => [String]
      str split onech loop s d0 pos slen seg_start acc =
        | pos >= slen = acc :: [str slice s seg_start slen]
        | (str char at s pos) == d0 =
          seg = str slice s seg_start pos
          str split onech loop s d0 (pos + 1) slen (pos + 1) (acc :: [seg])
        | otherwise =
          str split onech loop s d0 (pos + 1) slen seg_start acc

fn :: str split loop String String Int Int Int Int Int [String] => [String]
      str split loop s delim d0 pos slen dlen seg_start acc =
        | pos + dlen > slen = acc :: [str slice s seg_start slen]
        | (str char at s pos) == d0 and (str slice s pos (pos + dlen)) == delim =
          seg = str slice s seg_start pos
          str split loop s delim d0 (pos + dlen) slen dlen (pos + dlen) (acc :: [seg])
        | otherwise =
          str split loop s delim d0 (pos + 1) slen dlen seg_start acc

fn :: str split step String String Int Int => [String]
      str split step s delim slen dlen =
        | dlen == 0 = str split chars s 0 slen []
        | dlen == 1 = str split onech loop s (str char at delim 0) 0 slen 0 []
        | otherwise = str split loop s delim (str char at delim 0) 0 slen dlen 0 []

fn :: str split String String => [String]
      str split s      delim  =
        str split step s delim (str len s) (str len delim)

fn :: str join pair step [String] String [String] => [String]
      str join pair step []         _   acc =  acc
      str join pair step (a:[])     _   acc =  acc :: [a]
      str join pair step (a:b:rest) sep acc =
        str join pair step rest sep (acc :: [a + sep + b])

fn :: str join pairs [String] String => String
      str join pairs []       _   =  ""
      str join pairs (x:[])   _   =  x
      str join pairs (x:y:[]) sep =  x + sep + y
      str join pairs xs       sep =
        str join pairs (str join pair step xs sep []) sep

fn :: str join [String] String => String
      str join xs       sep    =  str join pairs xs sep
```

### 01.4.4. Implementación interna: Repetition & Padding

Fíxate en como `str.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: str repeat loop String Int String => String
      str repeat loop cur n acc =
        | n <= 0       = acc
        | (n % 2) == 1 = str repeat loop (cur + cur) (n / 2) (acc + cur)
        | otherwise    = str repeat loop (cur + cur) (n / 2) acc

fn :: str repeat String Int => String
      str repeat s      n   =
        | n <= 0 or (str len s) == 0 = ""
        | otherwise                  = str repeat loop s n ""

fn :: pad fill unit String => String
      pad fill unit pad_ch =
        | (str len pad_ch) == 0 = " "
        | otherwise             = str slice pad_ch 0 1

fn :: str pad left step String Int String Int => String
      str pad left step s width pad_ch slen =
        | slen >= width = s
        | otherwise     = (str repeat (pad fill unit pad_ch) (width - slen)) + s

fn :: str pad left String Int String => String
      str pad left s width pad_ch =
        str pad left step s width pad_ch (str len s)

fn :: str pad right step String Int String Int => String
      str pad right step s width pad_ch slen =
        | slen >= width = s
        | otherwise     = s + (str repeat (pad fill unit pad_ch) (width - slen))

fn :: str pad right String Int String => String
      str pad right s width pad_ch =
        str pad right step s width pad_ch (str len s)
```

---

## 01.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `str`

- **Garantía algorítmica e de seguridade**: Repetición en $O(\log N)$ mediante duplicación de cadeas, predicados seguros ante agullas baleiras e cero mutación no lugar.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/str.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test str.rg`.

### As 5 Regras de Ouro ao programar con `str`

1. **Declara `import str` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `str` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `str` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `str` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 02** pasaremos a explorar en profundidade a lib **`math`** (A lib `math` — Aritmética Segura, Teoría de Números e Estatística).
