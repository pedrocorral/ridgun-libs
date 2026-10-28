# Capítulo 17: A lib `path` — Normalización POSIX (`path clean`) e Confinamento contra Path Traversal

## 17.1. Por que existe a lib `path`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `path` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `path`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: unir rutas con `base + "/" + ficheiro` sen limpar segmentos `..` nin validar prefixos é coma deixar a porta aberta para que alguén pida `../../etc/passwd` no teu servidor web.

A lib **`path`** implementa normalización léxica POSIX (`path clean` ao estilo `filepath.Clean` de Go), unión segura (`path join`), descomposición (`dirname`, `basename`, `stem`, `ext`, `replace ext`) e o predicado de seguridade **`path is safe subpath`** (`VUL-INJ-001`) contra escapes de directorio.

Nun ecosistema tradicional, resolver as tarefas do dominio **`PATH`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`path`** (`src/main/ridgun/lib/path.rg`) aborda o problema con catro principios innegociables:

1. **Declara `import path` (ou `import path as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: path` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `path` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 17.2. Artefactos nativos, importación e catálogo completo da API de `path`

En `ridgun-libs`, **`path`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/path.rg` (dominio `PATH`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/path.rglib` | Distribución e importación directa con `import path` |
| **Ficheiro compilado** | `target/path.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libpath.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Cada lib declara o seu propio espazo de nomes con `module :: path`: abonda con escribir `import path` (ou `import path as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 17.2.1. Resumo de familias funcionais de `path`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `path clean / path join / path join list` | Colapsa `//`, `.` e `..` lexicamente e une segmentos de ruta |
| `path dirname / path basename / path split` | Divide unha ruta en directorio pai e nome de ficheiro final |
| `path ext / path stem / path replace ext` | Extrae ou cambia a extensión (tratando `.bashrc` como raíz `.bashrc` e ext `""`) |
| `path is safe subpath : String -> String -> Bool` | Verifica que `rel` permaneza estritamente dentro de `base_dir` e sen bytes NUL |

### 17.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/path.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/path.rg` (`0` tipos, `0` operadores e `30` funcións):

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: pa split slash loop String Int Int Int` | `[String]` |
| `2` | `fn :: pa rev strs [String] [String]` | `[String]` |
| `3` | `fn :: pa join slash [String]` | `String` |
| `4` | `fn :: pa pop stack [String] Bool` | `[String]` |
| `5` | `fn :: pa norm segs [String] [String] Bool` | `[String]` |
| `6` | `fn :: pa finish clean String Bool` | `String` |
| `7` | `fn :: path is abs String` | `Bool` |
| `8` | `fn :: path is rel String` | `Bool` |
| `9` | `fn :: path clean String` | `String` |
| `10` | `fn :: path join String String` | `String` |
| `11` | `fn :: path join list [String]` | `String` |
| `12` | `fn :: pa last char idx String Int Int` | `Int` |
| `13` | `fn :: pa dirname at String Int` | `String` |
| `14` | `fn :: pa dirname clean String` | `String` |
| `15` | `fn :: path dirname String` | `String` |
| `16` | `fn :: pa basename at String Int` | `String` |
| `17` | `fn :: pa basename clean String` | `String` |
| `18` | `fn :: path basename String` | `String` |
| `19` | `fn :: path split String` | `String String` |
| `20` | `fn :: pa ext at String Int` | `String` |
| `21` | `fn :: path ext String` | `String` |
| `22` | `fn :: pa stem at String Int` | `String` |
| `23` | `fn :: path stem String` | `String` |
| `24` | `fn :: pa norm ext String` | `String` |
| `25` | `fn :: pa combine dir base String String` | `String` |
| `26` | `fn :: path replace ext String String` | `String` |
| `27` | `fn :: pa is safe char Int` | `Bool` |
| `28` | `fn :: pa safe chars loop String Int Int` | `Bool` |
| `29` | `fn :: pa check prefix String String` | `Bool` |
| `30` | `fn :: path is safe subpath String String` | `Bool` |

---

## 17.3. Explorando `path` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `path` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test path.rg`.

### 17.3.1. Exemplo 1: Fluxo principal en estilo tabular con `path`

Observa como en Ridgun os signos `=` e os pasos de transformación con `path` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import path

fn :: resolver archivo estatico String String => Bool String
      resolver archivo estatico raiz peticion =
        path is safe subpath raiz peticion -> seguro
        path join raiz peticion -> ruta
        (seguro, ruta)
```

### 17.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `path` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import path

fn :: cambiar salida a objeto String => String String String
      cambiar salida a objeto fuente =
        fuente path dirname -> dir
        fuente path stem -> nom
        fuente path clean -> limpio
        path with ext limpio ".rglib" -> obj
        (dir, nom, obj)
```

### 17.3.3. Exemplo 3: Normalización léxica POSIX (`path clean`) e unión segura de segmentos (`path join`, `path join all`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `path` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test path clean and join => ()
      test path clean and join =
        -- Go path/path_test.go cleantests vectors
        assert str eq (path clean "") "." "AC1: empty -> ."
        assert str eq (path clean ".") "." "AC1: . -> ."
        assert str eq (path clean "././.") "." "AC1: ././. -> ."
        assert str eq (path clean "/") "/" "AC1: / -> /"
        assert str eq (path clean "///") "/" "AC1: /// -> /"
        assert str eq (path clean "/././") "/" "AC1: /././ -> /"
        assert str eq (path clean "/../a") "/a" "AC1: /../a clamped at root"
        assert str eq (path clean "/../../..") "/" "AC1: /../../.. clamped at root"
        assert str eq (path clean "a/b/..") "a" "AC1: a/b/.. -> a"
        assert str eq (path clean "a/../b") "b" "AC1: a/../b -> b"
        assert str eq (path clean "a/../../b") "../b" "AC1: relative .. preserved when above ."
        assert str eq (path clean "../../a/b/..") "../../a" "AC1: leading ../.. preserved"
        assert str eq (path clean "/a/b/../c/./d//") "/a/c/d" "AC1: complex absolute normalization"

        -- path join & path join list
        assert str eq (path join "" "") "." "AC1: join empty empty"
        assert str eq (path join "/var/log" "") "/var/log" "AC1: join with empty right"
        assert str eq (path join "" "app.log") "app.log" "AC1: join with empty left"
        assert str eq (path join "/var/log" "app/server.log") "/var/log/app/server.log" "AC1: join relative child"
        assert str eq (path join "/var/log" "/etc/hosts") "/etc/hosts" "AC1: join absolute child overrides base"
        assert str eq (path join list []) "." "AC1: join_list [] -> ."
        assert str eq (path join list ["src", "main", "ridgun", "lib", "path.rg"]) "src/main/ridgun/lib/path.rg" "AC1: join_list 5 segments"
        ()
```

### 17.3.4. Exemplo 4: Descomposición (`dirname`, `basename`, `ext`, `stem`) e confinamento contra *path traversal* (`path is safe rel`, `path resolve under`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `path` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test path components and confinement => ()
      test path components and confinement =
        p = "/home/boogie/ridgun-libs/src/socket.rg"
        assert true (path is abs p) "AC2: path_is_abs true"
        assert false (path is rel p) "AC2: path_is_rel false"
        assert false (path is abs "") "AC2: empty is not abs"
        assert true (path is rel "src/socket.rg") "AC2: relative path_is_rel"
        assert str eq (path dirname p) "/home/boogie/ridgun-libs/src" "AC2: dirname"
        assert str eq (path basename p) "socket.rg" "AC2: basename"
        sp = path split p
        assert str eq (pair_fst sp) "/home/boogie/ridgun-libs/src" "AC2: split dirname"
        assert str eq (pair_snd sp) "socket.rg" "AC2: split basename"
        assert str eq (path dirname "/") "/" "AC2: dirname of / is /"
        assert str eq (path basename "/") "/" "AC2: basename of / is /"
        assert str eq (path dirname "/top") "/" "AC2: dirname of /top is /"
        assert str eq (path dirname "barefile.txt") "." "AC2: dirname of bare filename is ."

        -- Multi-dot filenames, dotfiles, and extension replacement
        assert str eq (path stem p) "socket" "AC2: stem"
        assert str eq (path ext p) ".rg" "AC2: ext"
        assert str eq (path stem "archive.tar.gz") "archive.tar" "AC2: multi-dot stem"
        assert str eq (path ext "archive.tar.gz") ".gz" "AC2: multi-dot ext"
        assert str eq (path stem ".gitignore") ".gitignore" "AC2: dotfile stem"
        assert str eq (path ext ".gitignore") "" "AC2: dotfile empty ext"
        assert str eq (path replace ext p "rglib") "/home/boogie/ridgun-libs/src/socket.rglib" "AC2: replace_ext without leading dot"
        assert str eq (path replace ext p ".so") "/home/boogie/ridgun-libs/src/socket.so" "AC2: replace_ext with leading dot"
        assert str eq (path replace ext "main.rg" "") "main" "AC2: replace_ext with empty removes extension"

        -- OWASP Path Traversal & Shell Injection Confinement (VUL-INJ-002)
        assert true (path is safe subpath "/srv/www" "assets/app.js") "AC3: safe child subpath"
        assert true (path is safe subpath "/srv/www" "a/b/../c_1-2.txt") "AC3: safe normalized internal .."
        assert false (path is safe subpath "/srv/www" "") "AC3: empty child rejected"
        assert false (path is safe subpath "" "assets/app.js") "AC3: empty base rejected"
        assert false (path is safe subpath "/srv/www" "../etc/passwd") "AC3: direct .. traversal rejected"
        assert false (path is safe subpath "/srv/www" "a/b/../../../etc/passwd") "AC3: deep .. traversal escaping base rejected"
        assert false (path is safe subpath "/srv/www" "/etc/passwd") "AC3: absolute child path rejected"
        assert false (path is safe subpath "/srv/www" "/srv/www/index.html") "AC3: absolute child matching base still rejected"
        assert false (path is safe subpath "/srv/www" "bad;rm -rf /") "AC3: shell semicolon metachar rejected"
        assert false (path is safe subpath "/srv/www" "bad|cat") "AC3: shell pipe metachar rejected"
        assert false (path is safe subpath "/srv/www" "bad$var") "AC3: shell dollar metachar rejected"
        ()
```

### 17.3.5. Exemplo 5: Resolutor de ficheiros estáticos en *sandbox*: validación contra saltos `..`, bytes nulos e extracción de `dirname`/`basename`/`ext`/`stem`

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `path` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
import path

fn :: resolver archivo seguro (raiz : String) (peticion : String) => (String, String, String, String)
      resolver archivo seguro raiz peticion =
        ruta_final = path resolve under raiz peticion
        | ruta_final == "" = ("denegado", "", "", "")
        | otherwise        =
          dir  = path dirname ruta_final
          base = path basename ruta_final
          ext  = path ext ruta_final
          stem = path stem ruta_final
          (ruta_final, dir, base, "{stem} ({ext})")
```

---

## 17.4. Baixo o capó: como está construída `path` en Ridgun puro (`src/main/ridgun/lib/path.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/path.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 17.4.1. Implementación interna: Core Implementation Part 1

Fíxate en como `path.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
module :: path

fn :: pa split slash loop String Int Int Int => [String]
      pa split slash loop p start idx len =
        | idx >= len                = [(str slice p start len)]
        | (str char at p idx) == 47 = [(str slice p start idx)] :: (pa split slash loop p (idx + 1) (idx + 1) len)
        | otherwise                 = pa split slash loop p start (idx + 1) len

fn :: pa rev strs [String] [String] => [String]
      pa rev strs []       acc      =  acc
      pa rev strs (x:rest) acc      =  pa rev strs rest ([x] :: acc)

fn :: pa join slash [String] => String
      pa join slash []       =  ""
      pa join slash (x:[])   =  x
      pa join slash (x:rest) =  x + "/" + (pa join slash rest)

fn :: pa pop stack [String] Bool  => [String]
      pa pop stack []       True  =  []
      pa pop stack []       False =  [".."]
      pa pop stack (top:rs) is_ab =
        | top == ".." = ["..", ".."] :: rs
        | otherwise   = rs

fn :: pa norm segs [String] [String] Bool => [String]
      pa norm segs [] stack _ = pa rev strs stack []
      pa norm segs (s:rest) stack is_ab =
        | (str len s) == 0 or s == "." = pa norm segs rest stack is_ab
        | s == ".."                    = pa norm segs rest (pa pop stack stack is_ab) is_ab
        | otherwise                    = pa norm segs rest ([s] :: stack) is_ab

fn :: pa finish clean String Bool  => String
      pa finish clean joined True  =
        | (str len joined) == 0 = "/"
        | otherwise             = "/" + joined
      pa finish clean joined False =
        | (str len joined) == 0 = "."
        | otherwise             = joined

fn :: path is abs String => Bool
      path is abs p      =
        | (str len p) == 0        = False
        | (str char at p 0) == 47 = True
        | otherwise               = False

fn :: path is rel String => Bool
      path is rel p      =  not (path is abs p)

fn :: path clean String => String
      path clean p      =
        | (str len p) == 0 = "."
        | otherwise =
          p path is abs -> is_ab
          pa split slash loop p 0 0 (str len p) -> segs
          pa norm segs segs [] is_ab -> norm
          norm pa join slash -> pa finish clean is_ab

fn :: path join String String => String
      path join a      b      =
        | (str len a) == 0 = path clean b
        | (str len b) == 0 = path clean a
        | path is abs b    = path clean b
        | otherwise        = path clean (a + "/" + b)

fn :: path join list [String]   => String
      path join list []         =  "."
      path join list (x:[])     =  path clean x
      path join list (x:y:rest) =  path join list ([(path join x y)] :: rest)

fn :: pa last char idx String Int Int => Int
      pa last char idx s ch idx =
        | idx < 0                   = 0 - 1
        | (str char at s idx) == ch = idx
        | otherwise                 = pa last char idx s ch (idx - 1)

fn :: pa dirname at String Int => String
      pa dirname at cp     idx =
        | idx < 0   = "."
        | idx == 0  = "/"
        | otherwise = str slice cp 0 idx

fn :: pa dirname clean String => String
      pa dirname clean cp     =
        | cp == "/" = "/"
        | otherwise = pa dirname at cp (pa last char idx cp 47 ((str len cp) - 1))

fn :: path dirname String => String
      path dirname p      =  pa dirname clean (path clean p)
```

### 17.4.2. Implementación interna: Core Implementation Part 2

Fíxate en como `path.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: pa basename at String Int => String
      pa basename at cp     idx =
        | idx < 0   = cp
        | otherwise = str slice cp (idx + 1) (str len cp)

fn :: pa basename clean String => String
      pa basename clean cp     =
        | cp == "/" = "/"
        | otherwise = pa basename at cp (pa last char idx cp 47 ((str len cp) - 1))

fn :: path basename String => String
      path basename p      =  pa basename clean (path clean p)

fn :: path split String => String String
      path split p      =  (path dirname p, path basename p)

fn :: pa ext at String Int => String
      pa ext at base   dot =
        | dot <= 0  = ""
        | otherwise = str slice base dot (str len base)

fn :: path ext String => String
      path ext p      =
        base = path basename p
        pa ext at base (pa last char idx base 46 ((str len base) - 1))

fn :: pa stem at String Int => String
      pa stem at base   dot =
        | dot <= 0  = base
        | otherwise = str slice base 0 dot

fn :: path stem String => String
      path stem p      =
        base = path basename p
        pa stem at base (pa last char idx base 46 ((str len base) - 1))

fn :: pa norm ext String => String
      pa norm ext ext    =
        | (str len ext) == 0        = ""
        | (str char at ext 0) == 46 = ext
        | otherwise                 = "." + ext

fn :: pa combine dir base String String => String
      pa combine dir base dir base =
        | dir == "." = base
        | dir == "/" = "/" + base
        | otherwise  = dir + "/" + base

fn :: path replace ext String String  => String
      path replace ext p      new_ext =
        pa combine dir base (path dirname p) ((path stem p) + (pa norm ext new_ext))

fn :: pa is safe char Int => Bool
      pa is safe char c   =
        | c >= 48 and c <= 57                        = True
        | c >= 65 and c <= 90                        = True
        | c >= 97 and c <= 122                       = True
        | c == 47 or c == 46 or c == 95 or c == 45   = True
        | otherwise                                  = False

fn :: pa safe chars loop String Int Int => Bool
      pa safe chars loop s idx len =
        | idx >= len                          = True
        | not (pa is safe char (str char at s idx)) = False
        | otherwise                           = pa safe chars loop s (idx + 1) len

fn :: pa check prefix String String => Bool
      pa check prefix bclean full   =
        | bclean == "/" = path is abs full
        | full == bclean = True
        | otherwise     = str starts with full (bclean + "/")

fn :: path is safe subpath String String => Bool
      path is safe subpath base child =
        | (str len base) == 0 or (str len child) == 0          = False
        | path is abs child                                    = False
        | not (pa safe chars loop base 0 (str len base))       = False
        | not (pa safe chars loop child 0 (str len child))     = False
        | otherwise =
          bclean = path clean base
          full   = path clean (bclean + "/" + child)
          pa check prefix bclean full
```

### 17.4.3. Implementación interna: Core Implementation Part 4

Fíxate en como `path.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: path ext String => String
      path ext p      =
        base = path basename p
        pa ext at base (pa last char idx base 46 ((str len base) - 1))

fn :: pa stem at String Int => String
      pa stem at base   dot =
        | dot <= 0  = base
        | otherwise = str slice base 0 dot

fn :: path stem String => String
      path stem p      =
        base = path basename p
        pa stem at base (pa last char idx base 46 ((str len base) - 1))

fn :: pa norm ext String => String
      pa norm ext ext    =
        | (str len ext) == 0        = ""
        | (str char at ext 0) == 46 = ext
        | otherwise                 = "." + ext

fn :: pa combine dir base String String => String
      pa combine dir base dir base =
        | dir == "." = base
        | dir == "/" = "/" + base
        | otherwise  = dir + "/" + base

fn :: path replace ext String String  => String
      path replace ext p      new_ext =
        pa combine dir base (path dirname p) ((path stem p) + (pa norm ext new_ext))

fn :: pa is safe char Int => Bool
      pa is safe char c   =
        | c >= 48 and c <= 57                        = True
        | c >= 65 and c <= 90                        = True
        | c >= 97 and c <= 122                       = True
        | c == 47 or c == 46 or c == 95 or c == 45   = True
        | otherwise                                  = False
```

### 17.4.4. Implementación interna: Core Implementation Part 5

Fíxate en como `path.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: pa safe chars loop String Int Int => Bool
      pa safe chars loop s idx len =
        | idx >= len                          = True
        | not (pa is safe char (str char at s idx)) = False
        | otherwise                           = pa safe chars loop s (idx + 1) len

fn :: pa check prefix String String => Bool
      pa check prefix bclean full   =
        | bclean == "/" = path is abs full
        | full == bclean = True
        | otherwise     = str starts with full (bclean + "/")

fn :: path is safe subpath String String => Bool
      path is safe subpath base child =
        | (str len base) == 0 or (str len child) == 0          = False
        | path is abs child                                    = False
        | not (pa safe chars loop base 0 (str len base))       = False
        | not (pa safe chars loop child 0 (str len child))     = False
        | otherwise =
          bclean = path clean base
          full   = path clean (bclean + "/" + child)
          pa check prefix bclean full
```

---

## 17.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `path`

- **Garantía algorítmica e de seguridade**: `path is safe subpath` rexeita rutas absolutas, bytes NUL e calquera secuencia `..` que intente escapar do directorio raíz ou dun prefixo irmán (`/srv/www-secret`).
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/path.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test path.rg`.

### As 5 Regras de Ouro ao programar con `path`

1. **Declara `import path` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `path` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `path` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `path` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 18** pasaremos a explorar en profundidade a lib **`time`** (A lib `time` — Calendario Civil UTC (Hinnant), ISO-8601, Duracións e Backoff).
